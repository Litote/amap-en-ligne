@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ProducerPayload
import persistence.dao.ProducerSyncDAO
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ProducerSyncDAO::class])
internal class ProducerSyncPostgresDAO(
    private val client: PostgresClient,
) : ProducerSyncDAO {
    override suspend fun put(
        producer: Producer,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer (
                        producer_id, producer_account_id, role, association_instant,
                        status, producer_preferences, user_preferences, user_settings
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (producer_id)
                    DO UPDATE SET
                        producer_account_id = EXCLUDED.producer_account_id,
                        role = EXCLUDED.role,
                        association_instant = EXCLUDED.association_instant,
                        status = EXCLUDED.status,
                        producer_preferences = EXCLUDED.producer_preferences,
                        user_preferences = EXCLUDED.user_preferences,
                        user_settings = EXCLUDED.user_settings
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producer.producerId.id)
                    stmt.setString(2, producer.producerAccountId.id)
                    stmt.setString(3, producer.role.name)
                    stmt.setLong(4, producer.associationInstant.toEpochMilliseconds())
                    stmt.setString(5, producer.status.name)
                    stmt.setString(6, json.encodeToString(ProducerPreferences.serializer(), producer.producerPreferences))
                    stmt.setString(7, json.encodeToString(UserPreferences.serializer(), producer.userPreferences))
                    stmt.setString(8, json.encodeToString(UserSettings.serializer(), producer.userSettings))
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun findByProducerId(producerId: Id<Producer>): Producer? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT producer_id, producer_account_id, role, association_instant,
                           status, producer_preferences, user_preferences, user_settings
                    FROM producer
                    WHERE producer_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toProducer() else null
                    }
                }
        }

    override suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<Producer> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT producer_id, producer_account_id, role, association_instant,
                           status, producer_preferences, user_preferences, user_settings
                    FROM producer
                    WHERE producer_account_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccountId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toProducer())
                            }
                        }
                    }
                }
        }

    override suspend fun delete(
        producerId: Id<Producer>,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    DELETE FROM producer
                    WHERE producer_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerId.id)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }
}

private fun ResultSet.toProducer(): Producer =
    Producer(
        producerId = getString("producer_id").toId(),
        producerAccountId = getString("producer_account_id").toId(),
        role = ProducerRole.valueOf(getString("role")),
        associationInstant = Instant.fromEpochMilliseconds(getLong("association_instant")),
        status = ProducerStatus.valueOf(getString("status")),
        producerPreferences =
            json.decodeFromString(
                ProducerPreferences.serializer(),
                getString("producer_preferences"),
            ),
        userPreferences =
            json.decodeFromString(
                UserPreferences.serializer(),
                getString("user_preferences"),
            ),
        userSettings =
            json.decodeFromString(
                UserSettings.serializer(),
                getString("user_settings"),
            ),
    )

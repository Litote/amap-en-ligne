@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.DeviceTokenSyncDAO
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [DeviceTokenSyncDAO::class])
internal class DeviceTokenSyncPostgresDAO(
    private val client: PostgresClient,
) : DeviceTokenSyncDAO {
    override suspend fun getByRecipientScope(recipientScope: String): List<DeviceToken> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT device_token_id, recipient_scope, platform, token, created_at, last_seen_at
                    FROM device_token
                    WHERE recipient_scope = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toDeviceToken())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(
        recipientScope: String,
        deviceTokenId: Id<DeviceToken>,
    ): DeviceToken? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT device_token_id, recipient_scope, platform, token, created_at, last_seen_at
                    FROM device_token
                    WHERE recipient_scope = ? AND device_token_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.setString(2, deviceTokenId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toDeviceToken() else null
                    }
                }
        }

    override suspend fun put(
        deviceToken: DeviceToken,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO device_token (
                        device_token_id, recipient_scope, platform, token, created_at, last_seen_at
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT (device_token_id)
                    DO UPDATE SET
                        recipient_scope = EXCLUDED.recipient_scope,
                        platform = EXCLUDED.platform,
                        token = EXCLUDED.token,
                        created_at = EXCLUDED.created_at,
                        last_seen_at = EXCLUDED.last_seen_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, deviceToken.deviceTokenId.id)
                    stmt.setString(2, deviceToken.recipientScope)
                    stmt.setString(3, deviceToken.platform.name)
                    stmt.setString(4, deviceToken.token)
                    stmt.setLong(5, deviceToken.createdAt.toEpochMilliseconds())
                    stmt.setLong(6, deviceToken.lastSeenAt.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        recipientScope: String,
        deviceTokenId: Id<DeviceToken>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM device_token WHERE recipient_scope = ? AND device_token_id = ?",
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.setString(2, deviceTokenId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

@OptIn(ExperimentalTime::class)
private fun ResultSet.toDeviceToken(): DeviceToken =
    DeviceToken(
        deviceTokenId = getString("device_token_id").toId(),
        recipientScope = getString("recipient_scope"),
        platform = DevicePlatform.valueOf(getString("platform")),
        token = getString("token"),
        createdAt = Instant.fromEpochMilliseconds(getLong("created_at")),
        lastSeenAt = Instant.fromEpochMilliseconds(getLong("last_seen_at")),
    )

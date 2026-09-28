@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import org.koin.core.annotation.Single
import persistence.dao.AppliedClientOpDAO
import persistence.model.AppliedClientOp
import persistence.model.EntityType
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [AppliedClientOpDAO::class])
internal class AppliedClientOpPostgresDAO(
    private val client: PostgresClient,
) : AppliedClientOpDAO {
    override suspend fun record(entry: AppliedClientOp) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO applied_client_op(client_op_id, caller_sub, entity_type, server_entity_id, applied_at)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT (client_op_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, entry.clientOpId)
                    stmt.setString(2, entry.callerSub)
                    stmt.setString(3, entry.entityType.name)
                    stmt.setString(4, entry.serverEntityId)
                    stmt.setLong(5, entry.appliedAt.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun find(clientOpId: String): AppliedClientOp? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT client_op_id, caller_sub, entity_type, server_entity_id, applied_at
                    FROM applied_client_op
                    WHERE client_op_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, clientOpId)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toAppliedClientOp() else null
                    }
                }
        }
}

private fun ResultSet.toAppliedClientOp(): AppliedClientOp =
    AppliedClientOp(
        clientOpId = getString("client_op_id"),
        callerSub = getString("caller_sub"),
        entityType = EntityType.valueOf(getString("entity_type")),
        serverEntityId = getString("server_entity_id"),
        appliedAt = Instant.fromEpochMilliseconds(getLong("applied_at")),
    )

@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.AccountDeletionLogDAO
import persistence.model.AccountDeletionLog
import persistence.model.DeletedAccountRole
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [AccountDeletionLogDAO::class])
internal class AccountDeletionLogPostgresDAO(
    private val client: PostgresClient,
) : AccountDeletionLogDAO {
    override suspend fun append(entry: AccountDeletionLog) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO account_deletion_log(id, deleted_sub_hash, deleted_role, deleted_at, actor_owner_id)
                    VALUES (?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, entry.id.id)
                    stmt.setString(2, entry.deletedSubHash)
                    stmt.setString(3, entry.deletedRole.name)
                    stmt.setLong(4, entry.deletedAt.toEpochMilliseconds())
                    stmt.setString(5, entry.actorOwnerId.id)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun listAll(): List<AccountDeletionLog> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT id, deleted_sub_hash, deleted_role, deleted_at, actor_owner_id
                    FROM account_deletion_log
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) add(rs.toAccountDeletionLog())
                        }
                    }
                }
        }

    override suspend fun findById(id: Id<AccountDeletionLog>): AccountDeletionLog? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT id, deleted_sub_hash, deleted_role, deleted_at, actor_owner_id
                    FROM account_deletion_log
                    WHERE id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, id.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toAccountDeletionLog() else null
                    }
                }
        }
}

private fun ResultSet.toAccountDeletionLog(): AccountDeletionLog =
    AccountDeletionLog(
        id = getString("id").toId(),
        deletedSubHash = getString("deleted_sub_hash"),
        deletedRole = DeletedAccountRole.valueOf(getString("deleted_role")),
        deletedAt = Instant.fromEpochMilliseconds(getLong("deleted_at")),
        actorOwnerId = getString("actor_owner_id").toId(),
    )

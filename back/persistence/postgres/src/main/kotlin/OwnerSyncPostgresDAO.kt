@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.Member
import persistence.model.Owner
import persistence.model.UserPreferences
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [OwnerSyncDAO::class])
internal class OwnerSyncPostgresDAO(
    private val client: PostgresClient,
) : OwnerSyncDAO {
    override suspend fun listAll(): List<Owner> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT owner_id, first_name, last_name, email, phone,
                           account_status, registered_at, updated_at, user_preferences
                    FROM owner
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toOwner())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(ownerId: Id<Owner>): Owner? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT owner_id, first_name, last_name, email, phone,
                           account_status, registered_at, updated_at, user_preferences
                    FROM owner
                    WHERE owner_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, ownerId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toOwner() else null
                    }
                }
        }

    override suspend fun put(
        owner: Owner,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO owner (owner_id, first_name, last_name, email, phone,
                                      account_status, registered_at, updated_at, user_preferences)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb)
                    ON CONFLICT (owner_id) DO UPDATE SET
                        first_name = EXCLUDED.first_name,
                        last_name = EXCLUDED.last_name,
                        email = EXCLUDED.email,
                        phone = EXCLUDED.phone,
                        account_status = EXCLUDED.account_status,
                        registered_at = EXCLUDED.registered_at,
                        updated_at = EXCLUDED.updated_at,
                        user_preferences = EXCLUDED.user_preferences
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, owner.ownerId.id)
                    stmt.setString(2, owner.firstName)
                    stmt.setString(3, owner.lastName)
                    stmt.setString(4, owner.email)
                    stmt.setString(5, owner.phone)
                    stmt.setString(6, owner.accountStatus.name)
                    stmt.setLong(7, owner.registeredAt.toEpochMilliseconds())
                    stmt.setLong(8, owner.updatedAt.toEpochMilliseconds())
                    stmt.setString(9, json.encodeToString(UserPreferences.serializer(), owner.userPreferences))
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun updateStatus(
        ownerId: Id<Owner>,
        accountStatus: AccountStatus,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE owner SET account_status = ? WHERE owner_id = ?",
                ).use { stmt ->
                    stmt.setString(1, accountStatus.name)
                    stmt.setString(2, ownerId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun existsByEmail(email: String): Boolean =
        client.dataSource.query { conn ->
            conn
                .prepareStatement("SELECT 1 FROM owner WHERE email = ?")
                .use { stmt ->
                    stmt.setString(1, email)
                    stmt.executeQuery().use { rs -> rs.next() }
                }
        }

    override suspend fun existsBySub(sub: String): Boolean =
        // Since ownerId == sub by convention, we use owner_id for the WHERE clause.
        client.dataSource.query { conn ->
            conn
                .prepareStatement("SELECT 1 FROM owner WHERE owner_id = ?")
                .use { stmt ->
                    stmt.setString(1, sub)
                    stmt.executeQuery().use { rs -> rs.next() }
                }
        }

    override suspend fun findBySub(sub: String): Owner? =
        // Since ownerId == sub by convention, findBySub is equivalent to findById.
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT owner_id, first_name, last_name, email, phone,
                           account_status, registered_at, updated_at, user_preferences
                    FROM owner
                    WHERE owner_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, sub)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toOwner() else null
                    }
                }
        }

    override suspend fun delete(
        ownerId: Id<Owner>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement("DELETE FROM owner WHERE owner_id = ?")
                .use { stmt ->
                    stmt.setString(1, ownerId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun promoteToOwner(
        owner: Owner,
        ownerChange: Change,
        membersToRevoke: List<Member>,
        memberChanges: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            // Insert new owner row
            conn
                .prepareStatement(
                    """
                    INSERT INTO owner (owner_id, first_name, last_name, email, phone,
                                      account_status, registered_at, updated_at, user_preferences)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb)
                    ON CONFLICT (owner_id) DO UPDATE SET
                        first_name = EXCLUDED.first_name,
                        last_name = EXCLUDED.last_name,
                        email = EXCLUDED.email,
                        phone = EXCLUDED.phone,
                        account_status = EXCLUDED.account_status,
                        registered_at = EXCLUDED.registered_at,
                        updated_at = EXCLUDED.updated_at,
                        user_preferences = EXCLUDED.user_preferences
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, owner.ownerId.id)
                    stmt.setString(2, owner.firstName)
                    stmt.setString(3, owner.lastName)
                    stmt.setString(4, owner.email)
                    stmt.setString(5, owner.phone)
                    stmt.setString(6, owner.accountStatus.name)
                    stmt.setLong(7, owner.registeredAt.toEpochMilliseconds())
                    stmt.setLong(8, owner.updatedAt.toEpochMilliseconds())
                    stmt.setString(9, json.encodeToString(UserPreferences.serializer(), owner.userPreferences))
                    stmt.executeUpdate()
                }
            // Write owner Change record
            upsertChange(conn, ownerChange)
            // Delete each member row
            membersToRevoke.forEach { member ->
                conn
                    .prepareStatement(
                        "DELETE FROM member WHERE member_id = ? AND organization_id = ?",
                    ).use { stmt ->
                        stmt.setString(1, member.memberId.id)
                        stmt.setString(2, member.organizationId.id)
                        stmt.executeUpdate()
                    }
            }
            upsertChanges(conn, memberChanges)
        }
    }
}

private fun ResultSet.toOwner(): Owner =
    Owner(
        ownerId = getString("owner_id").toId(),
        firstName = getString("first_name"),
        lastName = getString("last_name"),
        email = getString("email"),
        phone = getString("phone"),
        accountStatus = AccountStatus.valueOf(getString("account_status")),
        registeredAt = Instant.fromEpochMilliseconds(getLong("registered_at")),
        updatedAt = Instant.fromEpochMilliseconds(getLong("updated_at")),
        userPreferences = json.decodeFromString(UserPreferences.serializer(), getString("user_preferences")),
    )

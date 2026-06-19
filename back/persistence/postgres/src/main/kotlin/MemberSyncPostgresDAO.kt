@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import authentication.Role
import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.MemberSyncDAO
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContract
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.UserPreferences
import persistence.model.UserSettings
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true, binds = [MemberSyncDAO::class])
internal class MemberSyncPostgresDAO(
    private val client: PostgresClient,
) : MemberSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Member> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT member_id, organization_id, roles, active_status,
                           first_name, last_name, email, phone, account_status,
                           contracts, registrations,
                           member_settings, member_preferences, user_preferences, user_settings
                    FROM member
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMember())
                            }
                        }
                    }
                }
        }

    override suspend fun listAll(): List<Member> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT member_id, organization_id, roles, active_status,
                           first_name, last_name, email, phone, account_status,
                           contracts, registrations,
                           member_settings, member_preferences, user_preferences, user_settings
                    FROM member
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMember())
                            }
                        }
                    }
                }
        }

    override suspend fun findOrganizationIdBySub(sub: String): Id<Organization>? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "SELECT organization_id FROM member WHERE member_id = ? LIMIT 1",
                ).use { stmt ->
                    stmt.setString(1, sub)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.getString("organization_id").toId() else null
                    }
                }
        }

    override suspend fun getMembersBySub(sub: String): List<Member> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT member_id, organization_id, roles, active_status,
                           first_name, last_name, email, phone, account_status,
                           contracts, registrations,
                           member_settings, member_preferences, user_preferences, user_settings
                    FROM member
                    WHERE member_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, sub)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMember())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        member: Member,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO member (
                        member_id, organization_id, roles, active_status,
                        first_name, last_name, email, phone, account_status,
                        contracts, registrations,
                        member_settings, member_preferences, user_preferences, user_settings
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?::jsonb, ?::jsonb, ?::jsonb, ?::jsonb, ?::jsonb)
                    ON CONFLICT (member_id)
                    DO UPDATE SET
                        organization_id = EXCLUDED.organization_id,
                        roles = EXCLUDED.roles,
                        active_status = EXCLUDED.active_status,
                        first_name = EXCLUDED.first_name,
                        last_name = EXCLUDED.last_name,
                        email = EXCLUDED.email,
                        phone = EXCLUDED.phone,
                        account_status = EXCLUDED.account_status,
                        contracts = EXCLUDED.contracts,
                        registrations = EXCLUDED.registrations,
                        member_settings = EXCLUDED.member_settings,
                        member_preferences = EXCLUDED.member_preferences,
                        user_preferences = EXCLUDED.user_preferences,
                        user_settings = EXCLUDED.user_settings
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, member.memberId.id)
                    stmt.setString(2, member.organizationId.id)
                    stmt.setArray(
                        3,
                        conn.createArrayOf("text", member.roles.map { it.name }.toTypedArray<String>()),
                    )
                    stmt.setBoolean(4, member.activeStatus)
                    stmt.setString(5, member.firstName)
                    stmt.setString(6, member.lastName)
                    stmt.setString(7, member.email)
                    stmt.setString(8, member.phone)
                    stmt.setString(9, member.accountStatus?.name)
                    stmt.setString(
                        10,
                        json.encodeToString(ListSerializer(MemberContract.serializer()), member.contracts),
                    )
                    stmt.setString(
                        11,
                        json.encodeToString(
                            ListSerializer(MemberRegistration.serializer()),
                            member.registrations,
                        ),
                    )
                    stmt.setString(12, json.encodeToString(MemberSettings.serializer(), member.memberSettings))
                    stmt.setString(
                        13,
                        json.encodeToString(MemberPreferences.serializer(), member.memberPreferences),
                    )
                    stmt.setString(
                        14,
                        json.encodeToString(UserPreferences.serializer(), member.userPreferences),
                    )
                    stmt.setString(15, json.encodeToString(UserSettings.serializer(), member.userSettings))
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun delete(
        memberId: Id<Member>,
        organizationId: Id<Organization>,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM member WHERE member_id = ? AND organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, memberId.id)
                    stmt.setString(2, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun setActiveStatusBySub(
        sub: String,
        activeStatus: Boolean,
        changes: List<Change>,
    ) {
        // Since memberId == sub by convention, we use member_id for the WHERE clause.
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE member SET active_status = ?, account_status = ? WHERE member_id = ?",
                ).use { stmt ->
                    stmt.setBoolean(1, activeStatus)
                    stmt.setString(2, if (activeStatus) MemberAccountStatus.ACTIVE.name else MemberAccountStatus.SUSPENDED.name)
                    stmt.setString(3, sub)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun anonymiseBySub(
        sub: String,
        changes: List<Change>,
    ) {
        // Since memberId == sub by convention, we use member_id for the WHERE clause.
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    UPDATE member
                    SET active_status = FALSE,
                        first_name = NULL,
                        last_name = NULL,
                        email = NULL,
                        phone = NULL,
                        account_status = ?
                    WHERE member_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, MemberAccountStatus.SUSPENDED.name)
                    stmt.setString(2, sub)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }
}

private fun ResultSet.toMember(): Member =
    Member(
        memberId = getString("member_id").toId(),
        organizationId = getString("organization_id").toId(),
        roles =
            (getArray("roles").array as Array<*>)
                .filterIsInstance<String>()
                .mapNotNull { Role.fromString(it) }
                .toSet(),
        activeStatus = getBoolean("active_status"),
        firstName = getString("first_name"),
        lastName = getString("last_name"),
        email = getString("email"),
        phone = getString("phone"),
        accountStatus =
            getString("account_status")?.let { value ->
                runCatching { MemberAccountStatus.valueOf(value) }.getOrNull()
            },
        contracts =
            json.decodeFromString(
                ListSerializer(MemberContract.serializer()),
                getString("contracts") ?: "[]",
            ),
        registrations =
            json.decodeFromString(
                ListSerializer(MemberRegistration.serializer()),
                getString("registrations") ?: "[]",
            ),
        memberSettings =
            json.decodeFromString(
                MemberSettings.serializer(),
                getString("member_settings"),
            ),
        memberPreferences =
            json.decodeFromString(
                MemberPreferences.serializer(),
                getString("member_preferences"),
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

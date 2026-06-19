@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import authentication.Role
import id.Id
import id.toId
import kotlinx.serialization.builtins.SetSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.DuplicatePendingInvitationException
import persistence.dao.MemberInvitationSyncDAO
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import serialization.json
import java.sql.SQLException
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [MemberInvitationSyncDAO::class])
internal class MemberInvitationSyncPostgresDAO(
    private val client: PostgresClient,
) : MemberInvitationSyncDAO {
    override suspend fun put(
        invitation: MemberInvitation,
        change: Change,
    ) {
        try {
            client.dataSource.tx { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO member_invitation(
                            invitation_id, organization_id, email, first_name, last_name, roles,
                            status, created_at, expires_at, resend_requested_at, activated_at,
                            custom_email_subject, custom_email_body
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT (invitation_id)
                        DO UPDATE SET
                            organization_id = EXCLUDED.organization_id,
                            email = EXCLUDED.email,
                            first_name = EXCLUDED.first_name,
                            last_name = EXCLUDED.last_name,
                            roles = EXCLUDED.roles,
                            status = EXCLUDED.status,
                            created_at = EXCLUDED.created_at,
                            expires_at = EXCLUDED.expires_at,
                            resend_requested_at = EXCLUDED.resend_requested_at,
                            activated_at = EXCLUDED.activated_at,
                            custom_email_subject = EXCLUDED.custom_email_subject,
                            custom_email_body = EXCLUDED.custom_email_body
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, invitation.invitationId)
                        stmt.setString(2, invitation.organizationId.id)
                        stmt.setString(3, invitation.email)
                        stmt.setString(4, invitation.firstName)
                        stmt.setString(5, invitation.lastName)
                        stmt.setString(6, json.encodeToString(SetSerializer(Role.serializer()), invitation.roles))
                        stmt.setString(7, invitation.status.name)
                        stmt.setLong(8, invitation.createdAt.toEpochMilliseconds())
                        stmt.setLong(9, invitation.expiresAt.toEpochMilliseconds())
                        stmt.setLongOrNull(10, invitation.resendRequestedAt)
                        stmt.setLongOrNull(11, invitation.activatedAt)
                        stmt.setString(12, invitation.customEmailSubject)
                        stmt.setString(13, invitation.customEmailBody)
                        stmt.executeUpdate()
                    }
                upsertChange(conn, change)
            }
        } catch (e: SQLException) {
            // SQLState 23505 = unique_violation — thrown by the partial unique index
            // member_invitation_unique_pending_email when a concurrent insert wins the race.
            if (e.sqlState == "23505") throw DuplicatePendingInvitationException()
            throw e
        }
    }

    override suspend fun findById(invitationId: String): MemberInvitation? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT invitation_id, organization_id, email, first_name, last_name, roles,
                           status, created_at, expires_at, resend_requested_at, activated_at,
                           custom_email_subject, custom_email_body
                    FROM member_invitation
                    WHERE invitation_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, invitationId)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toMemberInvitation() else null
                    }
                }
        }

    override suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberInvitation> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT invitation_id, organization_id, email, first_name, last_name, roles,
                           status, created_at, expires_at, resend_requested_at, activated_at,
                           custom_email_subject, custom_email_body
                    FROM member_invitation
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMemberInvitation())
                            }
                        }
                    }
                }
        }

    override suspend fun findPendingByEmail(email: String): MemberInvitation? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT invitation_id, organization_id, email, first_name, last_name, roles,
                           status, created_at, expires_at, resend_requested_at, activated_at,
                           custom_email_subject, custom_email_body
                    FROM member_invitation
                    WHERE email = ? AND status = 'PENDING_ACTIVATION'
                    LIMIT 1
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, email)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toMemberInvitation() else null
                    }
                }
        }
}

private fun java.sql.ResultSet.toMemberInvitation(): MemberInvitation =
    MemberInvitation(
        invitationId = getString("invitation_id"),
        organizationId = getString("organization_id").toId(),
        email = getString("email"),
        firstName = getString("first_name"),
        lastName = getString("last_name"),
        roles = json.decodeFromString(SetSerializer(Role.serializer()), getString("roles")),
        status = MemberInvitationStatus.valueOf(getString("status")),
        createdAt = Instant.fromEpochMilliseconds(getLong("created_at")),
        expiresAt = Instant.fromEpochMilliseconds(getLong("expires_at")),
        resendRequestedAt = getInstantOrNull("resend_requested_at"),
        activatedAt = getInstantOrNull("activated_at"),
        customEmailSubject = getString("custom_email_subject"),
        customEmailBody = getString("custom_email_body"),
    )

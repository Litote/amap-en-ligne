@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OwnerInvitationSyncDAO
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [OwnerInvitationSyncDAO::class])
internal class OwnerInvitationSyncPostgresDAO(
    private val client: PostgresClient,
) : OwnerInvitationSyncDAO {
    override suspend fun listAll(): List<OwnerInvitation> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT invitation_id, first_name, last_name, email, status, submitted_at, resend_requested_at, activated_at
                    FROM owner_invitation
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toOwnerInvitation())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        invitation: OwnerInvitation,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO owner_invitation(
                        invitation_id, first_name, last_name, email, status, submitted_at, resend_requested_at, activated_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (invitation_id)
                    DO UPDATE SET
                        first_name = EXCLUDED.first_name,
                        last_name = EXCLUDED.last_name,
                        email = EXCLUDED.email,
                        status = EXCLUDED.status,
                        submitted_at = EXCLUDED.submitted_at,
                        resend_requested_at = EXCLUDED.resend_requested_at,
                        activated_at = EXCLUDED.activated_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, invitation.invitationId.id)
                    stmt.setString(2, invitation.firstName)
                    stmt.setString(3, invitation.lastName)
                    stmt.setString(4, invitation.email)
                    stmt.setString(5, invitation.status.name)
                    stmt.setLong(6, invitation.submittedAt.toEpochMilliseconds())
                    stmt.setLongOrNull(7, invitation.resendRequestedAt)
                    stmt.setLongOrNull(8, invitation.activatedAt)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun findById(invitationId: Id<OwnerInvitation>): OwnerInvitation? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT invitation_id, first_name, last_name, email, status, submitted_at, resend_requested_at, activated_at
                    FROM owner_invitation
                    WHERE invitation_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, invitationId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toOwnerInvitation() else null
                    }
                }
        }

    override suspend fun existsPendingByEmail(email: String): Boolean =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "SELECT 1 FROM owner_invitation WHERE email = ? AND status = 'PENDING_ACTIVATION'",
                ).use { stmt ->
                    stmt.setString(1, email)
                    stmt.executeQuery().use { rs -> rs.next() }
                }
        }
}

private fun java.sql.ResultSet.toOwnerInvitation(): OwnerInvitation =
    OwnerInvitation(
        invitationId = getString("invitation_id").toId(),
        firstName = getString("first_name"),
        lastName = getString("last_name"),
        email = getString("email"),
        status = OwnerInvitationStatus.valueOf(getString("status")),
        submittedAt = Instant.fromEpochMilliseconds(getLong("submitted_at")),
        resendRequestedAt = getInstantOrNull("resend_requested_at"),
        activatedAt = getInstantOrNull("activated_at"),
    )

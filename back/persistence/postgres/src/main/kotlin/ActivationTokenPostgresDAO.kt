@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.ActivationTokenDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.MemberInvitation
import persistence.model.OrganizationRequest
import persistence.model.OwnerInvitation
import persistence.model.ProducerRequest
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ActivationTokenDAO::class])
internal class ActivationTokenPostgresDAO(
    private val client: PostgresClient,
) : ActivationTokenDAO {
    override suspend fun create(token: ActivationToken) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO activation_token(
                        token, kind, request_id, producer_request_id, admin_email, organization_id, producer_account_id, owner_invitation_id,
                        member_invitation_id, created_at, expires_at, invalidated_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, token.token)
                    stmt.setString(2, token.kind.name)
                    stmt.setString(3, token.requestId?.id)
                    stmt.setString(4, token.producerRequestId?.id)
                    stmt.setString(5, token.adminEmail)
                    stmt.setString(6, token.organizationId?.id)
                    stmt.setString(7, token.producerAccountId?.id)
                    stmt.setString(8, token.ownerInvitationId?.id)
                    stmt.setString(9, token.memberInvitationId?.id)
                    stmt.setLong(10, token.createdAt.toEpochMilliseconds())
                    stmt.setLong(11, token.expiresAt.toEpochMilliseconds())
                    stmt.setLongOrNull(12, token.invalidatedAt)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun findByToken(token: String): ActivationToken? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT token, kind, request_id, producer_request_id, admin_email, organization_id, producer_account_id, owner_invitation_id,
                           member_invitation_id, created_at, expires_at, invalidated_at, activated_at
                    FROM activation_token
                    WHERE token = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, token)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) {
                            ActivationToken(
                                token = rs.getString("token"),
                                kind = ActivationKind.valueOf(rs.getString("kind")),
                                requestId = rs.getString("request_id")?.toId(),
                                producerRequestId = rs.getString("producer_request_id")?.toId(),
                                adminEmail = rs.getString("admin_email"),
                                organizationId = rs.getString("organization_id")?.toId(),
                                producerAccountId = rs.getString("producer_account_id")?.toId(),
                                ownerInvitationId = rs.getString("owner_invitation_id")?.toId(),
                                memberInvitationId = rs.getString("member_invitation_id")?.toId(),
                                createdAt = Instant.fromEpochMilliseconds(rs.getLong("created_at")),
                                expiresAt = Instant.fromEpochMilliseconds(rs.getLong("expires_at")),
                                invalidatedAt = rs.getInstantOrNull("invalidated_at"),
                                activatedAt = rs.getInstantOrNull("activated_at"),
                            )
                        } else {
                            null
                        }
                    }
                }
        }

    override suspend fun markActivated(
        token: String,
        activatedAt: Instant,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE activation_token SET activated_at = ? WHERE token = ?",
                ).use { stmt ->
                    stmt.setLong(1, activatedAt.toEpochMilliseconds())
                    stmt.setString(2, token)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun invalidateByOwnerInvitationId(
        invitationId: Id<OwnerInvitation>,
        invalidatedAt: Instant,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE activation_token SET invalidated_at = ? WHERE owner_invitation_id = ? AND activated_at IS NULL",
                ).use { stmt ->
                    stmt.setLong(1, invalidatedAt.toEpochMilliseconds())
                    stmt.setString(2, invitationId.id)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun invalidateByMemberInvitationId(
        invitationId: Id<MemberInvitation>,
        invalidatedAt: Instant,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE activation_token SET invalidated_at = ? WHERE member_invitation_id = ? AND activated_at IS NULL",
                ).use { stmt ->
                    stmt.setLong(1, invalidatedAt.toEpochMilliseconds())
                    stmt.setString(2, invitationId.id)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun invalidateByOrganizationRequestId(
        requestId: Id<OrganizationRequest>,
        invalidatedAt: Instant,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE activation_token SET invalidated_at = ? WHERE request_id = ? AND activated_at IS NULL",
                ).use { stmt ->
                    stmt.setLong(1, invalidatedAt.toEpochMilliseconds())
                    stmt.setString(2, requestId.id)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun invalidateByProducerRequestId(
        requestId: Id<ProducerRequest>,
        invalidatedAt: Instant,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "UPDATE activation_token SET invalidated_at = ? WHERE producer_request_id = ? AND activated_at IS NULL",
                ).use { stmt ->
                    stmt.setLong(1, invalidatedAt.toEpochMilliseconds())
                    stmt.setString(2, requestId.id)
                    stmt.executeUpdate()
                }
        }
    }
}

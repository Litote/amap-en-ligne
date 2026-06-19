@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.MemberJoinRequestDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val SELECT_MEMBER_JOIN_REQUEST_COLUMNS = """
    SELECT request_id, organization_id, email, first_name, last_name,
           status, submitted_at, reviewed_at, review_comment
    FROM member_join_request
"""

@Single(createdAtStart = true, binds = [MemberJoinRequestDAO::class])
internal class MemberJoinRequestPostgresDAO(
    private val client: PostgresClient,
) : MemberJoinRequestDAO {
    override suspend fun create(request: MemberJoinRequest) =
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO member_join_request (
                        request_id, organization_id, email, first_name, last_name,
                        status, submitted_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.requestId.id)
                    stmt.setString(2, request.organizationId.id)
                    stmt.setString(3, request.email)
                    stmt.setString(4, request.firstName)
                    stmt.setString(5, request.lastName)
                    stmt.setString(6, request.status.name)
                    stmt.setLong(7, request.submittedAt.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
            Unit
        }

    override suspend fun existsPendingByEmailAndOrganization(
        email: String,
        organizationId: Id<Organization>,
    ): Boolean =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "SELECT 1 FROM member_join_request WHERE email = ? AND organization_id = ? AND status = 'PENDING'",
                ).use { stmt ->
                    stmt.setString(1, email)
                    stmt.setString(2, organizationId.id)
                    stmt.executeQuery().use { rs -> rs.next() }
                }
        }

    override suspend fun listByOrganization(organizationId: Id<Organization>): List<MemberJoinRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_MEMBER_JOIN_REQUEST_COLUMNS WHERE organization_id = ? ORDER BY submitted_at ASC".trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMemberJoinRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun listByOrganizationAndStatus(
        organizationId: Id<Organization>,
        status: MemberJoinRequestStatus,
    ): List<MemberJoinRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_MEMBER_JOIN_REQUEST_COLUMNS WHERE organization_id = ? AND status = ? ORDER BY submitted_at ASC".trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.setString(2, status.name)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toMemberJoinRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(requestId: Id<MemberJoinRequest>): MemberJoinRequest? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_MEMBER_JOIN_REQUEST_COLUMNS WHERE request_id = ? LIMIT 1".trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, requestId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toMemberJoinRequest() else null
                    }
                }
        }

    override suspend fun updateStatus(
        requestId: Id<MemberJoinRequest>,
        status: MemberJoinRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) = client.dataSource.tx { conn ->
        conn
            .prepareStatement(
                """
                UPDATE member_join_request
                SET status = ?, reviewed_at = ?, review_comment = ?
                WHERE request_id = ?
                """.trimIndent(),
            ).use { stmt ->
                stmt.setString(1, status.name)
                stmt.setLong(2, reviewedAt.toEpochMilliseconds())
                stmt.setString(3, reviewComment)
                stmt.setString(4, requestId.id)
                stmt.executeUpdate()
            }
        Unit
    }
}

private fun java.sql.ResultSet.toMemberJoinRequest(): MemberJoinRequest =
    MemberJoinRequest(
        requestId = getString("request_id").toId(),
        organizationId = getString("organization_id").toId(),
        email = getString("email"),
        firstName = getString("first_name"),
        lastName = getString("last_name"),
        status = MemberJoinRequestStatus.valueOf(getString("status")),
        submittedAt = Instant.fromEpochMilliseconds(getLong("submitted_at")),
        reviewedAt = getLong("reviewed_at").takeIf { !wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
        reviewComment = getString("review_comment"),
    )

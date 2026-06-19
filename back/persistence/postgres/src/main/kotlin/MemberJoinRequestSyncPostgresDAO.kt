@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val SELECT_MEMBER_JOIN_REQUEST_SYNC_COLUMNS = """
    SELECT request_id, organization_id, email, first_name, last_name,
           status, submitted_at, reviewed_at, review_comment
    FROM member_join_request
"""

@Single(createdAtStart = true, binds = [MemberJoinRequestSyncDAO::class])
internal class MemberJoinRequestSyncPostgresDAO(
    private val client: PostgresClient,
) : MemberJoinRequestSyncDAO {
    override suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberJoinRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_MEMBER_JOIN_REQUEST_SYNC_COLUMNS WHERE organization_id = ? ORDER BY submitted_at ASC".trimIndent(),
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

    override suspend fun put(
        request: MemberJoinRequest,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO member_join_request(
                        request_id, organization_id, email, first_name, last_name,
                        status, submitted_at, reviewed_at, review_comment
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (request_id)
                    DO UPDATE SET
                        organization_id = EXCLUDED.organization_id,
                        email = EXCLUDED.email,
                        first_name = EXCLUDED.first_name,
                        last_name = EXCLUDED.last_name,
                        status = EXCLUDED.status,
                        submitted_at = EXCLUDED.submitted_at,
                        reviewed_at = EXCLUDED.reviewed_at,
                        review_comment = EXCLUDED.review_comment
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.requestId.id)
                    stmt.setString(2, request.organizationId.id)
                    stmt.setString(3, request.email)
                    stmt.setString(4, request.firstName)
                    stmt.setString(5, request.lastName)
                    stmt.setString(6, request.status.name)
                    stmt.setLong(7, request.submittedAt.toEpochMilliseconds())
                    stmt.setLongOrNull(8, request.reviewedAt)
                    stmt.setString(9, request.reviewComment)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
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
        reviewedAt = getInstantOrNull("reviewed_at"),
        reviewComment = getString("review_comment"),
    )

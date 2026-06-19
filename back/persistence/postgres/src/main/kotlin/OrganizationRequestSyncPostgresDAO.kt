@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OrganizationRequestSyncDAO
import persistence.model.OrganizationRequest
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true, binds = [OrganizationRequestSyncDAO::class])
internal class OrganizationRequestSyncPostgresDAO(
    private val client: PostgresClient,
) : OrganizationRequestSyncDAO {
    override suspend fun listAll(): List<OrganizationRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_ORGANIZATION_REQUEST_COLUMNS ORDER BY submitted_at ASC".trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toOrganizationRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        request: OrganizationRequest,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization_request (
                        request_id, organization_name, organization_type, timezone, default_language,
                        admin_first_name, admin_last_name, admin_email,
                        status, submitted_at, reviewed_at, review_comment,
                        organization_id, resend_requested_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (request_id) DO UPDATE SET
                        status = EXCLUDED.status,
                        reviewed_at = EXCLUDED.reviewed_at,
                        review_comment = EXCLUDED.review_comment,
                        organization_id = EXCLUDED.organization_id,
                        resend_requested_at = EXCLUDED.resend_requested_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.requestId.id)
                    stmt.setString(2, request.organizationName)
                    stmt.setString(3, request.organizationType.name)
                    stmt.setString(4, request.timezone.id)
                    stmt.setString(5, request.defaultLanguage)
                    stmt.setString(6, request.adminFirstName)
                    stmt.setString(7, request.adminLastName)
                    stmt.setString(8, request.adminEmail)
                    stmt.setString(9, request.status.name)
                    stmt.setLong(10, request.submittedAt.toEpochMilliseconds())
                    val reviewedAt = request.reviewedAt
                    if (reviewedAt == null) {
                        stmt.setNull(11, java.sql.Types.BIGINT)
                    } else {
                        stmt.setLong(11, reviewedAt.toEpochMilliseconds())
                    }
                    stmt.setString(12, request.reviewComment)
                    stmt.setString(13, request.organizationId?.id)
                    val resendRequestedAt = request.resendRequestedAt
                    if (resendRequestedAt == null) {
                        stmt.setNull(14, java.sql.Types.BIGINT)
                    } else {
                        stmt.setLong(14, resendRequestedAt.toEpochMilliseconds())
                    }
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import kotlinx.datetime.TimeZone
import org.koin.core.annotation.Single
import persistence.dao.OrganizationRequestDAO
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal const val SELECT_ORGANIZATION_REQUEST_COLUMNS = """
    SELECT request_id, organization_name, organization_type, timezone, default_language,
           admin_first_name, admin_last_name, admin_email,
           status, submitted_at, reviewed_at, review_comment, submitter_comment,
           organization_id, resend_requested_at
    FROM organization_request
"""

@Single(createdAtStart = true, binds = [OrganizationRequestDAO::class])
internal class OrganizationRequestPostgresDAO(
    private val client: PostgresClient,
) : OrganizationRequestDAO {
    override suspend fun create(request: OrganizationRequest) =
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization_request (
                        request_id, organization_name, organization_type, timezone, default_language,
                        admin_first_name, admin_last_name, admin_email,
                        status, submitted_at, submitter_comment
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                    stmt.setString(11, request.submitterComment)
                    stmt.executeUpdate()
                }
            Unit
        }

    override suspend fun existsByOrganizationName(
        name: String,
        excludedStatuses: Set<OrganizationRequestStatus>,
    ): OrganizationRequestStatus? =
        client.dataSource.query { conn ->
            val sql =
                if (excludedStatuses.isEmpty()) {
                    "SELECT status FROM organization_request WHERE organization_name = ? LIMIT 1"
                } else {
                    val placeholders = excludedStatuses.joinToString(",") { "?" }
                    "SELECT status FROM organization_request WHERE organization_name = ? AND status NOT IN ($placeholders) LIMIT 1"
                }
            conn.prepareStatement(sql).use { stmt ->
                stmt.setString(1, name)
                excludedStatuses.forEachIndexed { index, status ->
                    stmt.setString(index + 2, status.name)
                }
                stmt.executeQuery().use { rs ->
                    if (rs.next()) OrganizationRequestStatus.valueOf(rs.getString("status")) else null
                }
            }
        }

    override suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<OrganizationRequestStatus>,
    ): OrganizationRequestStatus? =
        client.dataSource.query { conn ->
            val sql =
                if (excludedStatuses.isEmpty()) {
                    "SELECT status FROM organization_request WHERE admin_email = ? LIMIT 1"
                } else {
                    val placeholders = excludedStatuses.joinToString(",") { "?" }
                    "SELECT status FROM organization_request WHERE admin_email = ? AND status NOT IN ($placeholders) LIMIT 1"
                }
            conn.prepareStatement(sql).use { stmt ->
                stmt.setString(1, email)
                excludedStatuses.forEachIndexed { index, status ->
                    stmt.setString(index + 2, status.name)
                }
                stmt.executeQuery().use { rs ->
                    if (rs.next()) OrganizationRequestStatus.valueOf(rs.getString("status")) else null
                }
            }
        }

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

    override suspend fun listByStatus(status: OrganizationRequestStatus): List<OrganizationRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_ORGANIZATION_REQUEST_COLUMNS WHERE status = ? ORDER BY submitted_at ASC".trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, status.name)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toOrganizationRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(requestId: Id<OrganizationRequest>): OrganizationRequest? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    "$SELECT_ORGANIZATION_REQUEST_COLUMNS WHERE request_id = ? LIMIT 1".trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, requestId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toOrganizationRequest() else null
                    }
                }
        }

    override suspend fun updateStatus(
        requestId: Id<OrganizationRequest>,
        status: OrganizationRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) = client.dataSource.tx { conn ->
        conn
            .prepareStatement(
                """
                UPDATE organization_request
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

internal fun java.sql.ResultSet.toOrganizationRequest(): OrganizationRequest =
    OrganizationRequest(
        requestId = getString("request_id").toId(),
        organizationName = getString("organization_name"),
        organizationType = OrganizationType.valueOf(getString("organization_type")),
        timezone = TimeZone.of(getString("timezone")),
        defaultLanguage = getString("default_language"),
        adminFirstName = getString("admin_first_name"),
        adminLastName = getString("admin_last_name"),
        adminEmail = getString("admin_email"),
        status = OrganizationRequestStatus.valueOf(getString("status")),
        submittedAt = Instant.fromEpochMilliseconds(getLong("submitted_at")),
        reviewedAt = getLong("reviewed_at").takeIf { !wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
        reviewComment = getString("review_comment"),
        submitterComment = getString("submitter_comment"),
        organizationId = getString("organization_id")?.toId(),
        resendRequestedAt = getLong("resend_requested_at").takeIf { !wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
    )

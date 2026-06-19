@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.ProducerRequestDAO
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal const val SELECT_PRODUCER_REQUEST_COLUMNS = """
    SELECT request_id, producer_name, admin_first_name, admin_last_name, admin_email,
           status, submitted_at, reviewed_at, review_comment, submitter_comment,
           producer_account_id, resend_requested_at
    FROM producer_request
"""

@Single(createdAtStart = true, binds = [ProducerRequestDAO::class])
internal class ProducerRequestPostgresDAO(
    private val client: PostgresClient,
) : ProducerRequestDAO {
    override suspend fun create(request: ProducerRequest) =
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_request (
                        request_id, producer_name, admin_first_name, admin_last_name, admin_email,
                        status, submitted_at, submitter_comment
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.requestId.id)
                    stmt.setString(2, request.producerName)
                    stmt.setString(3, request.adminFirstName)
                    stmt.setString(4, request.adminLastName)
                    stmt.setString(5, request.adminEmail)
                    stmt.setString(6, request.status.name)
                    stmt.setLong(7, request.submittedAt.toEpochMilliseconds())
                    stmt.setString(8, request.submitterComment)
                    stmt.executeUpdate()
                }
            Unit
        }

    override suspend fun existsByProducerName(
        name: String,
        excludedStatuses: Set<ProducerRequestStatus>,
    ): ProducerRequestStatus? =
        client.dataSource.query { conn ->
            val sql =
                if (excludedStatuses.isEmpty()) {
                    "SELECT status FROM producer_request WHERE producer_name = ? LIMIT 1"
                } else {
                    val placeholders = excludedStatuses.joinToString(",") { "?" }
                    "SELECT status FROM producer_request WHERE producer_name = ? AND status NOT IN ($placeholders) LIMIT 1"
                }
            conn.prepareStatement(sql).use { stmt ->
                stmt.setString(1, name)
                excludedStatuses.forEachIndexed { index, status ->
                    stmt.setString(index + 2, status.name)
                }
                stmt.executeQuery().use { rs ->
                    if (rs.next()) ProducerRequestStatus.valueOf(rs.getString("status")) else null
                }
            }
        }

    override suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<ProducerRequestStatus>,
    ): ProducerRequestStatus? =
        client.dataSource.query { conn ->
            val sql =
                if (excludedStatuses.isEmpty()) {
                    "SELECT status FROM producer_request WHERE admin_email = ? LIMIT 1"
                } else {
                    val placeholders = excludedStatuses.joinToString(",") { "?" }
                    "SELECT status FROM producer_request WHERE admin_email = ? AND status NOT IN ($placeholders) LIMIT 1"
                }
            conn.prepareStatement(sql).use { stmt ->
                stmt.setString(1, email)
                excludedStatuses.forEachIndexed { index, status ->
                    stmt.setString(index + 2, status.name)
                }
                stmt.executeQuery().use { rs ->
                    if (rs.next()) ProducerRequestStatus.valueOf(rs.getString("status")) else null
                }
            }
        }

    override suspend fun listAll(): List<ProducerRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement("$SELECT_PRODUCER_REQUEST_COLUMNS ORDER BY submitted_at ASC".trimIndent())
                .use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toProducerRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun listByStatus(status: ProducerRequestStatus): List<ProducerRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement("$SELECT_PRODUCER_REQUEST_COLUMNS WHERE status = ? ORDER BY submitted_at ASC".trimIndent())
                .use { stmt ->
                    stmt.setString(1, status.name)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toProducerRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(requestId: Id<ProducerRequest>): ProducerRequest? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement("$SELECT_PRODUCER_REQUEST_COLUMNS WHERE request_id = ? LIMIT 1".trimIndent())
                .use { stmt ->
                    stmt.setString(1, requestId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toProducerRequest() else null
                    }
                }
        }

    override suspend fun updateStatus(
        requestId: Id<ProducerRequest>,
        status: ProducerRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) = client.dataSource.tx { conn ->
        conn
            .prepareStatement(
                """
                UPDATE producer_request
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

internal fun java.sql.ResultSet.toProducerRequest(): ProducerRequest =
    ProducerRequest(
        requestId = getString("request_id").toId(),
        producerName = getString("producer_name"),
        adminFirstName = getString("admin_first_name"),
        adminLastName = getString("admin_last_name"),
        adminEmail = getString("admin_email"),
        status = ProducerRequestStatus.valueOf(getString("status")),
        submittedAt = Instant.fromEpochMilliseconds(getLong("submitted_at")),
        reviewedAt = getLong("reviewed_at").takeIf { !wasNull() }?.let(Instant::fromEpochMilliseconds),
        reviewComment = getString("review_comment"),
        submitterComment = getString("submitter_comment"),
        producerAccountId = getString("producer_account_id")?.toId(),
        resendRequestedAt = getLong("resend_requested_at").takeIf { !wasNull() }?.let(Instant::fromEpochMilliseconds),
    )

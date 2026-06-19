@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProducerRequestSyncDAO
import persistence.model.ProducerRequest
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true, binds = [ProducerRequestSyncDAO::class])
internal class ProducerRequestSyncPostgresDAO(
    private val client: PostgresClient,
) : ProducerRequestSyncDAO {
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

    override suspend fun put(
        request: ProducerRequest,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_request (
                        request_id, producer_name, admin_first_name, admin_last_name, admin_email,
                        status, submitted_at, reviewed_at, review_comment,
                        producer_account_id, resend_requested_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (request_id) DO UPDATE SET
                        status = EXCLUDED.status,
                        reviewed_at = EXCLUDED.reviewed_at,
                        review_comment = EXCLUDED.review_comment,
                        producer_account_id = EXCLUDED.producer_account_id,
                        resend_requested_at = EXCLUDED.resend_requested_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.requestId.id)
                    stmt.setString(2, request.producerName)
                    stmt.setString(3, request.adminFirstName)
                    stmt.setString(4, request.adminLastName)
                    stmt.setString(5, request.adminEmail)
                    stmt.setString(6, request.status.name)
                    stmt.setLong(7, request.submittedAt.toEpochMilliseconds())
                    val reviewedAt = request.reviewedAt
                    if (reviewedAt == null) {
                        stmt.setNull(8, java.sql.Types.BIGINT)
                    } else {
                        stmt.setLong(8, reviewedAt.toEpochMilliseconds())
                    }
                    stmt.setString(9, request.reviewComment)
                    stmt.setString(10, request.producerAccountId?.id)
                    val resendRequestedAt = request.resendRequestedAt
                    if (resendRequestedAt == null) {
                        stmt.setNull(11, java.sql.Types.BIGINT)
                    } else {
                        stmt.setLong(11, resendRequestedAt.toEpochMilliseconds())
                    }
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

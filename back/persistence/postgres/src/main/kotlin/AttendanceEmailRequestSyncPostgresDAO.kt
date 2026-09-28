@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.model.AttendanceEmailRequest
import persistence.model.Organization
import java.sql.ResultSet
import java.sql.Types
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [AttendanceEmailRequestSyncDAO::class])
internal class AttendanceEmailRequestSyncPostgresDAO(
    private val client: PostgresClient,
) : AttendanceEmailRequestSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<AttendanceEmailRequest> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT attendance_email_request_id, organization_id, delivery_id,
                           recipient_email, requested_at, sent_at
                    FROM attendance_email_request
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toAttendanceEmailRequest())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(id: Id<AttendanceEmailRequest>): AttendanceEmailRequest? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT attendance_email_request_id, organization_id, delivery_id,
                           recipient_email, requested_at, sent_at
                    FROM attendance_email_request
                    WHERE attendance_email_request_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, id.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toAttendanceEmailRequest() else null
                    }
                }
        }

    override suspend fun put(
        request: AttendanceEmailRequest,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO attendance_email_request (
                        attendance_email_request_id, organization_id, delivery_id,
                        recipient_email, requested_at, sent_at
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT (attendance_email_request_id)
                    DO UPDATE SET
                        organization_id = EXCLUDED.organization_id,
                        delivery_id = EXCLUDED.delivery_id,
                        recipient_email = EXCLUDED.recipient_email,
                        requested_at = EXCLUDED.requested_at,
                        sent_at = EXCLUDED.sent_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, request.attendanceEmailRequestId.id)
                    stmt.setString(2, request.organizationId.id)
                    stmt.setString(3, request.deliveryId)
                    stmt.setString(4, request.recipientEmail)
                    stmt.setLong(5, request.requestedAt.toEpochMilliseconds())
                    val sentAt = request.sentAt
                    if (sentAt == null) {
                        stmt.setNull(6, Types.BIGINT)
                    } else {
                        stmt.setLong(6, sentAt.toEpochMilliseconds())
                    }
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toAttendanceEmailRequest(): AttendanceEmailRequest =
    AttendanceEmailRequest(
        attendanceEmailRequestId = getString("attendance_email_request_id").toId(),
        organizationId = getString("organization_id").toId(),
        deliveryId = getString("delivery_id"),
        recipientEmail = getString("recipient_email"),
        requestedAt = Instant.fromEpochMilliseconds(getLong("requested_at")),
        sentAt = getLong("sent_at").takeIf { !wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
    )

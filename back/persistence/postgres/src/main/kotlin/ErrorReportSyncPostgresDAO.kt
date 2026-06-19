@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.postgres

import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ErrorReportSyncDAO
import persistence.model.ErrorReport
import java.sql.ResultSet
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ErrorReportSyncDAO::class])
internal class ErrorReportSyncPostgresDAO(
    private val client: PostgresClient,
) : ErrorReportSyncDAO {
    override suspend fun listAll(): List<ErrorReport> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT error_report_id, error_message, reported_at
                    FROM error_report
                    ORDER BY reported_at ASC
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toErrorReport())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        errorReport: ErrorReport,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO error_report (error_report_id, error_message, reported_at)
                    VALUES (?, ?, ?)
                    ON CONFLICT (error_report_id)
                    DO UPDATE SET
                        error_message = EXCLUDED.error_message,
                        reported_at = EXCLUDED.reported_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, errorReport.errorReportId.id)
                    stmt.setString(2, errorReport.errorMessage)
                    stmt.setLong(3, errorReport.reportedAt.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toErrorReport(): ErrorReport =
    ErrorReport(
        errorReportId = getString("error_report_id").toId(),
        errorMessage = getString("error_message"),
        reportedAt = Instant.fromEpochMilliseconds(getLong("reported_at")),
    )

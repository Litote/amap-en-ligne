@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ErrorReportPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.ErrorReport
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Clock

@Execution(ExecutionMode.SAME_THREAD)
abstract class ErrorReportSyncDAOContractTest {
    protected abstract val errorReportSyncDAO: ErrorReportSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected abstract fun clearAll()

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun newReportId() = UUID.randomUUID().toString()

    protected fun buildReport(reportId: String = newReportId()): ErrorReport =
        ErrorReport(
            errorReportId = reportId.toId(),
            errorMessage = "Sync failed: connection timeout",
            reportedAt = Clock.System.now(),
        )

    protected fun buildUpsertChange(report: ErrorReport): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ErrorReport,
            entityId = report.errorReportId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = ErrorReportPayload(errorReport = report),
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a report WHEN put then listAll THEN returns it`() =
        runTest {
            val report = buildReport()

            errorReportSyncDAO.put(report, buildUpsertChange(report))

            val result = errorReportSyncDAO.listAll()
            assertTrue(result.any { it.errorReportId == report.errorReportId })
        }

    @Test
    fun `GIVEN no reports WHEN listAll THEN returns empty list`() =
        runTest {
            val result = errorReportSyncDAO.listAll()
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN two reports WHEN listAll THEN returns both`() =
        runTest {
            val report1 = buildReport()
            val report2 = buildReport()

            errorReportSyncDAO.put(report1, buildUpsertChange(report1))
            errorReportSyncDAO.put(report2, buildUpsertChange(report2))

            val result = errorReportSyncDAO.listAll()
            assertEquals(2, result.size)
            assertTrue(result.any { it.errorReportId == report1.errorReportId })
            assertTrue(result.any { it.errorReportId == report2.errorReportId })
        }

    @Test
    fun `GIVEN a report WHEN put THEN change is recorded on instance-owner scope`() =
        runTest {
            val report = buildReport()
            val change = buildUpsertChange(report)

            errorReportSyncDAO.put(report, change)

            val changes = changeDAO.since(SyncScope.InstanceOwner.key, null)
            assertTrue(changes.any { it.entityId == report.errorReportId.id })
        }

    @Test
    fun `GIVEN a report WHEN put THEN fields are preserved`() =
        runTest {
            val report = buildReport()

            errorReportSyncDAO.put(report, buildUpsertChange(report))

            val result = errorReportSyncDAO.listAll().single()
            assertEquals(report.errorReportId, result.errorReportId)
            assertEquals(report.errorMessage, result.errorMessage)
            assertEquals(report.reportedAt.toEpochMilliseconds(), result.reportedAt.toEpochMilliseconds())
        }
}

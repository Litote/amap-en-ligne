@file:OptIn(kotlin.time.ExperimentalTime::class)

package errorreport

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import persistence.changes.Change
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.ErrorReportPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ErrorReportSyncDAO
import persistence.model.EntityType
import persistence.model.ErrorReport
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Clock

private const val TMP_REPORT_ID = "tmp_report-1"
private const val REAL_REPORT_ID = "report-real-1"

internal class ErrorReportServiceTest {
    private val errorReportSyncDAO = mockk<ErrorReportSyncDAO>(relaxed = true)

    private val service = ErrorReportService(errorReportSyncDAO)

    private val anyAuth =
        AuthenticatedInfo(
            memberId = "user-1",
            firstName = "Alice",
            lastName = "User",
            email = "alice@example.com",
            roles = listOf(Role.ADMIN),
        )

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "owner-1",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            roles = listOf(Role.OWNER),
        )

    private fun buildPayload(reportId: String): ErrorReportPayload =
        ErrorReportPayload(
            errorReport =
                ErrorReport(
                    errorReportId = reportId.toId(),
                    errorMessage = "Sync failed: connection timeout",
                    reportedAt = Clock.System.now(),
                ),
        )

    private fun buildMutation(reportId: String): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(buildPayload(reportId)),
        )

    private fun buildDeleteMutation(reportId: String): ClientMutation =
        ClientMutation(
            clientOpId = "op-2",
            op = Delete(entityType = EntityType.ErrorReport, entityId = reportId),
        )

    @Test
    fun `GIVEN upsert with tmp_ id WHEN applyUpsert THEN APPLIED and real id allocated`() =
        runTest {
            val mutation = buildMutation(TMP_REPORT_ID)

            val outcome = service.applyUpsert(anyAuth, mutation, buildPayload(TMP_REPORT_ID))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotNull(outcome.serverEntityId)
            assert(!outcome.serverEntityId!!.startsWith("tmp_")) { "serverEntityId must be a real id" }
        }

    @Test
    fun `GIVEN upsert with tmp_ id WHEN applyUpsert THEN entity is persisted via DAO`() =
        runTest {
            val mutation = buildMutation(TMP_REPORT_ID)
            val capturedReport = slot<ErrorReport>()
            coEvery { errorReportSyncDAO.put(capture(capturedReport), any()) } returns Unit

            service.applyUpsert(anyAuth, mutation, buildPayload(TMP_REPORT_ID))

            coVerify(exactly = 1) { errorReportSyncDAO.put(any(), any()) }
            assertNotNull(capturedReport.captured)
            assertEquals("Sync failed: connection timeout", capturedReport.captured.errorMessage)
        }

    @Test
    fun `GIVEN upsert with tmp_ id WHEN applyUpsert THEN change is on instance-owner scope`() =
        runTest {
            val mutation = buildMutation(TMP_REPORT_ID)
            val capturedChange = slot<Change>()
            coEvery { errorReportSyncDAO.put(any(), capture(capturedChange)) } returns Unit

            service.applyUpsert(anyAuth, mutation, buildPayload(TMP_REPORT_ID))

            assertEquals(SyncScope.InstanceOwner.key, capturedChange.captured.scopeKey)
            assertEquals(EntityType.ErrorReport, capturedChange.captured.entityType)
        }

    @Test
    fun `GIVEN upsert with real id WHEN applyUpsert THEN FORBIDDEN`() =
        runTest {
            val mutation = buildMutation(REAL_REPORT_ID)

            val outcome = service.applyUpsert(anyAuth, mutation, buildPayload(REAL_REPORT_ID))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { errorReportSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN delete mutation WHEN applyDelete THEN FORBIDDEN`() =
        runTest {
            val mutation = buildDeleteMutation(REAL_REPORT_ID)

            val outcome = service.applyDelete(anyAuth, mutation, mutation.op as Delete)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN owner caller WHEN snapshot on InstanceOwner scope THEN returns all reports`() =
        runTest {
            val report =
                ErrorReport(
                    errorReportId = REAL_REPORT_ID.toId(),
                    errorMessage = "Something went wrong",
                    reportedAt = Clock.System.now(),
                )
            coEvery { errorReportSyncDAO.listAll() } returns listOf(report)

            val result = service.snapshot(ownerAuth, SyncScope.InstanceOwner)

            assertEquals(1, result.size)
            assertEquals(
                REAL_REPORT_ID,
                result
                    .first()
                    .errorReport.errorReportId.id,
            )
        }

    @Test
    fun `GIVEN any caller WHEN snapshot on Organization scope THEN returns empty list`() =
        runTest {
            val result = service.snapshot(anyAuth, SyncScope.Organization("org-1"))

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { errorReportSyncDAO.listAll() }
        }

    @Test
    fun `GIVEN any caller WHEN snapshot on ProducerAccount scope THEN returns empty list`() =
        runTest {
            val result = service.snapshot(anyAuth, SyncScope.ProducerAccount("pa-1"))

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { errorReportSyncDAO.listAll() }
        }

    @Test
    fun `GIVEN non-owner caller with tmp_ id WHEN applyUpsert THEN APPLIED`() =
        runTest {
            val producerAuth =
                AuthenticatedInfo(
                    memberId = "producer-1",
                    firstName = "Producer",
                    lastName = "User",
                    email = "producer@example.com",
                    roles = listOf(Role.PRODUCER),
                )
            val mutation = buildMutation(TMP_REPORT_ID)

            val outcome = service.applyUpsert(producerAuth, mutation, buildPayload(TMP_REPORT_ID))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }
}

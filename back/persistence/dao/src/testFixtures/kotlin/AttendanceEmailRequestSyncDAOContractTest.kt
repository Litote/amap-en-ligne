@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.AttendanceEmailRequestPayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.SyncScope
import persistence.model.AttendanceEmailRequest
import persistence.model.EntityType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class AttendanceEmailRequestSyncDAOContractTest {
    protected abstract val attendanceEmailRequestSyncDAO: AttendanceEmailRequestSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun newRequestId() = UUID.randomUUID().toString()

    protected fun buildRequest(
        requestId: String = newRequestId(),
        organizationId: String = newOrganizationId(),
        deliveryId: String = UUID.randomUUID().toString(),
        recipientEmail: String = "recipient@example.com",
        sentAt: kotlin.time.Instant? = null,
    ): AttendanceEmailRequest {
        val now = Clock.System.now()
        return AttendanceEmailRequest(
            attendanceEmailRequestId = requestId.toId(),
            organizationId = organizationId.toId(),
            deliveryId = deliveryId,
            recipientEmail = recipientEmail,
            requestedAt = now,
            sentAt = sentAt,
        )
    }

    protected fun buildUpsertChange(
        request: AttendanceEmailRequest,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.AttendanceEmailRequest,
            entityId = request.attendanceEmailRequestId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = AttendanceEmailRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a request WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request = buildRequest(organizationId = orgId)

            attendanceEmailRequestSyncDAO.put(request, buildUpsertChange(request, orgId))

            val result = attendanceEmailRequestSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(request.attendanceEmailRequestId, result.first().attendanceEmailRequestId)
        }

    @Test
    fun `GIVEN no requests WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = attendanceEmailRequestSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a request WHEN findById THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request = buildRequest(organizationId = orgId)
            attendanceEmailRequestSyncDAO.put(request, buildUpsertChange(request, orgId))

            val found = attendanceEmailRequestSyncDAO.findById(request.attendanceEmailRequestId)

            assertNotNull(found)
            assertEquals(request.attendanceEmailRequestId, found.attendanceEmailRequestId)
            assertEquals(request.recipientEmail, found.recipientEmail)
            assertEquals(request.deliveryId, found.deliveryId)
        }

    @Test
    fun `GIVEN no request WHEN findById THEN returns null`() =
        runTest {
            val found = attendanceEmailRequestSyncDAO.findById(newRequestId().toId())

            assertNull(found)
        }

    @Test
    fun `GIVEN requests for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val requestA = buildRequest(organizationId = orgA)
            val requestB = buildRequest(organizationId = orgB)

            attendanceEmailRequestSyncDAO.put(requestA, buildUpsertChange(requestA, orgA))
            attendanceEmailRequestSyncDAO.put(requestB, buildUpsertChange(requestB, orgB))

            val result = attendanceEmailRequestSyncDAO.getByOrganizationId(orgA.toId())
            assertEquals(1, result.size)
            assertEquals(requestA.attendanceEmailRequestId, result.first().attendanceEmailRequestId)
        }

    @Test
    fun `GIVEN multiple requests for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request1 = buildRequest(organizationId = orgId)
            val request2 = buildRequest(organizationId = orgId)

            attendanceEmailRequestSyncDAO.put(request1, buildUpsertChange(request1, orgId))
            attendanceEmailRequestSyncDAO.put(request2, buildUpsertChange(request2, orgId))

            val result = attendanceEmailRequestSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.attendanceEmailRequestId == request1.attendanceEmailRequestId })
            assertTrue(result.any { it.attendanceEmailRequestId == request2.attendanceEmailRequestId })
        }

    @Test
    fun `GIVEN a request WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request = buildRequest(organizationId = orgId)
            val change = buildUpsertChange(request, orgId)

            attendanceEmailRequestSyncDAO.put(request, change)

            val changes = changeDAO.since(SyncScope.Organization(orgId).key, null)
            assertNotNull(changes.find { it.entityId == request.attendanceEmailRequestId.id })
        }

    @Test
    fun `GIVEN a request with sentAt WHEN put then findById THEN sentAt is preserved`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val now = Clock.System.now()
            val request = buildRequest(organizationId = orgId, sentAt = now)
            attendanceEmailRequestSyncDAO.put(request, buildUpsertChange(request, orgId))

            val found = attendanceEmailRequestSyncDAO.findById(request.attendanceEmailRequestId)

            assertNotNull(found)
            assertNotNull(found.sentAt)
            assertEquals(now.toEpochMilliseconds(), found.sentAt!!.toEpochMilliseconds())
        }

    @Test
    fun `GIVEN a request with null sentAt WHEN put then findById THEN sentAt is null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request = buildRequest(organizationId = orgId, sentAt = null)
            attendanceEmailRequestSyncDAO.put(request, buildUpsertChange(request, orgId))

            val found = attendanceEmailRequestSyncDAO.findById(request.attendanceEmailRequestId)

            assertNotNull(found)
            assertNull(found.sentAt)
        }
}

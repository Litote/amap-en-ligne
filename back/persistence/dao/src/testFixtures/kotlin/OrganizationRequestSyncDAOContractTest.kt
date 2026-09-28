@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OrganizationRequestPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class OrganizationRequestSyncDAOContractTest {
    protected abstract val organizationRequestSyncDAO: OrganizationRequestSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected abstract fun clearAll()

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun newRequestId() = UUID.randomUUID().toString()

    protected fun buildRequest(
        requestId: String = newRequestId(),
        status: OrganizationRequestStatus = OrganizationRequestStatus.PENDING_VALIDATION,
    ): OrganizationRequest =
        OrganizationRequest(
            requestId = requestId.toId(),
            organizationName = "AMAP des Collines $requestId",
            organizationType = OrganizationType.AMAP,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean-$requestId@example.com",
            status = status,
            submittedAt = Clock.System.now(),
        )

    protected fun buildUpsertChange(request: OrganizationRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.OrganizationRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OrganizationRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a request WHEN put then listAll THEN returns it`() =
        runTest {
            val request = buildRequest()

            organizationRequestSyncDAO.put(request, buildUpsertChange(request))

            val result = organizationRequestSyncDAO.listAll()
            assertTrue(result.any { it.requestId == request.requestId })
        }

    @Test
    fun `GIVEN no requests WHEN listAll THEN returns empty list`() =
        runTest {
            val result = organizationRequestSyncDAO.listAll()
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN two requests WHEN listAll THEN returns both`() =
        runTest {
            val request1 = buildRequest()
            val request2 = buildRequest()

            organizationRequestSyncDAO.put(request1, buildUpsertChange(request1))
            organizationRequestSyncDAO.put(request2, buildUpsertChange(request2))

            val result = organizationRequestSyncDAO.listAll()
            assertEquals(2, result.size)
            assertTrue(result.any { it.requestId == request1.requestId })
            assertTrue(result.any { it.requestId == request2.requestId })
        }

    @Test
    fun `GIVEN an existing request WHEN put with updated status THEN listAll returns updated status`() =
        runTest {
            val request = buildRequest()
            organizationRequestSyncDAO.put(request, buildUpsertChange(request))

            val updated = request.copy(status = OrganizationRequestStatus.APPROVED)
            organizationRequestSyncDAO.put(updated, buildUpsertChange(updated))

            val result = organizationRequestSyncDAO.listAll()
            val found = result.find { it.requestId == request.requestId }
            assertNotNull(found)
            assertEquals(OrganizationRequestStatus.APPROVED, found.status)
        }

    @Test
    fun `GIVEN a request WHEN put THEN change scope key is instance-owner`() =
        runTest {
            val request = buildRequest()
            val change = buildUpsertChange(request)

            organizationRequestSyncDAO.put(request, change)

            val changes = changeDAO.since(SyncScope.InstanceOwner.key, null)
            assertNotNull(changes.find { it.entityId == request.requestId.id })
        }
}

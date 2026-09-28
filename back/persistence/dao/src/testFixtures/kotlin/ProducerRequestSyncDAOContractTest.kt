@file:OptIn(ExperimentalTime::class)

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
import persistence.changes.ProducerRequestPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class ProducerRequestSyncDAOContractTest {
    protected abstract val producerRequestSyncDAO: ProducerRequestSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected abstract fun clearAll()

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun buildRequest(
        requestId: String = UUID.randomUUID().toString(),
        status: ProducerRequestStatus = ProducerRequestStatus.PENDING_VALIDATION,
    ): ProducerRequest =
        ProducerRequest(
            requestId = requestId.toId(),
            producerName = "Producer $requestId",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean-$requestId@example.com",
            status = status,
            submittedAt = Clock.System.now(),
        )

    protected fun buildUpsertChange(request: ProducerRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProducerRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = ProducerRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a request WHEN put then listAll THEN returns it`() =
        runTest {
            val request = buildRequest()

            producerRequestSyncDAO.put(request, buildUpsertChange(request))

            val result = producerRequestSyncDAO.listAll()
            assertTrue(result.any { it.requestId == request.requestId })
        }

    @Test
    fun `GIVEN two requests WHEN listAll THEN returns both`() =
        runTest {
            val request1 = buildRequest()
            val request2 = buildRequest()

            producerRequestSyncDAO.put(request1, buildUpsertChange(request1))
            producerRequestSyncDAO.put(request2, buildUpsertChange(request2))

            val result = producerRequestSyncDAO.listAll()
            assertEquals(2, result.size)
        }

    @Test
    fun `GIVEN an existing request WHEN put with updated status THEN listAll returns updated status`() =
        runTest {
            val request = buildRequest()
            producerRequestSyncDAO.put(request, buildUpsertChange(request))

            val updated = request.copy(status = ProducerRequestStatus.APPROVED)
            producerRequestSyncDAO.put(updated, buildUpsertChange(updated))

            val result = producerRequestSyncDAO.listAll()
            val found = result.find { it.requestId == request.requestId }
            assertNotNull(found)
            assertEquals(ProducerRequestStatus.APPROVED, found.status)
        }

    @Test
    fun `GIVEN a request WHEN put THEN change scope key is instance-owner`() =
        runTest {
            val request = buildRequest()

            producerRequestSyncDAO.put(request, buildUpsertChange(request))

            val changes = changeDAO.since(SyncScope.InstanceOwner.key, null)
            assertNotNull(changes.find { it.entityId == request.requestId.id })
        }
}

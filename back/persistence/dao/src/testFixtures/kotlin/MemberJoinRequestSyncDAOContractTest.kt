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
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class MemberJoinRequestSyncDAOContractTest {
    protected abstract val memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected abstract fun clearAll()

    protected open fun ensureOrganizationExists(organizationId: String) {}

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun buildRequest(
        organizationId: String = "org-${UUID.randomUUID()}",
        status: MemberJoinRequestStatus = MemberJoinRequestStatus.PENDING,
    ): MemberJoinRequest {
        ensureOrganizationExists(organizationId)
        return MemberJoinRequest(
            requestId = UUID.randomUUID().toString().toId(),
            organizationId = organizationId.toId(),
            email = "member-${UUID.randomUUID()}@example.com",
            firstName = "Alice",
            lastName = "Martin",
            status = status,
            submittedAt = Clock.System.now(),
        )
    }

    protected fun buildUpsertChange(request: MemberJoinRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberJoinRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.Organization(request.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = MemberJoinRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a request WHEN put THEN listByOrganizationId returns it`() =
        runTest {
            val request = buildRequest()

            memberJoinRequestSyncDAO.put(request, buildUpsertChange(request))

            val result = memberJoinRequestSyncDAO.listByOrganizationId(request.organizationId)
            assertEquals(listOf(request.requestId), result.map { it.requestId })
        }

    @Test
    fun `GIVEN updated request WHEN put THEN listByOrganizationId returns updated status`() =
        runTest {
            val request = buildRequest()
            memberJoinRequestSyncDAO.put(request, buildUpsertChange(request))

            val updated =
                request.copy(
                    status = MemberJoinRequestStatus.REJECTED,
                    reviewedAt = Clock.System.now(),
                    reviewComment = "No slots",
                )
            memberJoinRequestSyncDAO.put(updated, buildUpsertChange(updated))

            val found = memberJoinRequestSyncDAO.listByOrganizationId(request.organizationId).single()
            assertEquals(MemberJoinRequestStatus.REJECTED, found.status)
            assertEquals("No slots", found.reviewComment)
        }

    @Test
    fun `GIVEN no requests WHEN listByOrganizationId THEN returns empty list`() =
        runTest {
            val result = memberJoinRequestSyncDAO.listByOrganizationId("org-missing".toId())

            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a request WHEN put THEN change is written in organization scope`() =
        runTest {
            val request = buildRequest()

            memberJoinRequestSyncDAO.put(request, buildUpsertChange(request))

            val changes = changeDAO.since(SyncScope.Organization(request.organizationId.id).key, null)
            val change = changes.find { it.entityId == request.requestId.id }
            assertNotNull(change)
            assertEquals(EntityType.MemberJoinRequest, change.entityType)
        }
}

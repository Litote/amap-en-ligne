@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class MemberJoinRequestDAOContractTest {
    protected abstract val dao: MemberJoinRequestDAO

    protected abstract fun clearAll()

    /**
     * Ensure the organization with the given id exists in the underlying store.
     * Implementations backed by a relational database must insert the org row;
     * DynamoDB implementations can be a no-op.
     */
    protected open fun ensureOrganizationExists(organizationId: String) {}

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun buildRequest(
        orgId: String = "org-${UUID.randomUUID()}",
        email: String = "${UUID.randomUUID()}@example.com",
    ): MemberJoinRequest {
        ensureOrganizationExists(orgId)
        return MemberJoinRequest(
            requestId = UUID.randomUUID().toString().toId(),
            organizationId = orgId.toId(),
            email = email,
            firstName = "Jean",
            lastName = "Dupont",
            status = MemberJoinRequestStatus.PENDING,
            submittedAt = Clock.System.now(),
        )
    }

    @Test
    fun `GIVEN a pending request WHEN create THEN existsPendingByEmailAndOrganization returns true`() =
        runTest {
            val orgId = "org-${UUID.randomUUID()}"
            val email = "${UUID.randomUUID()}@example.com"
            val request = buildRequest(orgId = orgId, email = email)

            dao.create(request)

            assertTrue(dao.existsPendingByEmailAndOrganization(email, orgId.toId()))
        }

    @Test
    fun `GIVEN no request WHEN existsPendingByEmailAndOrganization THEN returns false`() =
        runTest {
            assertFalse(dao.existsPendingByEmailAndOrganization("nobody@example.com", "org-unknown".toId()))
        }

    @Test
    fun `GIVEN same email in different org WHEN existsPendingByEmailAndOrganization THEN returns false`() =
        runTest {
            val email = "${UUID.randomUUID()}@example.com"
            val orgA = "org-${UUID.randomUUID()}"
            val orgB = "org-${UUID.randomUUID()}"
            dao.create(buildRequest(orgId = orgA, email = email))

            assertFalse(dao.existsPendingByEmailAndOrganization(email, orgB.toId()))
        }

    @Test
    fun `GIVEN an APPROVED request WHEN existsPendingByEmailAndOrganization THEN returns false`() =
        runTest {
            val orgId = "org-${UUID.randomUUID()}"
            val email = "${UUID.randomUUID()}@example.com"
            val request = buildRequest(orgId = orgId, email = email)
            dao.create(request)
            dao.updateStatus(request.requestId, MemberJoinRequestStatus.APPROVED, Clock.System.now(), null)

            assertFalse(dao.existsPendingByEmailAndOrganization(email, orgId.toId()))
        }

    @Test
    fun `GIVEN a REJECTED request WHEN existsPendingByEmailAndOrganization THEN returns false`() =
        runTest {
            val orgId = "org-${UUID.randomUUID()}"
            val email = "${UUID.randomUUID()}@example.com"
            val request = buildRequest(orgId = orgId, email = email)
            dao.create(request)
            dao.updateStatus(request.requestId, MemberJoinRequestStatus.REJECTED, Clock.System.now(), null)

            assertFalse(dao.existsPendingByEmailAndOrganization(email, orgId.toId()))
        }

    @Test
    fun `GIVEN requests in same org WHEN listByOrganization THEN returns all of them`() =
        runTest {
            val orgId = "org-${UUID.randomUUID()}"
            val r1 = buildRequest(orgId = orgId)
            val r2 = buildRequest(orgId = orgId)
            dao.create(r1)
            dao.create(r2)

            val result = dao.listByOrganization(orgId.toId())

            assertEquals(2, result.size)
            assertTrue(result.any { it.requestId == r1.requestId })
            assertTrue(result.any { it.requestId == r2.requestId })
        }

    @Test
    fun `GIVEN no requests for org WHEN listByOrganization THEN returns empty list`() =
        runTest {
            val result = dao.listByOrganization("org-empty".toId<Organization>())

            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN pending and approved requests WHEN listByOrganizationAndStatus PENDING THEN returns only pending`() =
        runTest {
            val orgId = "org-${UUID.randomUUID()}"
            val pending = buildRequest(orgId = orgId)
            val approved = buildRequest(orgId = orgId)
            dao.create(pending)
            dao.create(approved)
            dao.updateStatus(approved.requestId, MemberJoinRequestStatus.APPROVED, Clock.System.now(), null)

            val result = dao.listByOrganizationAndStatus(orgId.toId(), MemberJoinRequestStatus.PENDING)

            assertEquals(1, result.size)
            assertEquals(pending.requestId, result.first().requestId)
        }

    @Test
    fun `GIVEN no matching requests WHEN listByOrganizationAndStatus THEN returns empty list`() =
        runTest {
            val result =
                dao.listByOrganizationAndStatus("org-none".toId(), MemberJoinRequestStatus.APPROVED)

            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN request WHEN findById with existing id THEN returns request`() =
        runTest {
            val request = buildRequest()
            dao.create(request)

            val found = dao.findById(request.requestId)

            assertNotNull(found)
            assertEquals(request.requestId, found.requestId)
            assertEquals(request.email, found.email)
            assertEquals(request.firstName, found.firstName)
            assertEquals(request.lastName, found.lastName)
            assertEquals(MemberJoinRequestStatus.PENDING, found.status)
        }

    @Test
    fun `GIVEN no matching request WHEN findById THEN returns null`() =
        runTest {
            val found = dao.findById("non-existent-id".toId())

            assertNull(found)
        }

    @Test
    fun `GIVEN pending request WHEN updateStatus to APPROVED THEN status is updated`() =
        runTest {
            val request = buildRequest()
            dao.create(request)
            val reviewedAt = Clock.System.now()

            dao.updateStatus(request.requestId, MemberJoinRequestStatus.APPROVED, reviewedAt, null)

            val updated = dao.findById(request.requestId)
            assertNotNull(updated)
            assertEquals(MemberJoinRequestStatus.APPROVED, updated.status)
            assertNotNull(updated.reviewedAt)
            assertNull(updated.reviewComment)
        }

    @Test
    fun `GIVEN pending request WHEN updateStatus to REJECTED with comment THEN comment is stored`() =
        runTest {
            val request = buildRequest()
            dao.create(request)
            val reviewedAt = Clock.System.now()

            dao.updateStatus(request.requestId, MemberJoinRequestStatus.REJECTED, reviewedAt, "Not enough spots")

            val updated = dao.findById(request.requestId)
            assertNotNull(updated)
            assertEquals(MemberJoinRequestStatus.REJECTED, updated.status)
            assertEquals("Not enough spots", updated.reviewComment)
        }
}

@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class OrganizationRequestDAOContractTest {
    protected abstract val dao: OrganizationRequestDAO

    protected abstract fun clearAll()

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    protected fun buildRequest(
        orgName: String = "AMAP-${UUID.randomUUID()}",
        email: String = "${UUID.randomUUID()}@example.com",
        organizationType: OrganizationType = OrganizationType.AMAP,
        submitterComment: String? = null,
    ): OrganizationRequest =
        OrganizationRequest(
            requestId = UUID.randomUUID().toString().toId(),
            organizationName = orgName,
            organizationType = organizationType,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = email,
            status = OrganizationRequestStatus.PENDING_VALIDATION,
            submittedAt = Clock.System.now(),
            submitterComment = submitterComment,
        )

    @Test
    fun `GIVEN a request of type PRODUCER WHEN create THEN findById returns it with type PRODUCER`() =
        runTest {
            val request = buildRequest(organizationType = OrganizationType.PRODUCER)

            dao.create(request)

            val found = dao.findById(request.requestId)
            assertNotNull(found)
            assertEquals(OrganizationType.PRODUCER, found.organizationType)
        }

    @Test
    fun `GIVEN a request WHEN create THEN existsByOrganizationName returns non-null status`() =
        runTest {
            val request = buildRequest(orgName = "AMAP des Collines")

            dao.create(request)

            assertNotNull(dao.existsByOrganizationName("AMAP des Collines"))
        }

    @Test
    fun `GIVEN no request WHEN existsByOrganizationName THEN returns null`() =
        runTest {
            assertNull(dao.existsByOrganizationName("NonExistent"))
        }

    @Test
    fun `GIVEN a request WHEN create THEN existsByAdminEmail returns non-null status`() =
        runTest {
            val request = buildRequest(email = "unique@example.com")

            dao.create(request)

            assertNotNull(dao.existsByAdminEmail("unique@example.com"))
        }

    @Test
    fun `GIVEN no request WHEN existsByAdminEmail THEN returns null`() =
        runTest {
            assertNull(dao.existsByAdminEmail("nobody@example.com"))
        }

    @Test
    fun `GIVEN requests with various statuses WHEN listAll THEN returns all of them`() =
        runTest {
            val pending = buildRequest()
            val approved = buildRequest()
            dao.create(pending)
            dao.create(approved)
            dao.updateStatus(approved.requestId, OrganizationRequestStatus.APPROVED, Clock.System.now(), null)

            val result = dao.listAll()

            assertEquals(2, result.size)
            assertTrue(result.any { it.requestId == pending.requestId })
            assertTrue(result.any { it.requestId == approved.requestId })
        }

    @Test
    fun `GIVEN no requests WHEN listAll THEN returns empty list`() =
        runTest {
            val result = dao.listAll()

            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN pending request WHEN listByStatus PENDING_VALIDATION THEN returns it`() =
        runTest {
            val request = buildRequest()
            dao.create(request)

            val result = dao.listByStatus(OrganizationRequestStatus.PENDING_VALIDATION)

            assertEquals(1, result.size)
            assertEquals(request.requestId, result.first().requestId)
            assertEquals(OrganizationRequestStatus.PENDING_VALIDATION, result.first().status)
        }

    @Test
    fun `GIVEN no pending requests WHEN listByStatus PENDING_VALIDATION THEN returns empty list`() =
        runTest {
            val result = dao.listByStatus(OrganizationRequestStatus.PENDING_VALIDATION)

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
            assertEquals(request.organizationName, found.organizationName)
            assertEquals(request.adminEmail, found.adminEmail)
            assertEquals(OrganizationRequestStatus.PENDING_VALIDATION, found.status)
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

            dao.updateStatus(request.requestId, OrganizationRequestStatus.APPROVED, reviewedAt, null)

            val updated = dao.findById(request.requestId)
            assertNotNull(updated)
            assertEquals(OrganizationRequestStatus.APPROVED, updated.status)
            assertNotNull(updated.reviewedAt)
            assertNull(updated.reviewComment)
        }

    @Test
    fun `GIVEN pending request WHEN updateStatus to REJECTED with comment THEN comment is stored`() =
        runTest {
            val request = buildRequest()
            dao.create(request)
            val reviewedAt = Clock.System.now()

            dao.updateStatus(request.requestId, OrganizationRequestStatus.REJECTED, reviewedAt, "Missing information")

            val updated = dao.findById(request.requestId)
            assertNotNull(updated)
            assertEquals(OrganizationRequestStatus.REJECTED, updated.status)
            assertEquals("Missing information", updated.reviewComment)
        }

    @Test
    fun `GIVEN request with submitter comment WHEN create THEN findById returns the comment`() =
        runTest {
            val request = buildRequest(submitterComment = "Je suis producteur depuis 10 ans")
            dao.create(request)
            val found = dao.findById(request.requestId)
            assertNotNull(found)
            assertEquals("Je suis producteur depuis 10 ans", found.submitterComment)
        }

    @Test
    fun `GIVEN a rejected request WHEN existsByOrganizationName with REJECTED excluded THEN returns null`() =
        runTest {
            val request = buildRequest(orgName = "AMAP Test")
            dao.create(request)
            dao.updateStatus(request.requestId, OrganizationRequestStatus.REJECTED, Clock.System.now(), "Rejected")
            assertNull(dao.existsByOrganizationName("AMAP Test", excludedStatuses = setOf(OrganizationRequestStatus.REJECTED)))
        }

    @Test
    fun `GIVEN a pending request WHEN existsByOrganizationName with REJECTED excluded THEN returns PENDING_VALIDATION`() =
        runTest {
            val request = buildRequest(orgName = "AMAP Pending")
            dao.create(request)
            assertEquals(
                OrganizationRequestStatus.PENDING_VALIDATION,
                dao.existsByOrganizationName("AMAP Pending", excludedStatuses = setOf(OrganizationRequestStatus.REJECTED)),
            )
        }

    @Test
    fun `GIVEN a rejected request WHEN existsByAdminEmail with REJECTED excluded THEN returns null`() =
        runTest {
            val request = buildRequest(email = "rejected@example.com")
            dao.create(request)
            dao.updateStatus(request.requestId, OrganizationRequestStatus.REJECTED, Clock.System.now(), null)
            assertNull(dao.existsByAdminEmail("rejected@example.com", excludedStatuses = setOf(OrganizationRequestStatus.REJECTED)))
        }

    @Test
    fun `GIVEN a pending request WHEN existsByAdminEmail with REJECTED excluded THEN returns PENDING_VALIDATION`() =
        runTest {
            val request = buildRequest(email = "pending@example.com")
            dao.create(request)
            assertEquals(
                OrganizationRequestStatus.PENDING_VALIDATION,
                dao.existsByAdminEmail("pending@example.com", excludedStatuses = setOf(OrganizationRequestStatus.REJECTED)),
            )
        }

    @Test
    fun `GIVEN a pending request WHEN existsByAdminEmail THEN returns PENDING_VALIDATION status`() =
        runTest {
            val request = buildRequest(email = "status@example.com")
            dao.create(request)
            assertEquals(OrganizationRequestStatus.PENDING_VALIDATION, dao.existsByAdminEmail("status@example.com"))
        }
}

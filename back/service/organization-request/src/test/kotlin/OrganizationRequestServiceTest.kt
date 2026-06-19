@file:OptIn(ExperimentalTime::class)

package organizationrequest

import authentication.AuthenticatedInfo
import authentication.Role
import email.ActivationEmailPort
import email.RejectionEmailPort
import id.generateId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.OrganizationRequestPayload
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.ExperimentalTime

@OptIn(ExperimentalTime::class)
internal class OrganizationRequestServiceTest {
    private val organizationRequestSyncDAO = mockk<OrganizationRequestSyncDAO>(relaxed = true)
    private val organizationRequestDAO = mockk<OrganizationRequestDAO>(relaxed = true)
    private val organizationDAO = mockk<OrganizationDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val activationEmailPort = mockk<ActivationEmailPort>(relaxed = true)
    private val rejectionEmailPort = mockk<RejectionEmailPort>(relaxed = true)
    private val service =
        OrganizationRequestService(
            organizationRequestSyncDAO,
            organizationRequestDAO,
            organizationDAO,
            activationTokenDAO,
            activationEmailPort,
            rejectionEmailPort,
        )

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "owner-1",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            roles = listOf(Role.OWNER),
        )

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            roles = listOf(Role.ADMIN),
        )

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "producer-1",
            firstName = "Producer",
            lastName = "User",
            email = "producer@example.com",
            roles = listOf(Role.PRODUCER),
        )

    private fun buildPendingRequest(): OrganizationRequest =
        OrganizationRequest(
            requestId = generateId(),
            organizationName = "AMAP des Collines",
            organizationType = OrganizationType.AMAP,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean@example.com",
            status = OrganizationRequestStatus.PENDING_VALIDATION,
            submittedAt = Clock.System.now(),
        )

    private fun buildUpsertMutation(request: OrganizationRequest) =
        persistence.changes.ClientMutation(
            clientOpId = "op-1",
            op = Upsert(OrganizationRequestPayload(request)),
        )

    @Test
    fun `GIVEN non-owner caller WHEN applyUpsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val request = buildPendingRequest()
            val mutation = buildUpsertMutation(request)

            val outcome = service.applyUpsert(producerAuth, mutation, OrganizationRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN request not found WHEN applyUpsert THEN REJECTED NOT_FOUND`() =
        runTest {
            val request = buildPendingRequest()
            val mutation = buildUpsertMutation(request)
            coEvery { organizationRequestDAO.findById(request.requestId) } returns null

            val outcome = service.applyUpsert(ownerAuth, mutation, OrganizationRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN status already APPROVED and no resend_requested_at WHEN applyUpsert THEN REJECTED CONFLICT`() =
        runTest {
            val request = buildPendingRequest().copy(status = OrganizationRequestStatus.APPROVED)
            val mutation = buildUpsertMutation(request)
            coEvery { organizationRequestDAO.findById(request.requestId) } returns request

            val outcome = service.applyUpsert(ownerAuth, mutation, OrganizationRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    @Test
    fun `GIVEN valid PENDING_VALIDATION to APPROVED WHEN applyUpsert THEN APPLIED and activation triggered`() =
        runTest {
            val pending = buildPendingRequest()
            val approvePayload =
                OrganizationRequestPayload(
                    pending.copy(status = OrganizationRequestStatus.APPROVED),
                )
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-approve",
                    op = Upsert(approvePayload),
                )
            coEvery { organizationRequestDAO.findById(pending.requestId) } returns pending

            val outcome = service.applyUpsert(ownerAuth, mutation, approvePayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(pending.requestId.id, outcome.serverEntityId)
            coVerify { organizationDAO.create(any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { activationEmailPort.scheduleActivationEmail(any(), any()) }
            val persistedRequestSlot = slot<OrganizationRequest>()
            coVerify { organizationRequestSyncDAO.put(capture(persistedRequestSlot), any()) }
            assertNotNull(persistedRequestSlot.captured.organizationId)
        }

    @Test
    fun `GIVEN valid PENDING_VALIDATION to REJECTED WHEN applyUpsert THEN APPLIED and rejection email triggered`() =
        runTest {
            val pending = buildPendingRequest()
            val rejectPayload =
                OrganizationRequestPayload(
                    pending.copy(status = OrganizationRequestStatus.REJECTED, reviewComment = "Insufficient info"),
                )
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-reject",
                    op = Upsert(rejectPayload),
                )
            coEvery { organizationRequestDAO.findById(pending.requestId) } returns pending

            val outcome = service.applyUpsert(ownerAuth, mutation, rejectPayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(pending.requestId.id, outcome.serverEntityId)
            coVerify { rejectionEmailPort.sendRejectionEmail(any(), any()) }
            coVerify { organizationRequestSyncDAO.put(any(), any()) }
            coVerify(exactly = 0) { organizationDAO.create(any()) }
        }

    @Test
    fun `WHEN applyDelete THEN REJECTED FORBIDDEN`() =
        runTest {
            val op = Delete(EntityType.OrganizationRequest, "some-id")
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-del",
                    op = op,
                )

            val outcome = service.applyDelete(ownerAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN OWNER auth WHEN snapshot THEN returns all requests`() =
        runTest {
            val request = buildPendingRequest()
            coEvery { organizationRequestSyncDAO.listAll() } returns listOf(request)

            val result = service.snapshot(ownerAuth)

            assertEquals(1, result.size)
            assertEquals(OrganizationRequestPayload(request), result.first())
        }

    @Test
    fun `GIVEN ADMIN auth WHEN snapshot THEN returns empty list`() =
        runTest {
            val request = buildPendingRequest()
            coEvery { organizationRequestSyncDAO.listAll() } returns listOf(request)

            val result = service.snapshot(adminAuth)

            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN non-admin auth WHEN snapshot THEN returns empty list`() =
        runTest {
            val result = service.snapshot(producerAuth)

            assertTrue(result.isEmpty())
            coVerify(exactly = 0) { organizationRequestSyncDAO.listAll() }
        }

    @Test
    fun `GIVEN approved request WHEN resend with newer timestamp THEN email resent and outcome APPLIED`() =
        runTest {
            val orgId = generateId<persistence.model.Organization>()
            val approved =
                buildPendingRequest().copy(
                    status = OrganizationRequestStatus.APPROVED,
                    organizationId = orgId,
                )
            val resendAt = Clock.System.now()
            val resendPayload =
                OrganizationRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-resend",
                    op = Upsert(resendPayload),
                )
            coEvery { organizationRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(approved.requestId.id, outcome.serverEntityId)
            coVerify { activationTokenDAO.invalidateByOrganizationRequestId(approved.requestId, any()) }
            val tokenSlot = slot<ActivationToken>()
            coVerify { activationTokenDAO.create(capture(tokenSlot)) }
            assertEquals(orgId, tokenSlot.captured.organizationId)
            coVerify { activationEmailPort.scheduleActivationEmail(any(), any()) }
            coVerify { organizationRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN approved request WHEN resend with older timestamp THEN CONFLICT`() =
        runTest {
            val orgId = generateId<persistence.model.Organization>()
            val existingResendAt = Clock.System.now()
            val approved =
                buildPendingRequest().copy(
                    status = OrganizationRequestStatus.APPROVED,
                    organizationId = orgId,
                    resendRequestedAt = existingResendAt,
                )
            val olderResendAt = existingResendAt - 60.seconds
            val resendPayload =
                OrganizationRequestPayload(approved.copy(resendRequestedAt = olderResendAt))
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-resend-old",
                    op = Upsert(resendPayload),
                )
            coEvery { organizationRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
        }

    @Test
    fun `GIVEN approved request without organizationId WHEN resend THEN CONFLICT`() =
        runTest {
            val approved =
                buildPendingRequest().copy(
                    status = OrganizationRequestStatus.APPROVED,
                    organizationId = null,
                )
            val resendAt = Clock.System.now()
            val resendPayload =
                OrganizationRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-resend-no-org",
                    op = Upsert(resendPayload),
                )
            coEvery { organizationRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
        }

    @Test
    fun `GIVEN approved request WHEN resend with same timestamp THEN idempotent APPLIED`() =
        runTest {
            val orgId = generateId<persistence.model.Organization>()
            val resendAt = Clock.System.now()
            val approved =
                buildPendingRequest().copy(
                    status = OrganizationRequestStatus.APPROVED,
                    organizationId = orgId,
                    resendRequestedAt = resendAt,
                )
            val resendPayload =
                OrganizationRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation =
                persistence.changes.ClientMutation(
                    clientOpId = "op-resend-same",
                    op = Upsert(resendPayload),
                )
            coEvery { organizationRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
            coVerify(exactly = 0) { activationEmailPort.scheduleActivationEmail(any(), any()) }
        }
}

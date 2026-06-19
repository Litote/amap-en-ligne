@file:OptIn(ExperimentalTime::class)

package producerrequest

import authentication.AuthenticatedInfo
import authentication.Role
import email.ProducerActivationEmailPort
import email.ProducerRequestRejectionEmailPort
import id.generateId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.ProducerRequestPayload
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.ExperimentalTime

internal class ProducerRequestServiceTest {
    private val producerRequestSyncDAO = mockk<ProducerRequestSyncDAO>(relaxed = true)
    private val producerRequestDAO = mockk<ProducerRequestDAO>(relaxed = true)
    private val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val producerActivationEmailPort = mockk<ProducerActivationEmailPort>(relaxed = true)
    private val producerRequestRejectionEmailPort = mockk<ProducerRequestRejectionEmailPort>(relaxed = true)
    private val service =
        ProducerRequestService(
            producerRequestSyncDAO,
            producerRequestDAO,
            producerAccountSyncDAO,
            activationTokenDAO,
            producerActivationEmailPort,
            producerRequestRejectionEmailPort,
        )

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "owner-1",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            roles = listOf(Role.OWNER),
        )

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "producer-1",
            firstName = "Producer",
            lastName = "User",
            email = "producer@example.com",
            roles = listOf(Role.PRODUCER),
        )

    private fun buildPendingRequest(): ProducerRequest =
        ProducerRequest(
            requestId = generateId(),
            producerName = "Ferme des Collines",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean@example.com",
            status = ProducerRequestStatus.PENDING_VALIDATION,
            submittedAt = Clock.System.now(),
        )

    @Test
    fun `GIVEN non-owner caller WHEN applyUpsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val request = buildPendingRequest()
            val mutation = persistence.changes.ClientMutation("op-1", Upsert(ProducerRequestPayload(request)))

            val outcome = service.applyUpsert(producerAuth, mutation, ProducerRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { producerRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN request not found WHEN applyUpsert THEN REJECTED NOT_FOUND`() =
        runTest {
            val request = buildPendingRequest()
            val mutation = persistence.changes.ClientMutation("op-1", Upsert(ProducerRequestPayload(request)))
            coEvery { producerRequestDAO.findById(request.requestId) } returns null

            val outcome = service.applyUpsert(ownerAuth, mutation, ProducerRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN valid PENDING_VALIDATION to APPROVED WHEN applyUpsert THEN APPLIED and activation triggered`() =
        runTest {
            val pending = buildPendingRequest()
            val payload = ProducerRequestPayload(pending.copy(status = ProducerRequestStatus.APPROVED))
            val mutation = persistence.changes.ClientMutation("op-approve", Upsert(payload))
            coEvery { producerRequestDAO.findById(pending.requestId) } returns pending

            val outcome = service.applyUpsert(ownerAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(pending.requestId.id, outcome.serverEntityId)
            coVerify { producerAccountSyncDAO.createStandalone(any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { producerActivationEmailPort.sendProducerActivationEmail(any(), any()) }
            val persistedRequestSlot = slot<ProducerRequest>()
            coVerify { producerRequestSyncDAO.put(capture(persistedRequestSlot), any()) }
            assertNotNull(persistedRequestSlot.captured.producerAccountId)
        }

    @Test
    fun `GIVEN valid PENDING_VALIDATION to REJECTED WHEN applyUpsert THEN APPLIED and rejection email triggered`() =
        runTest {
            val pending = buildPendingRequest()
            val payload =
                ProducerRequestPayload(
                    pending.copy(status = ProducerRequestStatus.REJECTED, reviewComment = "Insufficient info"),
                )
            val mutation = persistence.changes.ClientMutation("op-reject", Upsert(payload))
            coEvery { producerRequestDAO.findById(pending.requestId) } returns pending

            val outcome = service.applyUpsert(ownerAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { producerRequestRejectionEmailPort.sendRejectionEmail(any(), "Insufficient info") }
            coVerify(exactly = 0) { producerAccountSyncDAO.createStandalone(any()) }
        }

    @Test
    fun `WHEN applyDelete THEN REJECTED FORBIDDEN`() =
        runTest {
            val op = Delete(EntityType.ProducerRequest, "some-id")
            val mutation = persistence.changes.ClientMutation("op-del", op)

            val outcome = service.applyDelete(ownerAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN OWNER auth WHEN snapshot THEN returns all requests`() =
        runTest {
            val request = buildPendingRequest()
            coEvery { producerRequestSyncDAO.listAll() } returns listOf(request)

            val result = service.snapshot(ownerAuth)

            assertEquals(1, result.size)
            assertEquals(ProducerRequestPayload(request), result.first())
        }

    @Test
    fun `GIVEN non-owner auth WHEN snapshot THEN returns empty list`() =
        runTest {
            val result = service.snapshot(producerAuth)

            assertTrue(result.isEmpty())
            coVerify(exactly = 0) { producerRequestSyncDAO.listAll() }
        }

    @Test
    fun `GIVEN approved request WHEN resend with newer timestamp THEN email resent and outcome APPLIED`() =
        runTest {
            val producerAccountId = generateId<persistence.model.ProducerAccount>()
            val approved =
                buildPendingRequest().copy(
                    status = ProducerRequestStatus.APPROVED,
                    producerAccountId = producerAccountId,
                )
            val resendAt = Clock.System.now()
            val resendPayload = ProducerRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation = persistence.changes.ClientMutation("op-resend", Upsert(resendPayload))
            coEvery { producerRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(approved.requestId.id, outcome.serverEntityId)
            coVerify { activationTokenDAO.invalidateByProducerRequestId(approved.requestId, any()) }
            val tokenSlot = slot<ActivationToken>()
            coVerify { activationTokenDAO.create(capture(tokenSlot)) }
            assertEquals(producerAccountId, tokenSlot.captured.producerAccountId)
            coVerify { producerActivationEmailPort.sendProducerActivationEmail(any(), any()) }
            coVerify { producerRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN approved request WHEN resend with older timestamp THEN CONFLICT`() =
        runTest {
            val producerAccountId = generateId<persistence.model.ProducerAccount>()
            val existingResendAt = Clock.System.now()
            val approved =
                buildPendingRequest().copy(
                    status = ProducerRequestStatus.APPROVED,
                    producerAccountId = producerAccountId,
                    resendRequestedAt = existingResendAt,
                )
            val olderResendAt = existingResendAt - 60.seconds
            val resendPayload = ProducerRequestPayload(approved.copy(resendRequestedAt = olderResendAt))
            val mutation = persistence.changes.ClientMutation("op-resend-old", Upsert(resendPayload))
            coEvery { producerRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
        }

    @Test
    fun `GIVEN approved request without producerAccountId WHEN resend THEN CONFLICT`() =
        runTest {
            val approved =
                buildPendingRequest().copy(
                    status = ProducerRequestStatus.APPROVED,
                    producerAccountId = null,
                )
            val resendAt = Clock.System.now()
            val resendPayload = ProducerRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation = persistence.changes.ClientMutation("op-resend-no-acct", Upsert(resendPayload))
            coEvery { producerRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
        }

    @Test
    fun `GIVEN approved request and no resend_requested_at WHEN applyUpsert THEN REJECTED CONFLICT`() =
        runTest {
            val producerAccountId = generateId<persistence.model.ProducerAccount>()
            val approved =
                buildPendingRequest().copy(
                    status = ProducerRequestStatus.APPROVED,
                    producerAccountId = producerAccountId,
                )
            val payload = ProducerRequestPayload(approved)
            val mutation = persistence.changes.ClientMutation("op-no-resend", Upsert(payload))
            coEvery { producerRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    @Test
    fun `GIVEN approved request WHEN resend with same timestamp THEN idempotent APPLIED`() =
        runTest {
            val producerAccountId = generateId<persistence.model.ProducerAccount>()
            val resendAt = Clock.System.now()
            val approved =
                buildPendingRequest().copy(
                    status = ProducerRequestStatus.APPROVED,
                    producerAccountId = producerAccountId,
                    resendRequestedAt = resendAt,
                )
            val resendPayload = ProducerRequestPayload(approved.copy(resendRequestedAt = resendAt))
            val mutation = persistence.changes.ClientMutation("op-resend-same", Upsert(resendPayload))
            coEvery { producerRequestDAO.findById(approved.requestId) } returns approved

            val outcome = service.applyUpsert(ownerAuth, mutation, resendPayload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { activationTokenDAO.create(any()) }
            coVerify(exactly = 0) { producerActivationEmailPort.sendProducerActivationEmail(any(), any()) }
        }
}

@file:OptIn(ExperimentalTime::class)

package exchange

import authentication.AuthenticatedInfo
import authentication.Role
import email.BasketExchangeAcceptedEmailPort
import email.BasketExchangeRejectedEmailPort
import email.BasketExchangeRequestReceivedEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import notificationpublisher.NotificationDispatcher
import notificationpublisher.NotificationPublisher
import persistence.changes.BasketExchangePayload
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Organization
import java.util.UUID
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

private const val ORG_ID = "org-1"
private const val OFFERER_ID = "member-offerer"
private const val REQUESTER_ID = "member-requester"
private const val DELIVERY_ID = "delivery-1"
private const val PROPOSED_DELIVERY_ID = "delivery-2"
private const val CONTRACT_ID = "contract-1"
private const val EXCHANGE_ID = "exchange-1"
private const val TMP_EXCHANGE_ID = "tmp_exchange-1"
private const val TMP_REQUEST_ID = "tmp_request-1"
private const val REQUEST_ID = "request-1"

internal class BasketExchangeServiceTest {
    private val basketExchangeSyncDAO = mockk<BasketExchangeSyncDAO>()
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>()
    private val memberSyncDAO = mockk<MemberSyncDAO>()
    private val contractSyncDAO = mockk<persistence.dao.ContractSyncDAO>(relaxed = true)
    private val requestReceivedEmailPort = mockk<BasketExchangeRequestReceivedEmailPort>(relaxed = true)
    private val acceptedEmailPort = mockk<BasketExchangeAcceptedEmailPort>(relaxed = true)
    private val rejectedEmailPort = mockk<BasketExchangeRejectedEmailPort>(relaxed = true)
    private val notificationSyncDAO = mockk<persistence.dao.NotificationSyncDAO>(relaxed = true)
    private val deviceTokenSyncDAO = mockk<persistence.dao.DeviceTokenSyncDAO>(relaxed = true)
    private val notificationPublisher =
        NotificationPublisher(notificationSyncDAO, deviceTokenSyncDAO, NotificationDispatcher(emptyList()))

    private val service =
        BasketExchangeService(
            basketExchangeSyncDAO,
            organizationSyncDAO,
            memberSyncDAO,
            contractSyncDAO,
            requestReceivedEmailPort,
            acceptedEmailPort,
            rejectedEmailPort,
            notificationPublisher,
        )

    private val offererAuth =
        AuthenticatedInfo(
            memberId = OFFERER_ID,
            firstName = "Offerer",
            lastName = "User",
            email = "offerer@example.com",
            organizationId = ORG_ID,
            roles = listOf(Role.VOLUNTEER),
        )

    private val requesterAuth =
        AuthenticatedInfo(
            memberId = REQUESTER_ID,
            firstName = "Requester",
            lastName = "User",
            email = "requester@example.com",
            organizationId = ORG_ID,
            roles = listOf(Role.VOLUNTEER),
        )

    private val noOrgAuth =
        AuthenticatedInfo(
            memberId = "no-org",
            firstName = "No",
            lastName = "Org",
            email = "noorg@example.com",
            organizationId = null,
            roles = listOf(Role.VOLUNTEER),
        )

    private fun buildActiveDelivery(deliveryId: String = DELIVERY_ID): Delivery =
        Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = ORG_ID.toId(),
            scheduledDate = kotlinx.datetime.LocalDateTime(2030, 1, 15, 18, 0),
            status = DeliveryStatus.PLANNED,
            minVolunteersRequired = 2,
            contracts =
                listOf(
                    DeliveryContract(
                        contractId = CONTRACT_ID.toId(),
                        coordinators = listOf(OFFERER_ID.toId()),
                        basketQuantity = 10,
                        deliveryDescription = "Légumes bio",
                        status = persistence.model.DeliveryContractStatus.PENDING,
                    ),
                ),
        )

    private fun buildOrganization(
        deliveries: List<Delivery> = listOf(buildActiveDelivery(), buildActiveDelivery(PROPOSED_DELIVERY_ID)),
    ): Organization {
        val now = Clock.System.now()
        return Organization(
            organizationId = ORG_ID.toId(),
            name = "Test AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = kotlinx.datetime.TimeZone.UTC,
            defaultLanguage = "fr",
            createdInstant = now,
            lastUpdatedInstant = now,
            deliveries = deliveries,
        )
    }

    private fun buildOpenExchange(
        exchangeId: String = EXCHANGE_ID,
        requests: List<BasketExchangeRequest> = emptyList(),
    ): BasketExchange {
        val now = Clock.System.now()
        return BasketExchange(
            basketExchangeId = exchangeId.toId(),
            organizationId = ORG_ID.toId(),
            deliveryId = DELIVERY_ID.toId(),
            contractId = CONTRACT_ID.toId(),
            offeringMemberId = OFFERER_ID.toId(),
            motive = "Vacation",
            status = BasketExchangeStatus.OPEN,
            createdAt = now,
            requests = requests,
        )
    }

    private fun buildPendingRequest(
        requestId: String = REQUEST_ID,
        requesterId: String = REQUESTER_ID,
        proposedDeliveryId: String? = PROPOSED_DELIVERY_ID,
    ): BasketExchangeRequest {
        val now = Clock.System.now()
        return BasketExchangeRequest(
            requestId = requestId.toId(),
            requesterMemberId = requesterId.toId(),
            createdAt = now,
            status = BasketExchangeRequestStatus.PENDING,
            proposedDeliveryId = proposedDeliveryId?.toId(),
        )
    }

    private fun buildMutation(exchange: BasketExchange): ClientMutation =
        ClientMutation(
            clientOpId = "op-${UUID.randomUUID()}",
            op = Upsert(BasketExchangePayload(exchange)),
        )

    // region create

    @Test
    fun `GIVEN caller without organization WHEN create THEN REJECTED FORBIDDEN`() =
        runTest {
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)

            val outcome = service.applyUpsert(noOrgAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN caller is not offerer WHEN create THEN REJECTED FORBIDDEN`() =
        runTest {
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID).copy(offeringMemberId = "other-member".toId())
            val mutation = buildMutation(exchange)

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN duplicate OPEN exchange for same offerer and delivery WHEN create THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(buildOpenExchange())

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN offerer already received this delivery in an accepted swap WHEN create THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            // Someone else offered DELIVERY_ID and accepted the offerer's counter — the offerer now
            // holds (received) DELIVERY_ID, so they cannot re-offer it.
            val received =
                buildOpenExchange(exchangeId = "exchange-2").copy(
                    deliveryId = DELIVERY_ID.toId(),
                    offeringMemberId = "someone-else".toId(),
                    status = BasketExchangeStatus.ACCEPTED,
                    acceptedRequestId = REQUEST_ID.toId(),
                    requests =
                        listOf(
                            buildPendingRequest(
                                requestId = REQUEST_ID,
                                requesterId = OFFERER_ID,
                                proposedDeliveryId = "delivery-9",
                            ).copy(status = BasketExchangeRequestStatus.ACCEPTED),
                        ),
                )
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(received)

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN valid create WHEN applyUpsert THEN APPLIED with real id`() =
        runTest {
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotNull(outcome.serverEntityId)
            assert(!outcome.serverEntityId!!.startsWith(ClientMutation.TMP_ID_PREFIX))
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN delivery not active WHEN create THEN REJECTED FORBIDDEN`() =
        runTest {
            val completedDelivery = buildActiveDelivery().copy(status = DeliveryStatus.COMPLETED)
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization(listOf(completedDelivery))
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    // endregion

    // region add request

    @Test
    fun `GIVEN open exchange WHEN add request THEN APPLIED with exchange id`() =
        runTest {
            val existing = buildOpenExchange()
            val newRequest = buildPendingRequest(requestId = TMP_REQUEST_ID)
            val incoming = existing.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(EXCHANGE_ID, outcome.serverEntityId)
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN request without counter-delivery WHEN add request THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existing = buildOpenExchange()
            val newRequest = buildPendingRequest(requestId = TMP_REQUEST_ID, proposedDeliveryId = null)
            val incoming = existing.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
        }

    @Test
    fun `GIVEN requester already committed the counter-delivery WHEN add request THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            val existing = buildOpenExchange()
            // The requester already offers PROPOSED_DELIVERY_ID in another OPEN exchange
            val committed =
                buildOpenExchange(exchangeId = "exchange-2")
                    .copy(deliveryId = PROPOSED_DELIVERY_ID.toId(), offeringMemberId = REQUESTER_ID.toId())
            val newRequest = buildPendingRequest(requestId = TMP_REQUEST_ID)
            val incoming = existing.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(existing, committed)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN requester already received the counter-delivery in an accepted swap WHEN add request THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            val existing = buildOpenExchange()
            // The requester offered delivery-9 and accepted a counter of PROPOSED_DELIVERY_ID — they
            // now hold (received) PROPOSED_DELIVERY_ID, so they cannot propose it again.
            val received =
                buildOpenExchange(exchangeId = "exchange-2").copy(
                    deliveryId = "delivery-9".toId(),
                    offeringMemberId = REQUESTER_ID.toId(),
                    status = BasketExchangeStatus.ACCEPTED,
                    acceptedRequestId = REQUEST_ID.toId(),
                    requests =
                        listOf(
                            buildPendingRequest(
                                requestId = REQUEST_ID,
                                requesterId = "another-member",
                                proposedDeliveryId = PROPOSED_DELIVERY_ID,
                            ).copy(status = BasketExchangeRequestStatus.ACCEPTED),
                        ),
                )
            val newRequest = buildPendingRequest(requestId = TMP_REQUEST_ID)
            val incoming = existing.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(existing, received)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN self-request WHEN add request THEN REJECTED FORBIDDEN`() =
        runTest {
            val existing = buildOpenExchange()
            val selfRequest =
                BasketExchangeRequest(
                    requestId = TMP_REQUEST_ID.toId(),
                    requesterMemberId = OFFERER_ID.toId(),
                    createdAt = Clock.System.now(),
                    status = BasketExchangeRequestStatus.PENDING,
                )
            val incoming = existing.copy(requests = listOf(selfRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN duplicate pending request for same member WHEN add request THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            val pendingRequest = buildPendingRequest()
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val newRequest =
                BasketExchangeRequest(
                    requestId = TMP_REQUEST_ID.toId(),
                    requesterMemberId = REQUESTER_ID.toId(),
                    createdAt = Clock.System.now(),
                    status = BasketExchangeRequestStatus.PENDING,
                )
            val incoming = existing.copy(requests = listOf(pendingRequest, newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN non-open exchange WHEN add request THEN REJECTED CONFLICT`() =
        runTest {
            val cancelledExchange = buildOpenExchange().copy(status = BasketExchangeStatus.CANCELLED)
            val newRequest =
                BasketExchangeRequest(
                    requestId = TMP_REQUEST_ID.toId(),
                    requesterMemberId = REQUESTER_ID.toId(),
                    createdAt = Clock.System.now(),
                    status = BasketExchangeRequestStatus.PENDING,
                )
            val incoming = cancelledExchange.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns cancelledExchange

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    // endregion

    // region withdraw request

    @Test
    fun `GIVEN pending request WHEN requester withdraws THEN APPLIED`() =
        runTest {
            val pendingRequest = buildPendingRequest()
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val withdrawn = pendingRequest.copy(status = BasketExchangeRequestStatus.WITHDRAWN)
            val incoming = existing.copy(requests = listOf(withdrawn))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN pending request WHEN non-requester tries to withdraw THEN REJECTED FORBIDDEN`() =
        runTest {
            val pendingRequest = buildPendingRequest(requesterId = "other-requester")
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val withdrawn = pendingRequest.copy(status = BasketExchangeRequestStatus.WITHDRAWN)
            val incoming = existing.copy(requests = listOf(withdrawn))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    // endregion

    // region refuse

    @Test
    fun `GIVEN pending request WHEN offerer refuses THEN APPLIED and offer stays OPEN`() =
        runTest {
            val pendingRequest = buildPendingRequest()
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val refused = pendingRequest.copy(status = BasketExchangeRequestStatus.REJECTED)
            val incoming = existing.copy(requests = listOf(refused))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                basketExchangeSyncDAO.put(
                    match { updated ->
                        updated.status == BasketExchangeStatus.OPEN &&
                            updated.requests.single().status == BasketExchangeRequestStatus.REJECTED
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN pending request WHEN non-offerer tries to refuse THEN REJECTED FORBIDDEN`() =
        runTest {
            val pendingRequest = buildPendingRequest()
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val refused = pendingRequest.copy(status = BasketExchangeRequestStatus.REJECTED)
            val incoming = existing.copy(requests = listOf(refused))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    // endregion

    // region cancel

    @Test
    fun `GIVEN open exchange WHEN offerer cancels THEN APPLIED and pending requests rejected`() =
        runTest {
            val pendingRequest = buildPendingRequest()
            val existing = buildOpenExchange(requests = listOf(pendingRequest))
            val incoming = existing.copy(status = BasketExchangeStatus.CANCELLED)
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN non-offerer WHEN cancel THEN REJECTED FORBIDDEN`() =
        runTest {
            val existing = buildOpenExchange()
            val incoming = existing.copy(status = BasketExchangeStatus.CANCELLED)
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN already cancelled exchange WHEN cancel THEN REJECTED CONFLICT`() =
        runTest {
            val existing = buildOpenExchange().copy(status = BasketExchangeStatus.CANCELLED)
            val incoming = existing.copy(status = BasketExchangeStatus.CANCELLED)
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    // endregion

    // region accept

    @Test
    fun `GIVEN open exchange with pending request WHEN offerer accepts THEN APPLIED and other requests rejected`() =
        runTest {
            val acceptedRequest = buildPendingRequest(requestId = REQUEST_ID, requesterId = REQUESTER_ID)
            val otherRequest = buildPendingRequest(requestId = "request-other", requesterId = "other-requester")
            val existing = buildOpenExchange(requests = listOf(acceptedRequest, otherRequest))
            val incoming =
                existing.copy(
                    status = BasketExchangeStatus.ACCEPTED,
                    acceptedRequestId = REQUEST_ID.toId(),
                )
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                basketExchangeSyncDAO.put(
                    match { updated ->
                        updated.status == BasketExchangeStatus.ACCEPTED &&
                            updated.requests.find { it.requestId.id == REQUEST_ID }?.status == BasketExchangeRequestStatus.ACCEPTED &&
                            updated.requests.find { it.requestId.id == "request-other" }?.status == BasketExchangeRequestStatus.REJECTED
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN accepted_request_id missing WHEN accept THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existing = buildOpenExchange()
            val incoming = existing.copy(status = BasketExchangeStatus.ACCEPTED)
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
        }

    @Test
    fun `GIVEN non-pending accepted request WHEN accept THEN REJECTED CONFLICT`() =
        runTest {
            val withdrawn = buildPendingRequest().copy(status = BasketExchangeRequestStatus.WITHDRAWN)
            val existing = buildOpenExchange(requests = listOf(withdrawn))
            val incoming =
                existing.copy(
                    status = BasketExchangeStatus.ACCEPTED,
                    acceptedRequestId = withdrawn.requestId,
                )
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    // endregion

    // region delete

    @Test
    fun `WHEN delete THEN always REJECTED FORBIDDEN`() =
        runTest {
            val op = Delete(EntityType.BasketExchange, EXCHANGE_ID)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(offererAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    // endregion

    // region snapshot

    @Test
    fun `GIVEN exchanges in DAO WHEN snapshot THEN returns all as BasketExchangePayload`() =
        runTest {
            val exchange = buildOpenExchange()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(exchange)

            val result = service.snapshot(offererAuth)

            assertEquals(1, result.size)
            assertEquals(BasketExchangePayload(exchange), result.first())
        }

    @Test
    fun `GIVEN caller without organization WHEN snapshot THEN returns empty`() =
        runTest {
            val result = service.snapshot(noOrgAuth)

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { basketExchangeSyncDAO.getByOrganizationId(any()) }
        }

    // endregion

    // region shared basket alternation guard

    // Both default deliveries (delivery-1, delivery-2) are linked to contract-1 on the same date,
    // so the canonical (scheduledDate, deliveryId) order is [delivery-1 (p=0), delivery-2 (p=1)].
    private fun buildSharedContract(memberIds: List<String>): persistence.model.Contract =
        persistence.model.Contract(
            contractId = CONTRACT_ID.toId(),
            name = "Panier partagé",
            organizationId = ORG_ID.toId(),
            producerAccountId = "pa-1".toId(),
            minDeliveryDate = kotlinx.datetime.LocalDate(2030, 1, 1),
            maxDeliveryDate = kotlinx.datetime.LocalDate(2030, 12, 31),
            deliveryCount = 2,
            seasonYear = 2030,
            sharedBaskets =
                listOf(
                    persistence.model.SharedBasket(
                        sharedBasketId = "sb-1".toId(),
                        memberIds = memberIds.map { it.toId() },
                    ),
                ),
        )

    @Test
    fun `GIVEN shared basket and not the offerer's turn WHEN create THEN REJECTED FORBIDDEN`() =
        runTest {
            // memberIds = [co-sharer, offerer] ⇒ delivery-1 (p=0) belongs to the co-sharer.
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { contractSyncDAO.getByOrganizationId(any()) } returns
                listOf(buildSharedContract(listOf("co-sharer", OFFERER_ID)))

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN shared basket and it is the offerer's turn WHEN create THEN APPLIED`() =
        runTest {
            // memberIds = [offerer, co-sharer] ⇒ delivery-1 (p=0) belongs to the offerer.
            val exchange = buildOpenExchange(TMP_EXCHANGE_ID)
            val mutation = buildMutation(exchange)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { basketExchangeSyncDAO.put(any(), any()) } returns Unit
            coEvery { contractSyncDAO.getByOrganizationId(any()) } returns
                listOf(buildSharedContract(listOf(OFFERER_ID, "co-sharer")))

            val outcome = service.applyUpsert(offererAuth, mutation, BasketExchangePayload(exchange))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN shared basket and not the requester's turn for the counter-delivery WHEN add request THEN REJECTED FORBIDDEN`() =
        runTest {
            // memberIds = [requester, offerer] ⇒ delivery-2 (p=1) belongs to the offerer, not the requester.
            val existing = buildOpenExchange()
            val newRequest =
                buildPendingRequest(requestId = TMP_REQUEST_ID).copy(proposedContractId = CONTRACT_ID.toId())
            val incoming = existing.copy(requests = listOf(newRequest))
            val mutation = buildMutation(incoming)
            coEvery { basketExchangeSyncDAO.findById(any(), any()) } returns existing
            coEvery { basketExchangeSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery { contractSyncDAO.getByOrganizationId(any()) } returns
                listOf(buildSharedContract(listOf(REQUESTER_ID, OFFERER_ID)))

            val outcome = service.applyUpsert(requesterAuth, mutation, BasketExchangePayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { basketExchangeSyncDAO.put(any(), any()) }
        }

    // endregion
}

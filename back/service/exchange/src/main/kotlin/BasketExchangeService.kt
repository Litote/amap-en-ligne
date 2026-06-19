@file:OptIn(ExperimentalTime::class)

package exchange

import authentication.AuthenticatedInfo
import core.EntityTypeService
import email.BasketExchangeAcceptedEmailPort
import email.BasketExchangeRejectedEmailPort
import email.BasketExchangeRequestReceivedEmailPort
import email.MemberSummary
import id.Id
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import notificationpublisher.NotificationContact
import notificationpublisher.NotificationPublisher
import notificationpublisher.resolveCopy
import org.koin.core.annotation.Single
import persistence.changes.BasketExchangePayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationCopyOverride
import persistence.model.NotificationType
import persistence.model.Organization
import persistence.model.holdsBasketOn
import persistence.model.orderedDeliveryIdsForContract
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

/**
 * EntityTypeService for [BasketExchange].
 *
 * Scope: organization:{organizationId}
 *
 * Reciprocal-swap model (validation mutuelle):
 *  - The offerer publishes the delivery they want to exchange (D1).
 *  - A requester proposes one of their own deliveries (D2) in return.
 *  - The offerer validates one request (→ exchange confirmed: offerer receives D2, requester
 *    receives D1) or refuses it individually (the offer stays OPEN for other requesters).
 *
 * Mutation rules:
 *  - Creation (basketExchangeId starts with tmp_): status must be OPEN, no requests, offerer = caller.
 *    Rejected if the offerer's D1 basket is already committed (offered OPEN/ACCEPTED, or accepted as a
 *    counter-delivery) — see [isBasketCommitted].
 *  - Update: valid transitions are OPEN→CANCELLED (offerer only) and OPEN→ACCEPTED (offerer only,
 *    requires acceptedRequestId pointing to a PENDING request). Accepting atomically rejects
 *    all other PENDING requests.
 *  - Request addition (requestId starts with tmp_): offer must be OPEN, no self-request, no duplicate
 *    PENDING per member, a counter-delivery (proposedDeliveryId) is required and must be an active
 *    delivery distinct from D1, not already committed by the requester. serverEntityId = basketExchangeId.
 *  - Request withdrawal (PENDING→WITHDRAWN): only by requester.
 *  - Request refusal (PENDING→REJECTED, offer stays OPEN): only by offerer.
 *  - Remaining request status changes happen via the OPEN→ACCEPTED transition.
 *
 * Note on serverEntityId for nested request ids:
 *  The existing [MutationOutcome.serverEntityId] convention carries the real entity id for
 *  tmp_* creations. BasketExchange is the aggregate root, so when a tmp_requestId is allocated,
 *  serverEntityId = basketExchangeId.id (the entity being upserted). The front reconciles which
 *  tmp request id was resolved by comparing the embedded requests list on the next sync bootstrap.
 *
 * applyDelete: always FORBIDDEN — cancellation must go through Upsert with status=CANCELLED.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class BasketExchangeService(
    private val basketExchangeSyncDAO: BasketExchangeSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val requestReceivedEmailPort: BasketExchangeRequestReceivedEmailPort,
    private val acceptedEmailPort: BasketExchangeAcceptedEmailPort,
    private val rejectedEmailPort: BasketExchangeRejectedEmailPort,
    private val notificationPublisher: NotificationPublisher,
) : EntityTypeService<BasketExchangePayload>(EntityType.BasketExchange) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: BasketExchangePayload,
    ): MutationOutcome {
        val incoming = payload.basketExchange
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        if (incoming.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }
        return if (incoming.basketExchangeId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
            applyCreate(auth, mutation, incoming, organizationId)
        } else {
            applyUpdate(auth, mutation, incoming, organizationId)
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome =
        rejected(
            mutation,
            MutationErrorCode.FORBIDDEN,
            "hard delete not allowed for basket exchanges — use Upsert with status=CANCELLED",
        )

    override suspend fun snapshot(auth: AuthenticatedInfo): List<BasketExchangePayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return basketExchangeSyncDAO.getByOrganizationId(organizationId.toId()).map { BasketExchangePayload(it) }
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<BasketExchangePayload> =
        when (scope) {
            is SyncScope.Organization -> {
                if (auth.organizationId != null && auth.organizationId == scope.organizationId) {
                    basketExchangeSyncDAO.getByOrganizationId(scope.organizationId.toId()).map { BasketExchangePayload(it) }
                } else {
                    emptyList()
                }
            }

            SyncScope.InstanceOwner,
            is SyncScope.ProducerAccount,
            is SyncScope.Member,
            is SyncScope.Owner,
            -> {
                emptyList()
            }
        }

    // region create

    private suspend fun applyCreate(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        incoming: BasketExchange,
        organizationId: String,
    ): MutationOutcome {
        // Caller must be the offerer
        if (incoming.offeringMemberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "offeringMemberId must match the caller")
        }
        // Initial state must be OPEN
        if (incoming.status != BasketExchangeStatus.OPEN) {
            return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, "new basket exchange must have status OPEN")
        }
        if (incoming.decidedAt != null || incoming.acceptedRequestId != null || incoming.requests.isNotEmpty()) {
            return rejected(
                mutation,
                MutationErrorCode.INVALID_PAYLOAD,
                "new basket exchange must have no decided_at, no accepted_request_id, and no requests",
            )
        }
        // Delivery must exist and be active
        val organization =
            organizationSyncDAO.getById(incoming.organizationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "organization not found")
        val delivery =
            organization.deliveries.find { it.deliveryId == incoming.deliveryId }
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "delivery not found in organization")
        if (!delivery.status.isActive()) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "delivery is not active")
        }
        // For a shared (alternating) basket, only the family whose turn it is may offer the basket.
        rejectIfNotBasketHolder(
            mutation,
            organization,
            incoming.contractId,
            incoming.deliveryId,
            incoming.offeringMemberId,
            "offer",
        )?.let { return it }
        // The offered basket must not already be committed (open/accepted offer, or accepted counter-delivery)
        val existingForOrg = basketExchangeSyncDAO.getByOrganizationId(organizationId.toId())
        if (existingForOrg.isBasketCommitted(incoming.offeringMemberId, incoming.deliveryId)) {
            return rejected(
                mutation,
                MutationErrorCode.UNIQUE_VIOLATION,
                "this delivery basket is already committed in another exchange",
            )
        }
        val realId = generateId<BasketExchange>()
        val exchange =
            incoming.copy(
                basketExchangeId = realId,
                createdAt = Clock.System.now(),
            )
        basketExchangeSyncDAO.put(exchange, buildUpsertChange(organizationId, exchange))
        return applied(mutation, realId.id)
    }

    // endregion

    // region update

    private suspend fun applyUpdate(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        incoming: BasketExchange,
        organizationId: String,
    ): MutationOutcome {
        val existing =
            basketExchangeSyncDAO.findById(organizationId.toId(), incoming.basketExchangeId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "basket exchange not found")

        // Check for request-only mutations first (request add / withdrawal)
        val requestDiff = detectRequestMutation(existing, incoming)
        if (requestDiff != null) {
            return applyRequestMutation(auth, mutation, existing, incoming, organizationId, requestDiff)
        }

        // Otherwise it is an offer status transition
        return applyStatusTransition(auth, mutation, existing, incoming, organizationId)
    }

    /**
     * Detects whether the incoming payload differs from [existing] only in the [BasketExchange.requests]
     * list (add one new request or update one existing request to WITHDRAWN) while all other fields
     * remain equal.
     *
     * Returns the detected [RequestMutation] or null if the delta spans more than just requests.
     */
    private fun detectRequestMutation(
        existing: BasketExchange,
        incoming: BasketExchange,
    ): RequestMutation? {
        val offerFieldsEqual =
            existing.copy(requests = emptyList()) == incoming.copy(requests = emptyList())
        if (!offerFieldsEqual) return null

        val existingIds = existing.requests.map { it.requestId }.toSet()
        val incomingIds = incoming.requests.map { it.requestId }.toSet()

        // New request added (tmp_ id = creation)
        val newRequests = incoming.requests.filter { it.requestId.id.startsWith(ClientMutation.TMP_ID_PREFIX) }
        if (newRequests.size == 1 && existingIds == (incomingIds - newRequests.first().requestId)) {
            return RequestMutation.Add(newRequests.first())
        }

        // Existing request transitioned (withdrawn by requester or refused by offerer), offer unchanged
        val singleTransition = detectSingleRequestTransition(existing, incoming, existingIds, incomingIds)
        if (singleTransition != null) return singleTransition

        return null
    }

    /**
     * Detects a single existing request transitioning from PENDING to either WITHDRAWN (by the
     * requester) or REJECTED (individual refusal by the offerer, the offer staying OPEN), with all
     * other requests unchanged.
     */
    private fun detectSingleRequestTransition(
        existing: BasketExchange,
        incoming: BasketExchange,
        existingIds: Set<Id<BasketExchangeRequest>>,
        incomingIds: Set<Id<BasketExchangeRequest>>,
    ): RequestMutation? {
        if (existingIds != incomingIds) return null
        val transitioned =
            incoming.requests.filter { req ->
                val old = existing.requests.find { it.requestId == req.requestId }
                old != null && old.status == BasketExchangeRequestStatus.PENDING &&
                    (req.status == BasketExchangeRequestStatus.WITHDRAWN || req.status == BasketExchangeRequestStatus.REJECTED)
            }
        if (transitioned.size != 1) return null
        val target = transitioned.first()
        val unchangedOthers =
            incoming.requests.all { req ->
                req.requestId == target.requestId ||
                    existing.requests.find { it.requestId == req.requestId } == req
            }
        if (!unchangedOthers) return null
        return when (target.status) {
            BasketExchangeRequestStatus.WITHDRAWN -> RequestMutation.Withdraw(target)
            BasketExchangeRequestStatus.REJECTED -> RequestMutation.Refuse(target)
            else -> null
        }
    }

    private sealed interface RequestMutation {
        data class Add(
            val request: BasketExchangeRequest,
        ) : RequestMutation

        data class Withdraw(
            val request: BasketExchangeRequest,
        ) : RequestMutation

        data class Refuse(
            val request: BasketExchangeRequest,
        ) : RequestMutation
    }

    private suspend fun applyRequestMutation(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
        requestMutation: RequestMutation,
    ): MutationOutcome =
        when (requestMutation) {
            is RequestMutation.Add -> applyAddRequest(auth, mutation, existing, incoming, organizationId, requestMutation.request)
            is RequestMutation.Withdraw -> applyWithdrawRequest(auth, mutation, existing, incoming, organizationId, requestMutation.request)
            is RequestMutation.Refuse -> applyRefuseRequest(auth, mutation, existing, incoming, organizationId, requestMutation.request)
        }

    private suspend fun applyAddRequest(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
        newRequest: BasketExchangeRequest,
    ): MutationOutcome {
        // Offer must be OPEN
        if (existing.status != BasketExchangeStatus.OPEN) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "offer is not open")
        }
        // No self-request
        if (newRequest.requesterMemberId == existing.offeringMemberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "cannot request your own exchange offer")
        }
        // Caller must be the requester
        if (newRequest.requesterMemberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "requesterMemberId must match the caller")
        }
        // Request must start as PENDING
        if (newRequest.status != BasketExchangeRequestStatus.PENDING) {
            return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, "new request must have status PENDING")
        }
        // No duplicate PENDING request for same member
        val alreadyPending =
            existing.requests.any { req ->
                req.requesterMemberId == newRequest.requesterMemberId &&
                    req.status == BasketExchangeRequestStatus.PENDING
            }
        if (alreadyPending) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, "a pending request already exists for this member")
        }
        // A counter-delivery (the requester's own basket offered in return) is required
        val proposedDeliveryId =
            newRequest.proposedDeliveryId
                ?: return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, "a counter-delivery (proposed_delivery_id) is required")
        if (proposedDeliveryId == existing.deliveryId) {
            return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, "the counter-delivery must differ from the offered delivery")
        }
        val organization =
            organizationSyncDAO.getById(existing.organizationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "organization not found")
        val proposedDelivery =
            organization.deliveries.find { it.deliveryId == proposedDeliveryId }
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "proposed delivery not found in organization")
        if (!proposedDelivery.status.isActive()) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "proposed delivery is not active")
        }
        // For a shared (alternating) basket, the requester may only offer a counter-delivery whose
        // basket is theirs to give that week.
        rejectIfNotBasketHolder(
            mutation,
            organization,
            newRequest.proposedContractId,
            proposedDeliveryId,
            newRequest.requesterMemberId,
            "counter-delivery",
        )?.let { return it }
        // The proposed counter-delivery basket must not already be committed by the requester
        val allForOrg = basketExchangeSyncDAO.getByOrganizationId(organizationId.toId())
        if (allForOrg.isBasketCommitted(newRequest.requesterMemberId, proposedDeliveryId)) {
            return rejected(
                mutation,
                MutationErrorCode.UNIQUE_VIOLATION,
                "your proposed counter-delivery basket is already committed in another exchange",
            )
        }

        val realRequestId = generateId<BasketExchangeRequest>()
        val savedRequest = newRequest.copy(requestId = realRequestId, createdAt = Clock.System.now())
        val rewrittenRequests =
            incoming.requests.map { req ->
                if (req.requestId == newRequest.requestId) savedRequest else req
            }
        val updated = incoming.copy(requests = rewrittenRequests)
        basketExchangeSyncDAO.put(updated, buildUpsertChange(organizationId, updated))

        // Best-effort notification to the offerer
        runCatching {
            val offererMember = memberSyncDAO.getByOrganizationId(existing.organizationId).find { it.memberId == existing.offeringMemberId }
            val requesterMember =
                memberSyncDAO.getByOrganizationId(existing.organizationId).find {
                    it.memberId ==
                        savedRequest.requesterMemberId
                }
            if (offererMember != null && requesterMember != null) {
                requestReceivedEmailPort.notifyOffererOfNewRequest(
                    updated,
                    savedRequest,
                    offererMember.toSummary(),
                    requesterMember.toSummary(),
                    organization.name,
                )
                val requesterName = requesterMember.displayName()
                val offeredDate = organization.deliveryDateLabel(existing.deliveryId)
                val proposedDate = organization.deliveryDateLabel(proposedDeliveryId)
                notifyMember(
                    member = offererMember,
                    category = NotificationCategory.BASKET_EXCHANGE_REQUEST_RECEIVED,
                    defaultTitle = "Nouvelle demande d'échange de panier",
                    defaultBody =
                        "$requesterName propose son panier du $proposedDate en échange du vôtre du $offeredDate.",
                    relatedEntityId = updated.basketExchangeId.id,
                    deepLink = requestsDeepLink(updated.basketExchangeId.id),
                    notificationOverrides = organization.notificationOverrides,
                    organizationName = organization.name,
                )
            }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange request-received notification" } }

        // serverEntityId = basketExchangeId because the request id is nested;
        // the front reconciles the tmp→real request id mapping on next sync.
        return applied(mutation, updated.basketExchangeId.id)
    }

    private suspend fun applyWithdrawRequest(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
        withdrawnRequest: BasketExchangeRequest,
    ): MutationOutcome {
        // Only the requester may withdraw
        if (withdrawnRequest.requesterMemberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only the requester can withdraw their own request")
        }
        val now = Clock.System.now()
        val rewrittenRequests =
            incoming.requests.map { req ->
                if (req.requestId == withdrawnRequest.requestId) {
                    req.copy(status = BasketExchangeRequestStatus.WITHDRAWN, decidedAt = now)
                } else {
                    req
                }
            }
        val updated = incoming.copy(requests = rewrittenRequests)
        basketExchangeSyncDAO.put(updated, buildUpsertChange(organizationId, updated))
        return applied(mutation, updated.basketExchangeId.id)
    }

    /**
     * Individual refusal of a single PENDING request by the offerer. The offer stays OPEN so other
     * requesters may still be validated. The refused requester is notified.
     */
    private suspend fun applyRefuseRequest(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
        refusedRequest: BasketExchangeRequest,
    ): MutationOutcome {
        // Only the offerer may refuse a request
        if (existing.offeringMemberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only the offerer can refuse a request")
        }
        // Offer must still be OPEN
        if (existing.status != BasketExchangeStatus.OPEN) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "offer is not open")
        }
        // The refused request must currently be PENDING
        val target = existing.requests.find { it.requestId == refusedRequest.requestId }
        if (target == null || target.status != BasketExchangeRequestStatus.PENDING) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "refused request is not PENDING")
        }
        val now = Clock.System.now()
        val rewrittenRequests =
            incoming.requests.map { req ->
                if (req.requestId == refusedRequest.requestId) {
                    req.copy(status = BasketExchangeRequestStatus.REJECTED, decidedAt = now)
                } else {
                    req
                }
            }
        val updated = incoming.copy(requests = rewrittenRequests)
        basketExchangeSyncDAO.put(updated, buildUpsertChange(organizationId, updated))

        // Best-effort rejection notification to the refused requester
        runCatching {
            val members = memberSyncDAO.getByOrganizationId(existing.organizationId)
            val requesterMember = members.find { it.memberId == target.requesterMemberId }
            if (requesterMember != null) {
                val org = organizationFor(existing.organizationId)
                rejectedEmailPort.notifyRequesterRejected(updated, target, requesterMember.toSummary(), org?.name)
                val offeredDate = org?.deliveryDateLabel(existing.deliveryId)
                notifyMember(
                    member = requesterMember,
                    category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                    defaultTitle = "Proposition d'échange refusée",
                    defaultBody = "Votre proposition d'échange pour le panier du $offeredDate n'a pas été retenue.",
                    relatedEntityId = updated.basketExchangeId.id,
                    deepLink = exchangeDeepLink(),
                    notificationOverrides = org?.notificationOverrides ?: emptyMap(),
                    organizationName = org?.name,
                )
            }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange refusal notification" } }

        return applied(mutation, updated.basketExchangeId.id)
    }

    // endregion

    // region status transitions

    private suspend fun applyStatusTransition(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
    ): MutationOutcome {
        if (existing.status != BasketExchangeStatus.OPEN) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "only OPEN exchanges can be transitioned")
        }
        // Only the offerer may change offer status
        if (incoming.offeringMemberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only the offerer can change offer status")
        }
        return when (incoming.status) {
            BasketExchangeStatus.CANCELLED -> applyCancel(mutation, existing, incoming, organizationId)
            BasketExchangeStatus.ACCEPTED -> applyAccept(mutation, existing, incoming, organizationId)
            BasketExchangeStatus.OPEN -> rejected(mutation, MutationErrorCode.CONFLICT, "invalid status transition OPEN→OPEN")
        }
    }

    private suspend fun applyCancel(
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
    ): MutationOutcome {
        val now = Clock.System.now()
        // Reject all PENDING requests
        val rejectAllPending =
            incoming.requests.map { req ->
                if (req.status == BasketExchangeRequestStatus.PENDING) {
                    req.copy(status = BasketExchangeRequestStatus.REJECTED, decidedAt = now)
                } else {
                    req
                }
            }
        val updated =
            incoming.copy(
                status = BasketExchangeStatus.CANCELLED,
                decidedAt = now,
                requests = rejectAllPending,
            )
        basketExchangeSyncDAO.put(updated, buildUpsertChange(organizationId, updated))

        // Best-effort rejection notifications
        runCatching {
            val orgId = existing.organizationId
            val members = memberSyncDAO.getByOrganizationId(orgId)
            val org = organizationFor(orgId)
            val overrides = org?.notificationOverrides ?: emptyMap()
            val offeredDate = org?.deliveryDateLabel(existing.deliveryId)
            rejectAllPending
                .filter { it.status == BasketExchangeRequestStatus.REJECTED }
                .forEach { req ->
                    val requesterMember = members.find { it.memberId == req.requesterMemberId }
                    if (requesterMember != null) {
                        rejectedEmailPort.notifyRequesterRejected(updated, req, requesterMember.toSummary(), org?.name)
                        notifyMember(
                            member = requesterMember,
                            category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                            defaultTitle = "Échange de panier annulé",
                            defaultBody = "L'offre d'échange de panier du $offeredDate que vous aviez demandée a été annulée.",
                            relatedEntityId = updated.basketExchangeId.id,
                            deepLink = exchangeDeepLink(),
                            notificationOverrides = overrides,
                            organizationName = org?.name,
                        )
                    }
                }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange rejection notifications on cancel" } }

        return applied(mutation, updated.basketExchangeId.id)
    }

    private suspend fun applyAccept(
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
    ): MutationOutcome {
        val acceptedRequestId =
            incoming.acceptedRequestId
                ?: return rejected(
                    mutation,
                    MutationErrorCode.INVALID_PAYLOAD,
                    "acceptedRequestId is required for OPEN→ACCEPTED transition",
                )

        val targetRequest =
            existing.requests.find { it.requestId == acceptedRequestId }
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "accepted_request_id not found among requests")

        if (targetRequest.status != BasketExchangeRequestStatus.PENDING) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "accepted request is not PENDING")
        }

        val now = Clock.System.now()
        val resolvedRequests =
            existing.requests.map { req ->
                when {
                    req.requestId == acceptedRequestId -> {
                        req.copy(status = BasketExchangeRequestStatus.ACCEPTED, decidedAt = now)
                    }

                    req.status == BasketExchangeRequestStatus.PENDING -> {
                        req.copy(status = BasketExchangeRequestStatus.REJECTED, decidedAt = now)
                    }

                    else -> {
                        req
                    }
                }
            }
        val updated =
            incoming.copy(
                status = BasketExchangeStatus.ACCEPTED,
                decidedAt = now,
                acceptedRequestId = acceptedRequestId,
                requests = resolvedRequests,
            )
        basketExchangeSyncDAO.put(updated, buildUpsertChange(organizationId, updated))

        // Best-effort email notifications
        runCatching {
            val members = memberSyncDAO.getByOrganizationId(existing.organizationId)
            val org = organizationFor(existing.organizationId)
            val overrides = org?.notificationOverrides ?: emptyMap()
            val offeredDate = org?.deliveryDateLabel(existing.deliveryId)
            resolvedRequests.forEach { req ->
                val requesterMember = members.find { it.memberId == req.requesterMemberId }
                if (requesterMember != null) {
                    when (req.status) {
                        BasketExchangeRequestStatus.ACCEPTED -> {
                            acceptedEmailPort.notifyRequesterAccepted(updated, req, requesterMember.toSummary(), org?.name)
                            val proposedDate = org?.deliveryDateLabel(req.proposedDeliveryId)
                            notifyMember(
                                member = requesterMember,
                                category = NotificationCategory.BASKET_EXCHANGE_ACCEPTED,
                                defaultTitle = "Échange de panier confirmé",
                                defaultBody =
                                    "Votre échange est confirmé : vous récupérez le panier du $offeredDate, " +
                                        "vous cédez le vôtre du $proposedDate.",
                                relatedEntityId = updated.basketExchangeId.id,
                                deepLink = exchangeDeepLink(),
                                notificationOverrides = overrides,
                                organizationName = org?.name,
                            )
                        }

                        BasketExchangeRequestStatus.REJECTED -> {
                            rejectedEmailPort.notifyRequesterRejected(updated, req, requesterMember.toSummary(), org?.name)
                            notifyMember(
                                member = requesterMember,
                                category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                                defaultTitle = "Demande de panier non retenue",
                                defaultBody =
                                    "Votre proposition d'échange pour le panier du $offeredDate n'a pas été retenue.",
                                relatedEntityId = updated.basketExchangeId.id,
                                deepLink = exchangeDeepLink(),
                                notificationOverrides = overrides,
                                organizationName = org?.name,
                            )
                        }

                        else -> {
                            Unit
                        }
                    }
                }
            }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange acceptance/rejection notifications" } }

        return applied(mutation, updated.basketExchangeId.id)
    }

    // endregion

    private fun buildUpsertChange(
        organizationId: String,
        exchange: BasketExchange,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.BasketExchange,
            entityId = exchange.basketExchangeId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = BasketExchangePayload(exchange),
            producedAt = System.currentTimeMillis(),
        )

    private fun Member.toSummary(): MemberSummary =
        MemberSummary(
            memberId = memberId.id,
            firstName = firstName ?: "",
            lastName = lastName ?: "",
            email = email ?: "",
        )

    /** Human-readable name for notification copy ("Prénom Nom", falling back to "Un membre"). */
    private fun Member.displayName(): String {
        val name = listOfNotNull(firstName, lastName).filter { it.isNotBlank() }.joinToString(" ")
        return name.ifBlank { "Un membre" }
    }

    /**
     * True when [memberId]'s basket for [deliveryId] is already engaged in another exchange so it
     * cannot be re-committed. A basket is committed when it is:
     *  - currently offered for exchange (OPEN/ACCEPTED), or
     *  - given away or received through a settled (ACCEPTED) exchange.
     *
     * In an ACCEPTED exchange both deliveries change hands: the offerer gives D1 and receives the
     * accepted counter-delivery D2, the requester gives D2 and receives D1. Both deliveries are
     * therefore committed for both parties — a basket already exchanged or received cannot be
     * re-offered or re-proposed.
     */
    private fun List<BasketExchange>.isBasketCommitted(
        memberId: Id<Member>,
        deliveryId: Id<Delivery>,
    ): Boolean =
        any { ex ->
            val offered =
                ex.offeringMemberId == memberId &&
                    ex.deliveryId == deliveryId &&
                    ex.status in setOf(BasketExchangeStatus.OPEN, BasketExchangeStatus.ACCEPTED)
            if (offered) return@any true
            if (ex.status != BasketExchangeStatus.ACCEPTED) return@any false
            val acceptedRequest =
                ex.acceptedRequestId?.let { id -> ex.requests.find { it.requestId == id } }
                    ?: return@any false
            val involvesMember = memberId == ex.offeringMemberId || memberId == acceptedRequest.requesterMemberId
            involvesMember && (deliveryId == ex.deliveryId || deliveryId == acceptedRequest.proposedDeliveryId)
        }

    /**
     * Rejects (FORBIDDEN) when [memberId] does not hold the basket of the contract identified by
     * [contractId] on [deliveryId] this week — i.e. when the contract uses an alternating shared
     * basket and it is another family's turn. No-op when [contractId] is null, the contract is
     * unknown, or it has no shared baskets (the non-shared case is unchanged). [role] is "offer" or
     * "counter-delivery" for the message.
     */
    private suspend fun rejectIfNotBasketHolder(
        mutation: ClientMutation,
        organization: Organization,
        contractId: Id<DeliveryContract>?,
        deliveryId: Id<Delivery>,
        memberId: Id<Member>,
        role: String,
    ): MutationOutcome? {
        if (contractId == null) return null
        val contract =
            contractSyncDAO
                .getByOrganizationId(organization.organizationId)
                .find { it.contractId.id == contractId.id } ?: return null
        if (contract.sharedBaskets.isEmpty()) return null
        val ordered = organization.orderedDeliveryIdsForContract(contract.contractId)
        if (contract.holdsBasketOn(memberId, ordered, deliveryId)) return null
        return rejected(
            mutation,
            MutationErrorCode.FORBIDDEN,
            "member ${memberId.id} does not hold the shared basket of contract ${contract.contractId.id} " +
                "on delivery ${deliveryId.id} this week ($role)",
        )
    }

    /** French date label of [deliveryId] within this organization, or "?" if unknown. */
    private fun Organization.deliveryDateLabel(deliveryId: Id<Delivery>?): String {
        val delivery = deliveryId?.let { id -> deliveries.find { it.deliveryId == id } } ?: return "?"
        val dt = delivery.scheduledDate
        val month = FRENCH_MONTHS.getOrElse(dt.month.ordinal) { "" }
        return "${dt.day} $month ${dt.year}".trim()
    }

    private fun requestsDeepLink(basketExchangeId: String): String = "/basket-exchange/$basketExchangeId/requests"

    private fun exchangeDeepLink(): String = "/basket-exchange"

    /** Outbound channels the member opted into, derived from their synced preferences. */
    private fun Member.optedChannels(): Set<NotificationChannel> =
        buildSet {
            if (userPreferences.emailNotificationsEnabled) add(NotificationChannel.EMAIL)
            if (userPreferences.pushNotificationsEnabled) add(NotificationChannel.PUSH)
        }

    /**
     * Publishes an in-app notification to [member] and fans out to their opted channels.
     * The member feed is keyed by the auth subject (`member:{sub}`), so a member with no
     * linked `sub` (pending-invitation rows) cannot be addressed yet — skipped.
     */
    private suspend fun notifyMember(
        member: Member,
        category: NotificationCategory,
        defaultTitle: String,
        defaultBody: String,
        relatedEntityId: String,
        deepLink: String? = null,
        notificationOverrides: Map<NotificationCategory, NotificationCopyOverride> = emptyMap(),
        organizationName: String? = null,
        type: NotificationType = NotificationType.INFO,
    ) {
        // memberId == sub by convention
        val sub = member.memberId.id
        val copy = notificationOverrides.resolveCopy(category, defaultTitle, defaultBody)
        notificationPublisher.publish(
            recipientScope = SyncScope.Member(sub).key,
            type = type,
            category = category,
            title = copy.title,
            body = copy.body,
            deepLink = deepLink,
            relatedEntityId = relatedEntityId,
            contact = NotificationContact(email = member.email, organizationName = organizationName),
            channels = member.optedChannels(),
        )
    }

    /** Loads the organization for [organizationId] (name + notification overrides), or null if unknown. */
    private suspend fun organizationFor(organizationId: Id<Organization>): Organization? = organizationSyncDAO.getById(organizationId)

    private companion object {
        private val logger = KotlinLogging.logger {}
        private val FRENCH_MONTHS =
            listOf(
                "janvier",
                "février",
                "mars",
                "avril",
                "mai",
                "juin",
                "juillet",
                "août",
                "septembre",
                "octobre",
                "novembre",
                "décembre",
            )
    }
}

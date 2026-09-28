@file:OptIn(ExperimentalTime::class)

package exchange

import authentication.AuthenticatedInfo
import core.EntityTypeService
import email.BasketExchangeAcceptedEmailPort
import email.BasketExchangeRejectedEmailPort
import email.BasketExchangeRequestReceivedEmailPort
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.BasketExchangePayload
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.EntityType
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
    private val requestReceivedEmailPort: BasketExchangeRequestReceivedEmailPort,
    private val acceptedEmailPort: BasketExchangeAcceptedEmailPort,
    private val rejectedEmailPort: BasketExchangeRejectedEmailPort,
    private val notifier: BasketExchangeNotifier,
    private val commitmentValidator: BasketExchangeCommitmentValidator,
) : EntityTypeService<BasketExchangePayload>(EntityType.BasketExchange) {
    private val outcomeNotifications =
        BasketExchangeOutcomeNotifications(
            memberSyncDAO,
            organizationSyncDAO,
            requestReceivedEmailPort,
            acceptedEmailPort,
            rejectedEmailPort,
            notifier,
        )

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
        commitmentValidator
            .rejectIfNotBasketHolder(
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

    private suspend fun applyRequestMutation(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        existing: BasketExchange,
        incoming: BasketExchange,
        organizationId: String,
        requestMutation: BasketExchangeRequestMutation,
    ): MutationOutcome =
        when (requestMutation) {
            is BasketExchangeRequestMutation.Add -> {
                applyAddRequest(
                    auth,
                    mutation,
                    existing,
                    incoming,
                    organizationId,
                    requestMutation.request,
                )
            }

            is BasketExchangeRequestMutation.Withdraw -> {
                applyWithdrawRequest(
                    auth,
                    mutation,
                    incoming,
                    organizationId,
                    requestMutation.request,
                )
            }

            is BasketExchangeRequestMutation.Refuse -> {
                applyRefuseRequest(
                    auth,
                    mutation,
                    existing,
                    incoming,
                    organizationId,
                    requestMutation.request,
                )
            }
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
        commitmentValidator
            .rejectIfNotBasketHolder(
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
        outcomeNotifications.onRequestAdded(existing, updated, savedRequest, organization, proposedDeliveryId)

        // serverEntityId = basketExchangeId because the request id is nested;
        // the front reconciles the tmp→real request id mapping on next sync.
        return applied(mutation, updated.basketExchangeId.id)
    }

    private suspend fun applyWithdrawRequest(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
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
        outcomeNotifications.onRequestRefused(existing, updated, target)

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
        outcomeNotifications.onCancelled(existing, updated, rejectAllPending)

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
        outcomeNotifications.onAccepted(existing, updated, resolvedRequests)

        return applied(mutation, updated.basketExchangeId.id)
    }

    // endregion
}

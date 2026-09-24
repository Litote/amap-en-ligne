package exchange

import email.BasketExchangeAcceptedEmailPort
import email.BasketExchangeRejectedEmailPort
import email.BasketExchangeRequestReceivedEmailPort
import id.Id
import io.github.oshai.kotlinlogging.KotlinLogging
import notificationpublisher.NotificationContent
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.Delivery
import persistence.model.NotificationCategory
import persistence.model.Organization

/**
 * Best-effort post-commit side-effects (emails + in-app notifications) of [BasketExchangeService]
 * mutations. Every method swallows and logs its failures: a notification error never rolls back
 * the already-persisted exchange.
 */
internal class BasketExchangeOutcomeNotifications(
    private val memberSyncDAO: MemberSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val requestReceivedEmailPort: BasketExchangeRequestReceivedEmailPort,
    private val acceptedEmailPort: BasketExchangeAcceptedEmailPort,
    private val rejectedEmailPort: BasketExchangeRejectedEmailPort,
    private val notifier: BasketExchangeNotifier,
) {
    /** Notifies the offerer that [savedRequest] (counter-delivery [proposedDeliveryId]) was submitted. */
    suspend fun onRequestAdded(
        existing: BasketExchange,
        updated: BasketExchange,
        savedRequest: BasketExchangeRequest,
        organization: Organization,
        proposedDeliveryId: Id<Delivery>,
    ) {
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
                notifier.notifyMember(
                    member = offererMember,
                    category = NotificationCategory.BASKET_EXCHANGE_REQUEST_RECEIVED,
                    defaultContent =
                        NotificationContent(
                            title = "Nouvelle demande d'échange de panier",
                            body = "$requesterName propose son panier du $proposedDate en échange du vôtre du $offeredDate.",
                            deepLink = requestsDeepLink(updated.basketExchangeId.id),
                            relatedEntityId = updated.basketExchangeId.id,
                        ),
                    notificationOverrides = organization.notificationOverrides,
                    organizationName = organization.name,
                )
            }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange request-received notification" } }
    }

    /** Notifies the requester of [target] that the offerer individually refused their request. */
    suspend fun onRequestRefused(
        existing: BasketExchange,
        updated: BasketExchange,
        target: BasketExchangeRequest,
    ) {
        runCatching {
            val members = memberSyncDAO.getByOrganizationId(existing.organizationId)
            val requesterMember = members.find { it.memberId == target.requesterMemberId }
            if (requesterMember != null) {
                val org = organizationFor(existing.organizationId)
                rejectedEmailPort.notifyRequesterRejected(updated, target, requesterMember.toSummary(), org?.name)
                val offeredDate = org?.deliveryDateLabel(existing.deliveryId)
                notifier.notifyMember(
                    member = requesterMember,
                    category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                    defaultContent =
                        NotificationContent(
                            title = "Proposition d'échange refusée",
                            body = "Votre proposition d'échange pour le panier du $offeredDate n'a pas été retenue.",
                            deepLink = exchangeDeepLink(),
                            relatedEntityId = updated.basketExchangeId.id,
                        ),
                    notificationOverrides = org?.notificationOverrides ?: emptyMap(),
                    organizationName = org?.name,
                )
            }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange refusal notification" } }
    }

    /** Notifies every requester whose request was REJECTED by the offer cancellation. */
    suspend fun onCancelled(
        existing: BasketExchange,
        updated: BasketExchange,
        rejectAllPending: List<BasketExchangeRequest>,
    ) {
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
                        notifier.notifyMember(
                            member = requesterMember,
                            category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                            defaultContent =
                                NotificationContent(
                                    title = "Échange de panier annulé",
                                    body = "L'offre d'échange de panier du $offeredDate que vous aviez demandée a été annulée.",
                                    deepLink = exchangeDeepLink(),
                                    relatedEntityId = updated.basketExchangeId.id,
                                ),
                            notificationOverrides = overrides,
                            organizationName = org?.name,
                        )
                    }
                }
        }.onFailure { logger.warn(it) { "failed to send basket-exchange rejection notifications on cancel" } }
    }

    /** Notifies the accepted requester and every requester rejected by the acceptance fan-out. */
    suspend fun onAccepted(
        existing: BasketExchange,
        updated: BasketExchange,
        resolvedRequests: List<BasketExchangeRequest>,
    ) {
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
                            notifier.notifyMember(
                                member = requesterMember,
                                category = NotificationCategory.BASKET_EXCHANGE_ACCEPTED,
                                defaultContent =
                                    NotificationContent(
                                        title = "Échange de panier confirmé",
                                        body =
                                            "Votre échange est confirmé : vous récupérez le panier du $offeredDate, " +
                                                "vous cédez le vôtre du $proposedDate.",
                                        deepLink = exchangeDeepLink(),
                                        relatedEntityId = updated.basketExchangeId.id,
                                    ),
                                notificationOverrides = overrides,
                                organizationName = org?.name,
                            )
                        }

                        BasketExchangeRequestStatus.REJECTED -> {
                            rejectedEmailPort.notifyRequesterRejected(updated, req, requesterMember.toSummary(), org?.name)
                            notifier.notifyMember(
                                member = requesterMember,
                                category = NotificationCategory.BASKET_EXCHANGE_REJECTED,
                                defaultContent =
                                    NotificationContent(
                                        title = "Demande de panier non retenue",
                                        body = "Votre proposition d'échange pour le panier du $offeredDate n'a pas été retenue.",
                                        deepLink = exchangeDeepLink(),
                                        relatedEntityId = updated.basketExchangeId.id,
                                    ),
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
    }

    /** Loads the organization for [organizationId] (name + notification overrides), or null if unknown. */
    private suspend fun organizationFor(organizationId: Id<Organization>): Organization? = organizationSyncDAO.getById(organizationId)

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

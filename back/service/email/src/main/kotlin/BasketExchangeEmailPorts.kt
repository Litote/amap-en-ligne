package email

import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest

/**
 * Summary of a member for use in basket-exchange email notifications.
 * Carries the minimum PII needed to render an email template without exposing
 * unrelated fields.
 */
data class MemberSummary(
    val memberId: String,
    val firstName: String,
    val lastName: String,
    val email: String,
)

/**
 * Email port: notifies the offer owner that a new request has arrived.
 * Best-effort post-commit; current implementations are log stubs.
 */
interface BasketExchangeRequestReceivedEmailPort {
    suspend fun notifyOffererOfNewRequest(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        offererSummary: MemberSummary,
        requesterSummary: MemberSummary,
        organizationName: String? = null,
    )
}

/**
 * Email port: notifies a requester that their request was accepted.
 * Best-effort post-commit; current implementations are log stubs.
 */
interface BasketExchangeAcceptedEmailPort {
    suspend fun notifyRequesterAccepted(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        requesterSummary: MemberSummary,
        organizationName: String? = null,
    )
}

/**
 * Email port: notifies a requester that their request was rejected (either
 * explicitly or because a competing request was accepted).
 * Best-effort post-commit; current implementations are log stubs.
 */
interface BasketExchangeRejectedEmailPort {
    suspend fun notifyRequesterRejected(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        requesterSummary: MemberSummary,
        organizationName: String? = null,
    )
}

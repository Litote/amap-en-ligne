package email.delivery

import email.BasketExchangeAcceptedEmailPort
import email.BasketExchangeRejectedEmailPort
import email.BasketExchangeRequestReceivedEmailPort
import email.EmailTemplates
import email.MemberSummary
import org.koin.core.annotation.Single
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.EmailMessage

/** Notifies the offerer of a new basket-exchange request (best-effort). */
@Single(createdAtStart = true, binds = [BasketExchangeRequestReceivedEmailPort::class])
internal class BasketExchangeRequestReceivedEmailAdapter(
    private val gateway: EmailGateway,
) : BasketExchangeRequestReceivedEmailPort {
    override suspend fun notifyOffererOfNewRequest(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        offererSummary: MemberSummary,
        requesterSummary: MemberSummary,
        organizationName: String?,
    ) {
        val content = EmailTemplates.basketExchangeRequestReceived(offererSummary, requesterSummary, organizationName)
        gateway.deliver(EmailMessage(to = offererSummary.email, subject = content.subject, body = content.body))
    }
}

/** Notifies a requester that their basket-exchange request was accepted. */
@Single(createdAtStart = true, binds = [BasketExchangeAcceptedEmailPort::class])
internal class BasketExchangeAcceptedEmailAdapter(
    private val gateway: EmailGateway,
) : BasketExchangeAcceptedEmailPort {
    override suspend fun notifyRequesterAccepted(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        requesterSummary: MemberSummary,
        organizationName: String?,
    ) {
        val content = EmailTemplates.basketExchangeAccepted(requesterSummary, organizationName)
        gateway.deliver(EmailMessage(to = requesterSummary.email, subject = content.subject, body = content.body))
    }
}

/** Notifies a requester that their basket-exchange request was rejected. */
@Single(createdAtStart = true, binds = [BasketExchangeRejectedEmailPort::class])
internal class BasketExchangeRejectedEmailAdapter(
    private val gateway: EmailGateway,
) : BasketExchangeRejectedEmailPort {
    override suspend fun notifyRequesterRejected(
        exchange: BasketExchange,
        request: BasketExchangeRequest,
        requesterSummary: MemberSummary,
        organizationName: String?,
    ) {
        val content = EmailTemplates.basketExchangeRejected(requesterSummary, organizationName)
        gateway.deliver(EmailMessage(to = requesterSummary.email, subject = content.subject, body = content.body))
    }
}

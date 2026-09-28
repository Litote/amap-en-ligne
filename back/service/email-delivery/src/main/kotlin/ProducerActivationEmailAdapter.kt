package email.delivery

import email.EmailTemplates
import email.ProducerActivationEmailPort
import org.koin.core.annotation.Single
import persistence.model.ActivationToken
import persistence.model.EmailMessage
import persistence.model.ProducerRequest

/** Sends the producer activation email (best-effort). */
@Single(createdAtStart = true, binds = [ProducerActivationEmailPort::class])
internal class ProducerActivationEmailAdapter(
    private val gateway: EmailGateway,
) : ProducerActivationEmailPort {
    override suspend fun sendProducerActivationEmail(
        request: ProducerRequest,
        token: ActivationToken,
    ) {
        val content = EmailTemplates.producerActivation(request, gateway.activationUrl(token.token), token.expiresAt)
        gateway.deliver(EmailMessage(to = request.adminEmail, subject = content.subject, body = content.body))
    }
}

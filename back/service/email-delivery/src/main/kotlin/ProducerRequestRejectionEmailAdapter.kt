package email.delivery

import email.EmailTemplates
import email.ProducerRequestRejectionEmailPort
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import persistence.model.ProducerRequest

/** Sends the producer-request rejection email (best-effort). */
@Single(createdAtStart = true, binds = [ProducerRequestRejectionEmailPort::class])
internal class ProducerRequestRejectionEmailAdapter(
    private val gateway: EmailGateway,
) : ProducerRequestRejectionEmailPort {
    override suspend fun sendRejectionEmail(
        request: ProducerRequest,
        reviewComment: String?,
    ) {
        val content = EmailTemplates.producerRequestRejected(request, reviewComment)
        gateway.deliver(EmailMessage(to = request.adminEmail, subject = content.subject, body = content.body))
    }
}

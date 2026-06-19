package email.delivery

import email.EmailTemplates
import email.RejectionEmailPort
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import persistence.model.OrganizationRequest

/** Sends the organization-request rejection email (best-effort). */
@Single(createdAtStart = true, binds = [RejectionEmailPort::class])
internal class OrganizationRequestRejectionEmailAdapter(
    private val gateway: EmailGateway,
) : RejectionEmailPort {
    override suspend fun sendRejectionEmail(
        request: OrganizationRequest,
        reviewComment: String?,
    ) {
        val content = EmailTemplates.organizationRequestRejected(request, reviewComment)
        gateway.deliver(EmailMessage(to = request.adminEmail, subject = content.subject, body = content.body))
    }
}

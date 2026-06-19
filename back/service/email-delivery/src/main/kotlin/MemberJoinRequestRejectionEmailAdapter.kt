package email.delivery

import email.EmailTemplates
import email.MemberJoinRequestRejectionEmailPort
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import persistence.model.MemberJoinRequest

/** Sends the member-join-request rejection email (best-effort). */
@Single(createdAtStart = true, binds = [MemberJoinRequestRejectionEmailPort::class])
internal class MemberJoinRequestRejectionEmailAdapter(
    private val gateway: EmailGateway,
) : MemberJoinRequestRejectionEmailPort {
    override suspend fun sendRejectionEmail(
        request: MemberJoinRequest,
        organizationName: String?,
    ) {
        val content = EmailTemplates.memberJoinRequestRejected(request, organizationName)
        gateway.deliver(EmailMessage(to = request.email, subject = content.subject, body = content.body))
    }
}

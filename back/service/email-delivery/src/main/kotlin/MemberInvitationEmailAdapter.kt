package email.delivery

import email.EmailTemplates
import email.MemberInvitationEmailPort
import org.koin.core.annotation.Single
import persistence.model.ActivationToken
import persistence.model.EmailMessage
import persistence.model.MemberInvitation

/** Sends the member invitation email (best-effort). */
@Single(createdAtStart = true, binds = [MemberInvitationEmailPort::class])
internal class MemberInvitationEmailAdapter(
    private val gateway: EmailGateway,
) : MemberInvitationEmailPort {
    override suspend fun sendInvitationEmail(
        invitation: MemberInvitation,
        token: ActivationToken,
        organizationName: String?,
    ) {
        val content =
            EmailTemplates.memberInvitation(
                invitation,
                gateway.activationUrl(token.token),
                token.expiresAt,
                organizationName,
            )
        gateway.deliver(EmailMessage(to = invitation.email, subject = content.subject, body = content.body))
    }
}

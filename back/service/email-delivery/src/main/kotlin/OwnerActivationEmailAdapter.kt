package email.delivery

import email.EmailTemplates
import email.OwnerActivationEmailPort
import org.koin.core.annotation.Single
import persistence.model.ActivationToken
import persistence.model.EmailMessage
import persistence.model.OwnerInvitation

/** Sends the instance-owner activation email (best-effort). */
@Single(createdAtStart = true, binds = [OwnerActivationEmailPort::class])
internal class OwnerActivationEmailAdapter(
    private val gateway: EmailGateway,
) : OwnerActivationEmailPort {
    override suspend fun sendOwnerActivationEmail(
        invitation: OwnerInvitation,
        token: ActivationToken,
    ) {
        val content = EmailTemplates.ownerActivation(invitation, gateway.activationUrl(token.token), token.expiresAt)
        gateway.deliver(EmailMessage(to = invitation.email, subject = content.subject, body = content.body))
    }
}

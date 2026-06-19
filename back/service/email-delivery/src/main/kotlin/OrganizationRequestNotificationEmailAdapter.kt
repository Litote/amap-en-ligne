package email.delivery

import email.EmailTemplates
import email.OrganizationRequestNotificationEmailPort
import org.koin.core.annotation.Single
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.EmailMessage
import persistence.model.OrganizationRequest

/**
 * Notifies every active instance owner (best-effort) that a new organization
 * creation request was submitted.
 */
@Single(createdAtStart = true, binds = [OrganizationRequestNotificationEmailPort::class])
internal class OrganizationRequestNotificationEmailAdapter(
    private val gateway: EmailGateway,
    private val ownerDAO: OwnerSyncDAO,
) : OrganizationRequestNotificationEmailPort {
    override suspend fun notifyOwners(request: OrganizationRequest) {
        val content = EmailTemplates.organizationRequestSubmitted(request)
        ownerDAO
            .listAll()
            .filter { it.accountStatus == AccountStatus.ACTIVE && it.email.isNotBlank() }
            .forEach { owner ->
                gateway.deliver(EmailMessage(to = owner.email, subject = content.subject, body = content.body))
            }
    }
}

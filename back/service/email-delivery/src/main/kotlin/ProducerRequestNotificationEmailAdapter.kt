package email.delivery

import email.EmailTemplates
import email.ProducerRequestNotificationEmailPort
import org.koin.core.annotation.Single
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.EmailMessage
import persistence.model.ProducerRequest

/**
 * Notifies every active instance owner (best-effort) that a new producer
 * account request was submitted.
 */
@Single(createdAtStart = true, binds = [ProducerRequestNotificationEmailPort::class])
internal class ProducerRequestNotificationEmailAdapter(
    private val gateway: EmailGateway,
    private val ownerDAO: OwnerSyncDAO,
) : ProducerRequestNotificationEmailPort {
    override suspend fun notifyOwners(request: ProducerRequest) {
        val content = EmailTemplates.producerRequestSubmitted(request)
        ownerDAO
            .listAll()
            .filter { it.accountStatus == AccountStatus.ACTIVE && it.email.isNotBlank() }
            .forEach { owner ->
                gateway.deliver(EmailMessage(to = owner.email, subject = content.subject, body = content.body))
            }
    }
}

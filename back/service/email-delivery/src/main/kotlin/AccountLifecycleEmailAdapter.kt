package email.delivery

import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.EmailTemplates
import email.OwnersBroadcastEvent
import org.koin.core.annotation.Single
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.EmailMessage

/**
 * Sends account-lifecycle emails (best-effort). Notifications to the impacted
 * user carry their identity; the Owners broadcast is PII-free and goes to every
 * *other* active instance owner (resolved via [OwnerSyncDAO]).
 */
@Single(createdAtStart = true, binds = [AccountLifecycleEmailPort::class])
internal class AccountLifecycleEmailAdapter(
    private val gateway: EmailGateway,
    private val ownerDAO: OwnerSyncDAO,
) : AccountLifecycleEmailPort {
    override suspend fun notifyAccountSuspended(target: AccountLifecycleTarget) {
        val content = EmailTemplates.accountSuspended(target)
        gateway.deliver(EmailMessage(to = target.email, subject = content.subject, body = content.body))
    }

    override suspend fun notifyAccountReactivated(target: AccountLifecycleTarget) {
        val content = EmailTemplates.accountReactivated(target)
        gateway.deliver(EmailMessage(to = target.email, subject = content.subject, body = content.body))
    }

    override suspend fun notifyAccountDeleted(target: AccountLifecycleTarget) {
        val content = EmailTemplates.accountDeleted(target)
        gateway.deliver(EmailMessage(to = target.email, subject = content.subject, body = content.body))
    }

    override suspend fun notifyOwnersOfLifecycleEvent(
        event: OwnersBroadcastEvent,
        actorOwnerEmail: String,
        impactedRole: AccountLifecycleRole,
    ) {
        val content = EmailTemplates.ownersLifecycleBroadcast(event, actorOwnerEmail, impactedRole)
        ownerDAO
            .listAll()
            .filter { it.accountStatus == AccountStatus.ACTIVE && it.email != actorOwnerEmail }
            .forEach { owner ->
                gateway.deliver(EmailMessage(to = owner.email, subject = content.subject, body = content.body))
            }
    }
}

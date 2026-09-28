package email.delivery

import email.amapEmailSubject
import io.github.oshai.kotlinlogging.KotlinLogging
import notificationpublisher.NotificationChannelSender
import notificationpublisher.NotificationContact
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import persistence.model.Notification
import persistence.model.NotificationChannel

/**
 * EMAIL channel sender for in-app notifications (ADR-005). Publishes the
 * notification's title/body through the deployment [EmailGateway]. No-op when
 * the recipient has no email on file.
 */
@Single(createdAtStart = true, binds = [NotificationChannelSender::class])
internal class EmailNotificationChannelSender(
    private val gateway: EmailGateway,
) : NotificationChannelSender {
    override val channel: NotificationChannel = NotificationChannel.EMAIL

    override suspend fun send(
        notification: Notification,
        contact: NotificationContact,
    ) {
        val email = contact.email
        if (email.isNullOrBlank()) {
            logger.debug { "Skipping email notification ${notification.notificationId.id}: no recipient email" }
            return
        }
        val subject = amapEmailSubject(contact.organizationName, notification.title)
        gateway.deliver(EmailMessage(to = email, subject = subject, body = notification.body))
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

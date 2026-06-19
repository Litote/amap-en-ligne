package exchange

import notificationpublisher.NotificationContact
import notificationpublisher.NotificationContent
import notificationpublisher.NotificationPublisher
import notificationpublisher.resolveCopy
import org.koin.core.annotation.Single
import persistence.changes.SyncScope
import persistence.model.Member
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationCopyOverride
import persistence.model.NotificationType

/**
 * Handles in-app and channel notification dispatch for basket-exchange events.
 *
 * Callers supply the resolved [Member], a [NotificationCategory], a default [NotificationContent]
 * (title / body / deep-link), and optional org-level copy overrides. The publisher resolves the
 * effective copy, fans out to the member's opted channels, and writes the notification row
 * atomically.
 */
@Single
class BasketExchangeNotifier(
    private val notificationPublisher: NotificationPublisher,
) {
    /**
     * Publishes an in-app notification to [member] and fans out to their opted channels.
     * The member feed is keyed by the auth subject (`member:{sub}`), so a member with no
     * linked `sub` (pending-invitation rows) cannot be addressed yet — skipped.
     */
    suspend fun notifyMember(
        member: Member,
        category: NotificationCategory,
        defaultContent: NotificationContent,
        notificationOverrides: Map<NotificationCategory, NotificationCopyOverride> = emptyMap(),
        organizationName: String? = null,
        type: NotificationType = NotificationType.INFO,
    ) {
        // memberId == sub by convention
        val sub = member.memberId.id
        val copy = notificationOverrides.resolveCopy(category, defaultContent.title, defaultContent.body)
        notificationPublisher.publish(
            recipientScope = SyncScope.Member(sub).key,
            type = type,
            category = category,
            content = defaultContent.copy(title = copy.title, body = copy.body),
            contact = NotificationContact(email = member.email, organizationName = organizationName),
            channels = member.optedChannels(),
        )
    }

    /** Outbound channels the member opted into, derived from their synced preferences. */
    private fun Member.optedChannels(): Set<NotificationChannel> =
        buildSet {
            if (userPreferences.emailNotificationsEnabled) add(NotificationChannel.EMAIL)
            if (userPreferences.pushNotificationsEnabled) add(NotificationChannel.PUSH)
        }
}

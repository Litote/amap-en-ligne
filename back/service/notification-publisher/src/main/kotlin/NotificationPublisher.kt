@file:OptIn(ExperimentalTime::class)

package notificationpublisher

import id.generateId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.NotificationPayload
import persistence.dao.DeviceTokenSyncDAO
import persistence.dao.NotificationSyncDAO
import persistence.model.EntityType
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationType
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

/**
 * Server-side entry point for *creating* notifications (see ADR-005). Domain services
 * call this from their mutation side-effects to push a notification onto a recipient's
 * private sync feed and, best-effort, onto the requested outbound channels.
 *
 * Persisting the row + its [Change] is authoritative (the in-app feed); outbound
 * dispatch is best-effort and never fails the caller.
 */
@Single(createdAtStart = true)
class NotificationPublisher(
    private val notificationSyncDAO: NotificationSyncDAO,
    private val deviceTokenSyncDAO: DeviceTokenSyncDAO,
    private val dispatcher: NotificationDispatcher,
) {
    suspend fun publish(
        recipientScope: String,
        type: NotificationType,
        category: NotificationCategory,
        title: String,
        body: String,
        deepLink: String? = null,
        relatedEntityId: String? = null,
        contact: NotificationContact = NotificationContact(),
        channels: Set<NotificationChannel> = emptySet(),
    ): Notification {
        val notification =
            Notification(
                notificationId = generateId(),
                recipientScope = recipientScope,
                type = type,
                category = category,
                title = title,
                body = body,
                deepLink = deepLink,
                relatedEntityId = relatedEntityId,
                createdAt = Clock.System.now(),
                readAt = null,
            )
        notificationSyncDAO.put(
            notification,
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Notification,
                entityId = notification.notificationId.id,
                scopeKey = recipientScope,
                op = ChangeOp.UPSERT,
                payload = NotificationPayload(notification),
                producedAt = System.currentTimeMillis(),
            ),
        )
        if (channels.isNotEmpty()) {
            // Resolve the recipient's push targets here so channel senders stay pure
            // transports (ADR-005). Only hit the device feed when PUSH is actually opted.
            val resolvedContact =
                if (NotificationChannel.PUSH in channels) {
                    contact.copy(devices = deviceTokenSyncDAO.getByRecipientScope(recipientScope))
                } else {
                    contact
                }
            runCatching { dispatcher.dispatch(notification, resolvedContact, channels) }
                .onFailure { logger.warn(it) { "notification dispatch failed for ${notification.notificationId.id}" } }
        }
        return notification
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

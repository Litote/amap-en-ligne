package notificationpublisher

import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.model.Notification
import persistence.model.NotificationChannel

/**
 * Fans a [Notification] out to the requested outbound [NotificationChannel]s, isolating
 * per-channel failures (transport is best-effort; the in-app feed is the durable record).
 *
 * Senders are injected as a Koin list (one per [NotificationChannel]); channels with no
 * registered sender are skipped (see ADR-005).
 */
@Single(createdAtStart = true)
class NotificationDispatcher(
    senders: List<NotificationChannelSender>,
) {
    private val byChannel: Map<NotificationChannel, NotificationChannelSender> =
        senders.associateBy { it.channel }

    suspend fun dispatch(
        notification: Notification,
        contact: NotificationContact,
        channels: Set<NotificationChannel>,
    ) {
        channels.forEach { channel ->
            val sender = byChannel[channel] ?: return@forEach
            runCatching { sender.send(notification, contact) }
                .onFailure { logger.warn(it) { "failed to dispatch notification ${notification.notificationId.id} on $channel" } }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

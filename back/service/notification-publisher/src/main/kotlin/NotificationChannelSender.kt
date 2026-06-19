package notificationpublisher

import persistence.model.DeviceToken
import persistence.model.Notification
import persistence.model.NotificationChannel

/**
 * Outbound transport for one [NotificationChannel] (email / push).
 *
 * Implementations live in the deployment modules (deploy:jvm / deploy:lambda) and are
 * contributed to the [NotificationDispatcher] as a Koin `List<NotificationChannelSender>`.
 * Adding a transport later is adding one implementation — no change to this layer
 * (see ADR-005).
 */
interface NotificationChannelSender {
    val channel: NotificationChannel

    /** Best-effort delivery. May throw; the dispatcher isolates failures per channel. */
    suspend fun send(
        notification: Notification,
        contact: NotificationContact,
    )
}

/**
 * Where a notification can be delivered for a given recipient. All fields optional:
 * a channel sender simply no-ops when the contact it needs is absent.
 *
 * [devices] are the recipient's registered push targets, resolved by
 * [NotificationPublisher] from the recipient's [DeviceToken] feed when the PUSH channel is
 * requested — so push senders stay pure transports (no persistence access).
 */
data class NotificationContact(
    val email: String? = null,
    val devices: List<DeviceToken> = emptyList(),
    /**
     * Name of the AMAP the notification belongs to, used to prefix the email subject
     * (`[Name] …`). Null for instance-level notifications with no owning AMAP.
     */
    val organizationName: String? = null,
)

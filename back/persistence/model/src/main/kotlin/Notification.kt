@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * A user-facing notification, materialised as a first-class synced entity on the
 * recipient's private scope (see ADR-005).
 *
 * Notifications are server-authoritative: a domain mutation's side-effect creates the
 * row and its scope [persistence.changes.Change] atomically. The client only ever
 * mutates [readAt] (mark read) or deletes the row (archive) through `POST /v1/sync`.
 *
 * [recipientScope] is the private scope key the notification belongs to —
 * `member:{sub}`, `owner:{sub}`, and `producer-account:{id}` are all active now.
 * A single [Notification] type serves every recipient kind; the difference is carried
 * by [recipientScope] + [category].
 */
@Serializable
data class Notification(
    @SerialName("notification_id") val notificationId: Id<Notification>,
    @SerialName("recipient_scope") val recipientScope: String,
    val type: NotificationType,
    val category: NotificationCategory,
    val title: String,
    val body: String,
    @SerialName("deep_link") val deepLink: String? = null,
    @SerialName("related_entity_id") val relatedEntityId: String? = null,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("read_at") val readAt: Instant? = null,
)

/** Severity / intent of a [Notification]. Drives client styling and ordering. */
@Serializable
enum class NotificationType {
    ALERT,
    REMINDER,
    INFO,
    URGENT,
}

/**
 * Business origin of a [Notification]. Lets the client group/filter and lets the
 * transport layer pick a per-category template. Extend as new event producers are wired.
 */
@Serializable
enum class NotificationCategory {
    GENERIC,
    BASKET_EXCHANGE_REQUEST_RECEIVED,
    BASKET_EXCHANGE_ACCEPTED,
    BASKET_EXCHANGE_REJECTED,
    ORGANIZATION_REQUEST_SUBMITTED,
    PRODUCER_REQUEST_SUBMITTED,
    MEMBER_JOIN_REQUEST_SUBMITTED,
    DELIVERY_REMINDER,
    SLOT_CANCELLED,
    SLOT_RESCHEDULED,
}

/**
 * Outbound transport channel for a notification. The in-app feed always exists (it is
 * the synced [Notification] itself); these are the *additional* push transports a
 * recipient may opt into via their preferences.
 */
@Serializable
enum class NotificationChannel {
    EMAIL,
    PUSH,
}

/**
 * Admin-authored override of the title/body used for a given [NotificationCategory]
 * within an organization (see `Organization.notificationOverrides`). Either field may be
 * null/blank, in which case the hardcoded default copy is used for that part. The override
 * is applied verbatim — no variable interpolation.
 */
@Serializable
data class NotificationCopyOverride(
    val title: String? = null,
    val body: String? = null,
)

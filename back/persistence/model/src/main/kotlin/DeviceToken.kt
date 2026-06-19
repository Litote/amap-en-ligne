@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * A push-capable device registered for a recipient, materialised as a first-class synced
 * entity on the recipient's private scope (see ADR-005).
 *
 * The client owns its device tokens: it upserts one when it obtains/refreshes a push
 * registration token and deletes it on logout. The server reads them to fan a
 * [Notification] out to the recipient's devices over the PUSH channel — SNS Mobile Push
 * (Lambda) or FCM HTTP v1 (JVM).
 *
 * [recipientScope] is the private scope key the token belongs to — `member:{sub}`,
 * `owner:{sub}`, or `producer-account:{id}` — the same family as [Notification].
 */
@Serializable
data class DeviceToken(
    @SerialName("device_token_id") val deviceTokenId: Id<DeviceToken>,
    @SerialName("recipient_scope") val recipientScope: String,
    val platform: DevicePlatform,
    val token: String,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("last_seen_at") val lastSeenAt: Instant,
)

/** Platform a [DeviceToken] was issued for. Drives the push payload shape. */
@Serializable
enum class DevicePlatform {
    ANDROID,
    IOS,
    WEB,
}

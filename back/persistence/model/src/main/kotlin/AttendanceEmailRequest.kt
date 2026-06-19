@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * An audit record of an attendance email sent by a coordinator for a delivery.
 *
 * Scope: organization:{organizationId}
 *
 * The entity is created by the client with a tmp_* id and a null [sentAt].
 * The server sets [sentAt] to the current time on apply.
 */
@Serializable
data class AttendanceEmailRequest(
    @SerialName("attendance_email_request_id") val attendanceEmailRequestId: Id<AttendanceEmailRequest>,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("delivery_id") val deliveryId: String,
    @SerialName("recipient_email") val recipientEmail: String,
    @SerialName("requested_at") val requestedAt: Instant,
    @SerialName("sent_at") val sentAt: Instant? = null,
)

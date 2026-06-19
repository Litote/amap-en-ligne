@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class OwnerInvitationStatus {
    PENDING_ACTIVATION,
    ACTIVATED,
    CANCELLED,
}

@Serializable
data class OwnerInvitation(
    @SerialName("invitation_id") val invitationId: Id<OwnerInvitation>,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val email: String,
    val status: OwnerInvitationStatus,
    @SerialName("submitted_at") val submittedAt: Instant,
    @SerialName("resend_requested_at") val resendRequestedAt: Instant? = null,
    @SerialName("activated_at") val activatedAt: Instant? = null,
)

@Serializable
data class CreateOwnerInvitationBody(
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val email: String,
)

@Serializable
data class OwnerInvitationCreated(
    @SerialName("invitation_id") val invitationId: Id<OwnerInvitation>,
    val status: OwnerInvitationStatus,
)

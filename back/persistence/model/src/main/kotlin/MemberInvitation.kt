@file:OptIn(ExperimentalTime::class)

package persistence.model

import authentication.Role
import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class MemberInvitationStatus {
    PENDING_ACTIVATION,
    ACTIVATED,
    CANCELLED,
}

@Serializable
data class MemberInvitation(
    @SerialName("invitation_id") val invitationId: String,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val email: String,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val roles: Set<Role>,
    val status: MemberInvitationStatus,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("expires_at") val expiresAt: Instant,
    @SerialName("resend_requested_at") val resendRequestedAt: Instant? = null,
    @SerialName("activated_at") val activatedAt: Instant? = null,
    // Optional admin-authored overrides of the invitation email's subject / intro body.
    // When set they replace the default copy; the activation link footer + signature are
    // always appended server-side (see EmailTemplates.memberInvitation). Null ⇒ default copy.
    @SerialName("custom_email_subject") val customEmailSubject: String? = null,
    @SerialName("custom_email_body") val customEmailBody: String? = null,
)

@Serializable
data class InviteMemberBody(
    val email: String,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val roles: Set<Role>,
)

@Serializable
data class MemberInvitationCreated(
    @SerialName("invitation_id") val invitationId: String,
    val status: MemberInvitationStatus = MemberInvitationStatus.PENDING_ACTIVATION,
)

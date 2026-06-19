@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class ActivationKind {
    ORGANIZATION_ADMIN,
    PRODUCER,
    OWNER,
    MEMBER,
}

@Serializable
data class ActivationToken(
    val token: String,
    val kind: ActivationKind = ActivationKind.ORGANIZATION_ADMIN,
    @SerialName("request_id") val requestId: Id<OrganizationRequest>? = null,
    @SerialName("producer_request_id") val producerRequestId: Id<ProducerRequest>? = null,
    @SerialName("admin_email") val adminEmail: String,
    @SerialName("organization_id") val organizationId: Id<Organization>? = null,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>? = null,
    @SerialName("owner_invitation_id") val ownerInvitationId: Id<OwnerInvitation>? = null,
    @SerialName("member_invitation_id") val memberInvitationId: Id<MemberInvitation>? = null,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("expires_at") val expiresAt: Instant,
    @SerialName("invalidated_at") val invalidatedAt: Instant? = null,
    @SerialName("activated_at") val activatedAt: Instant? = null,
)

@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
data class MemberJoinRequest(
    @SerialName("request_id") val requestId: Id<MemberJoinRequest>,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val email: String,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val status: MemberJoinRequestStatus,
    @SerialName("submitted_at") val submittedAt: Instant,
    @SerialName("reviewed_at") val reviewedAt: Instant? = null,
    @SerialName("review_comment") val reviewComment: String? = null,
)

@Serializable
enum class MemberJoinRequestStatus {
    PENDING,
    APPROVED,
    REJECTED,
}

@Serializable
data class CreateMemberJoinRequestBody(
    @SerialName("organization_id") val organizationId: String,
    val email: String,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
)

@Serializable
data class MemberJoinRequestCreated(
    @SerialName("request_id") val requestId: Id<MemberJoinRequest>,
    val status: MemberJoinRequestStatus,
)

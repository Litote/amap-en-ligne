@file:OptIn(ExperimentalTime::class)

package persistence.model

import i18n.Language
import id.Id
import kotlinx.datetime.TimeZone
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class OrganizationType {
    AMAP,
    PRODUCER,
}

@Serializable
data class OrganizationRequest(
    @SerialName("request_id") val requestId: Id<OrganizationRequest>,
    @SerialName("organization_name") val organizationName: String,
    @SerialName("organization_type") val organizationType: OrganizationType,
    val timezone: TimeZone,
    @SerialName("default_language") val defaultLanguage: Language,
    @SerialName("admin_first_name") val adminFirstName: String,
    @SerialName("admin_last_name") val adminLastName: String,
    @SerialName("admin_email") val adminEmail: String,
    val status: OrganizationRequestStatus,
    @SerialName("submitted_at") val submittedAt: Instant,
    @SerialName("reviewed_at") val reviewedAt: Instant? = null,
    @SerialName("review_comment") val reviewComment: String? = null,
    @SerialName("submitter_comment") val submitterComment: String? = null,
    @SerialName("organization_id") val organizationId: Id<Organization>? = null,
    @SerialName("resend_requested_at") val resendRequestedAt: Instant? = null,
)

@Serializable
enum class OrganizationRequestStatus {
    PENDING_VALIDATION,
    APPROVED,
    REJECTED,
}

@Serializable
data class CreateOrganizationRequestBody(
    @SerialName("organization_name") val organizationName: String,
    @SerialName("organization_type") val organizationType: OrganizationType,
    val timezone: TimeZone,
    @SerialName("default_language") val defaultLanguage: Language,
    @SerialName("admin_first_name") val adminFirstName: String,
    @SerialName("admin_last_name") val adminLastName: String,
    @SerialName("admin_email") val adminEmail: String,
    @SerialName("submitter_comment") val submitterComment: String? = null,
)

@Serializable
data class OrganizationRequestCreated(
    @SerialName("request_id") val requestId: Id<OrganizationRequest>,
    val status: OrganizationRequestStatus,
)

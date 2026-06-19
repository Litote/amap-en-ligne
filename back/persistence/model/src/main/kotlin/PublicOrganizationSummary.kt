package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PublicOrganizationSummary(
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val name: String,
    @SerialName("contact_email") val contactEmail: String,
    @SerialName("active_status") val activeStatus: Boolean,
)

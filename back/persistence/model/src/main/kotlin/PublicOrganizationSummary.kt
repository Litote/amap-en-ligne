package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Organization entry served by the unauthenticated `GET /v1/public/organizations`.
 * Deliberately carries no contact email: that endpoint is world-readable.
 */
@Serializable
data class PublicOrganizationSummary(
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val name: String,
    @SerialName("active_status") val activeStatus: Boolean,
)

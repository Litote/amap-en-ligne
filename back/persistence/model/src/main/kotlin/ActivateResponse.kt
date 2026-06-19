package persistence.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ActivateResponse(
    val kind: ActivationKind,
    @SerialName("organization_name") val organizationName: String? = null,
    val email: String,
)

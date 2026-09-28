package instanceconfig

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@SerialName("gotrue")
data class GoTrueInstanceAuthConfig(
    @SerialName("base_url") val baseUrl: String,
) : InstanceAuthConfig

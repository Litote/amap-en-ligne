package instanceconfig

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@SerialName("cognito")
data class CognitoInstanceAuthConfig(
    @SerialName("issuer_url") val issuerUrl: String,
    @SerialName("client_id") val clientId: String,
) : InstanceAuthConfig

@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package instanceconfig

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonClassDiscriminator

/**
 * Public metadata an instance exposes in its discovery document at
 * GET /.well-known/amap-en-ligne.json. Contains only non-secret,
 * client-bootstrap data — never secrets or internal config.
 */
@Serializable
data class InstanceConfig(
    val name: String,
    @SerialName("api_url") val apiUrl: String,
    val visible: Boolean,
    @SerialName("protocol_version") val protocolVersion: String,
    @SerialName("terms_url") val termsUrl: String? = null,
    val auth: InstanceAuthConfig,
)

/**
 * Auth provider configuration embedded in the discovery document.
 * Discriminator key is "kind" (lowercase) to follow REST conventions.
 *
 * Concrete variants are contributed by adapter modules:
 *  - `lib:instance-config-gotrue` provides the GoTrue variant.
 *  - `lib:instance-config-cognito` provides the Cognito variant.
 *
 * Each adapter also registers its subtype on the polymorphic serializer via
 * [InstanceAuthConfigSerializers] so that the active deploy can serialize its
 * own variant on the discovery endpoint.
 */
@JsonClassDiscriminator("kind")
interface InstanceAuthConfig

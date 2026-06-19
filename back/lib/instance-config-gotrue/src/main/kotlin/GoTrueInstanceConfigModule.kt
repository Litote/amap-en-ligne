package instanceconfig

import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single
import properties.Properties

/**
 * Wires [InstanceConfig] for the JVM / GoTrue deployment.
 * Reuses GOTRUE_JWT_ISSUER as the public auth base URL since
 * it is already required for token verification.
 *
 * Required env vars: INSTANCE_NAME, INSTANCE_API_URL, GOTRUE_JWT_ISSUER.
 * Optional: INSTANCE_VISIBLE (default true), INSTANCE_TERMS_URL.
 */
@Module
class GoTrueInstanceConfigModule {
    @Single(createdAtStart = true)
    fun instanceConfig(): InstanceConfig =
        InstanceConfig(
            name = Properties.Instance.propertyOrFail("INSTANCE_NAME"),
            apiUrl = Properties.Instance.propertyOrFail("INSTANCE_API_URL"),
            visible = Properties.Instance.booleanProperty("INSTANCE_VISIBLE", true),
            protocolVersion = "1",
            termsUrl = Properties.Instance.propertyOrNull("INSTANCE_TERMS_URL"),
            auth =
                GoTrueInstanceAuthConfig(
                    baseUrl = Properties.Instance.propertyOrFail("GOTRUE_JWT_ISSUER"),
                ),
        )

    @Single
    fun instanceAuthConfigSerializers(): InstanceAuthConfigSerializers =
        InstanceAuthConfigSerializers(
            SerializersModule {
                polymorphic(InstanceAuthConfig::class) {
                    subclass(GoTrueInstanceAuthConfig::class, GoTrueInstanceAuthConfig.serializer())
                }
            },
        )
}

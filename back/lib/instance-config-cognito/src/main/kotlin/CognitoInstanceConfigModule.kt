package instanceconfig

import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single
import properties.Properties

/**
 * Wires [InstanceConfig] for the Lambda / Cognito deployment.
 *
 * Required env vars: INSTANCE_NAME, INSTANCE_API_URL,
 *   COGNITO_ISSUER_URL, COGNITO_CLIENT_ID.
 * Optional: INSTANCE_VISIBLE (default true), INSTANCE_TERMS_URL.
 */
@Module
class CognitoInstanceConfigModule {
    @Single(createdAtStart = true)
    fun instanceConfig(): InstanceConfig =
        InstanceConfig(
            name = Properties.Instance.propertyOrFail("INSTANCE_NAME"),
            apiUrl = Properties.Instance.propertyOrFail("INSTANCE_API_URL"),
            visible = Properties.Instance.booleanProperty("INSTANCE_VISIBLE", true),
            protocolVersion = "1",
            termsUrl = Properties.Instance.propertyOrNull("INSTANCE_TERMS_URL"),
            auth =
                CognitoInstanceAuthConfig(
                    issuerUrl = Properties.Instance.propertyOrFail("COGNITO_ISSUER_URL"),
                    clientId = Properties.Instance.propertyOrFail("COGNITO_CLIENT_ID"),
                ),
        )

    @Single
    fun instanceAuthConfigSerializers(): InstanceAuthConfigSerializers =
        InstanceAuthConfigSerializers(
            SerializersModule {
                polymorphic(InstanceAuthConfig::class) {
                    subclass(CognitoInstanceAuthConfig::class, CognitoInstanceAuthConfig.serializer())
                }
            },
        )
}

package provisioning.cognito

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single
import properties.Properties

/**
 * Koin module collecting the Cognito auth-provisioning adapters (user lifecycle
 * + role provisioning) for the Lambda deployment. Included from the Lambda bootstrap.
 */
@Module
@ComponentScan
class ProvisioningCognitoModule {
    /**
     * The shared Cognito SDK client, provided here (rather than built inside each adapter)
     * so adapters take it as a constructor dependency and stay unit-testable with a mock.
     */
    @Single
    fun cognitoIdentityProviderClient(properties: Properties): CognitoIdentityProviderClient =
        CognitoIdentityProviderClient {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }
}

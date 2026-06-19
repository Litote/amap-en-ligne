package authentication

import org.koin.core.annotation.Module
import org.koin.core.annotation.Single

/**
 * Koin module wiring the Cognito-backed [AuthenticationService]. Loaded by the Lambda deployment.
 */
@Module
class CognitoAuthenticationModule {
    @Single(createdAtStart = true)
    fun authenticationService(): AuthenticationService = CognitoAuthenticationService()
}

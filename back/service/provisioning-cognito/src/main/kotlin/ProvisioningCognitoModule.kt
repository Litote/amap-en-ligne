package provisioning.cognito

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

/**
 * Koin module collecting the Cognito auth-provisioning adapters (user lifecycle
 * + role provisioning) for the Lambda deployment. Included from the Lambda bootstrap.
 */
@Module
@ComponentScan
class ProvisioningCognitoModule

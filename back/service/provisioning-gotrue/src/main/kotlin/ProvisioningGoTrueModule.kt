package provisioning.gotrue

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

/**
 * Koin module collecting the GoTrue auth-provisioning adapters (user lifecycle
 * + role provisioning) for the JVM deployment. Included from the JVM bootstrap.
 */
@Module
@ComponentScan
class ProvisioningGoTrueModule

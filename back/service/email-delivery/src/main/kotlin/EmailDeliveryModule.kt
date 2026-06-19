package email.delivery

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

/**
 * Koin module collecting the deployment-agnostic email-port adapters. Each
 * deployment provides the concrete [EmailGateway] and includes this module so
 * the adapters bind to their respective `*EmailPort` interfaces.
 */
@Module
@ComponentScan
class EmailDeliveryModule

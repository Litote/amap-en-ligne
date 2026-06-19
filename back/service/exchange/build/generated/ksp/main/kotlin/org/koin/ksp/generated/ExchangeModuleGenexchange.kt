package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val exchange_ExchangeModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> exchange.BasketExchangeService(basketExchangeSyncDAO=get(),organizationSyncDAO=get(),memberSyncDAO=get(),contractSyncDAO=get(),requestReceivedEmailPort=get(),acceptedEmailPort=get(),rejectedEmailPort=get(),notificationPublisher=get())} bind(core.EntityTypeService::class)
}
public val exchange.ExchangeModule.module : org.koin.core.module.Module get() = exchange_ExchangeModule

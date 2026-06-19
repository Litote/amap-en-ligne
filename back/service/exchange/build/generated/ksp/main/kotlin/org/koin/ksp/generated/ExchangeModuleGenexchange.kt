package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val exchange_ExchangeModule : Module get() = module {
	includes(core.CoreModule().module)
	single() { _ -> exchange.BasketExchangeCommitmentValidator(contractSyncDAO=get())} 
	single() { _ -> exchange.BasketExchangeNotifier(notificationPublisher=get())} 
	single(createdAtStart=true) { _ -> exchange.BasketExchangeService(basketExchangeSyncDAO=get(),organizationSyncDAO=get(),memberSyncDAO=get(),requestReceivedEmailPort=get(),acceptedEmailPort=get(),rejectedEmailPort=get(),notifier=get(),commitmentValidator=get())} bind(core.EntityTypeService::class)
}
public val exchange.ExchangeModule.module : org.koin.core.module.Module get() = exchange_ExchangeModule

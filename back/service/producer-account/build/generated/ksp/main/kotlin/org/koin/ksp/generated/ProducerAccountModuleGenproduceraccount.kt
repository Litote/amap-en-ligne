package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val produceraccount_ProducerAccountModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> produceraccount.ProducerAccountService(producerAccountSyncDAO=get(),organizationSyncDAO=get(),userProvisioningPort=get(),accountLifecycleEmailPort=get(),accountDeletionLogDAO=get())} bind(core.EntityTypeService::class)
}
public val produceraccount.ProducerAccountModule.module : org.koin.core.module.Module get() = produceraccount_ProducerAccountModule

package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val producer_ProducerModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> producer.ProducerService(producerSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val producer.ProducerModule.module : org.koin.core.module.Module get() = producer_ProducerModule

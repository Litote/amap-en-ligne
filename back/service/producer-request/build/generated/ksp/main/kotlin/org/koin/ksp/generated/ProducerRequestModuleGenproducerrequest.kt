package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val producerrequest_ProducerRequestModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> producerrequest.ProducerRequestService(producerRequestSyncDAO=get(),producerRequestDAO=get(),producerAccountSyncDAO=get(),activationTokenDAO=get(),producerActivationEmailPort=get(),producerRequestRejectionEmailPort=get())} bind(core.EntityTypeService::class)
}
public val producerrequest.ProducerRequestModule.module : org.koin.core.module.Module get() = producerrequest_ProducerRequestModule

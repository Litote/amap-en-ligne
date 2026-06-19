package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val activation_ActivationModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> activation.ActivationService(activationTokenDAO=get(),organizationRequestDAO=get(),producerRequestDAO=get(),organizationSyncDAO=get(),serverDAO=get(),producerAccountSyncDAO=get(),producerSyncDAO=get(),userProvisioningPort=get(),memberInvitationDAO=get(),memberSyncDAO=get(),ownerInvitationDAO=get(),ownerDAO=get())} 
}
public val activation.ActivationModule.module : org.koin.core.module.Module get() = activation_ActivationModule

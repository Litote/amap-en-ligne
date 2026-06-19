package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val owner_OwnerModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> owner.OwnerInvitationService(ownerInvitationDAO=get(),ownerDAO=get(),activationTokenDAO=get(),ownerActivationEmailPort=get())} bind(core.EntityTypeService::class)
	single(createdAtStart=true) { _ -> owner.OwnerService(ownerDAO=get(),roleService=get(),userProvisioningPort=get(),accountLifecycleEmailPort=get(),accountDeletionLogDAO=get())} 
	single(createdAtStart=true) { _ -> owner.OwnerTypeService(ownerDAO=get(),memberSyncDAO=get(),roleService=get(),ownerService=get(),roleProvisioningPort=getOrNull())} bind(core.EntityTypeService::class)
}
public val owner.OwnerModule.module : org.koin.core.module.Module get() = owner_OwnerModule

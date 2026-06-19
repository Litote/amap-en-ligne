package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val core_CoreModule : Module get() = module {
	includes(notificationpublisher.NotificationPublisherModule().module)
	single(createdAtStart=true) { _ -> core.AuthorizedScopeResolver(memberSyncDAO=get(),producerSyncDAO=get())} 
	single(createdAtStart=true) { _ -> core.RoleService(ownerDAO=get(),userProvisioningPort=get())} 
}
public val core.CoreModule.module : org.koin.core.module.Module get() = core_CoreModule

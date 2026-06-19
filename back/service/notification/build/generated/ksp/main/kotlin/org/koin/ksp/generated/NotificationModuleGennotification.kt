package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val notification_NotificationModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> notification.DeviceTokenService(deviceTokenSyncDAO=get(),authorizedScopeResolver=get())} bind(core.EntityTypeService::class)
	single(createdAtStart=true) { _ -> notification.NotificationService(notificationSyncDAO=get(),authorizedScopeResolver=get())} bind(core.EntityTypeService::class)
}
public val notification.NotificationModule.module : org.koin.core.module.Module get() = notification_NotificationModule

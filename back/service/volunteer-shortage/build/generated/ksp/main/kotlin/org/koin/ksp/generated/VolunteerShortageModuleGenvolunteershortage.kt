package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val volunteershortage_VolunteerShortageModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> volunteershortage.VolunteerShortageService(organizationSyncDAO=get(),contractSyncDAO=get(),memberSyncDAO=get(),memberInvitationSyncDAO=get(),sentAlertDAO=get(),notificationPublisher=get())} 
}
public val volunteershortage.VolunteerShortageModule.module : org.koin.core.module.Module get() = volunteershortage_VolunteerShortageModule

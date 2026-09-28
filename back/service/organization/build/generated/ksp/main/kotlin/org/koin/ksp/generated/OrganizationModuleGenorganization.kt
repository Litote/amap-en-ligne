package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val organization_OrganizationModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> organization.OrganizationService(organizationSyncDAO=get(),deliveryTemplateSyncDAO=get(),producerAccountSyncDAO=get(),memberSyncDAO=get(),notificationPublisher=get(),contractSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val organization.OrganizationModule.module : org.koin.core.module.Module get() = organization_OrganizationModule

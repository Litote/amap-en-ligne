package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val organizationrequest_OrganizationRequestModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> organizationrequest.OrganizationRequestService(organizationRequestSyncDAO=get(),organizationRequestDAO=get(),organizationDAO=get(),activationTokenDAO=get(),activationEmailPort=get(),rejectionEmailPort=get())} bind(core.EntityTypeService::class)
}
public val organizationrequest.OrganizationRequestModule.module : org.koin.core.module.Module get() = organizationrequest_OrganizationRequestModule

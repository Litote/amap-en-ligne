package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val memberjoinrequest_MemberJoinRequestModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> memberjoinrequest.MemberJoinRequestService(memberJoinRequestSyncDAO=get(),memberJoinRequestDAO=get(),memberSyncDAO=get(),memberInvitationDAO=get(),activationTokenDAO=get(),memberInvitationEmailPort=get(),rejectionEmailPort=get(),organizationSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val memberjoinrequest.MemberJoinRequestModule.module : org.koin.core.module.Module get() = memberjoinrequest_MemberJoinRequestModule

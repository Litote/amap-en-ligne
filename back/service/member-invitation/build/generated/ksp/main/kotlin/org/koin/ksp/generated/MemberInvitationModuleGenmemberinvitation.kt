package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val memberinvitation_MemberInvitationModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> memberinvitation.MemberInvitationService(memberInvitationDAO=get(),memberSyncDAO=get(),activationTokenDAO=get(),memberInvitationEmailPort=get(),organizationSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val memberinvitation.MemberInvitationModule.module : org.koin.core.module.Module get() = memberinvitation_MemberInvitationModule

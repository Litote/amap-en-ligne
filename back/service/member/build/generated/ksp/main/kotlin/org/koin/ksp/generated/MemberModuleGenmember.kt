package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val member_MemberModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> member.MemberService(memberSyncDAO=get(),roleService=get(),roleProvisioningPort=getOrNull(),userProvisioningPort=get(),accountLifecycleEmailPort=get(),accountDeletionLogDAO=get(),contractSyncDAO=get(),organizationSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val member.MemberModule.module : org.koin.core.module.Module get() = member_MemberModule

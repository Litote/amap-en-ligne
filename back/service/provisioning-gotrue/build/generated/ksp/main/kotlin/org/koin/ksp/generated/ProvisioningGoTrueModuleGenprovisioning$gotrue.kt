package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val provisioning_gotrue_ProvisioningGoTrueModule : Module get() = module {
	single(createdAtStart=true) { _ -> provisioning.gotrue.GoTrueMemberRoleProvisioningAdapter(properties=get())} bind(core.MemberRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.gotrue.GoTrueOwnerRoleProvisioningAdapter(properties=get())} bind(core.OwnerRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.gotrue.GoTrueUserProvisioningAdapter(properties=get())} bind(core.UserProvisioningPort::class)
}
public val provisioning.gotrue.ProvisioningGoTrueModule.module : org.koin.core.module.Module get() = provisioning_gotrue_ProvisioningGoTrueModule

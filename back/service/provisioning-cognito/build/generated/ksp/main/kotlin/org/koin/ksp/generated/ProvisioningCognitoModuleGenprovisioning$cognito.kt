package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val provisioning_cognito_ProvisioningCognitoModule : Module get() = module {
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoMemberRoleProvisioningAdapter(properties=get())} bind(core.MemberRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoOwnerRoleProvisioningAdapter(properties=get())} bind(core.OwnerRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoUserProvisioningAdapter(properties=get())} bind(core.UserProvisioningPort::class)
}
public val provisioning.cognito.ProvisioningCognitoModule.module : org.koin.core.module.Module get() = provisioning_cognito_ProvisioningCognitoModule

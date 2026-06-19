package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val provisioning_cognito_ProvisioningCognitoModule : Module get() = module {
	val moduleInstance = provisioning.cognito.ProvisioningCognitoModule()
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoMemberRoleProvisioningAdapter(properties=get())} bind(core.MemberRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoOwnerRoleProvisioningAdapter(properties=get())} bind(core.OwnerRoleProvisioningPort::class)
	single(createdAtStart=true) { _ -> provisioning.cognito.CognitoUserProvisioningAdapter(properties=get(),cognitoClient=get())} bind(core.UserProvisioningPort::class)
	single() { _ -> moduleInstance.cognitoIdentityProviderClient(properties=get())} bind(aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient::class)
}
public val provisioning.cognito.ProvisioningCognitoModule.module : org.koin.core.module.Module get() = provisioning_cognito_ProvisioningCognitoModule

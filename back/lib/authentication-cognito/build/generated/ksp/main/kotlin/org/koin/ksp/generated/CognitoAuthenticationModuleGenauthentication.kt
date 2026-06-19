package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val authentication_CognitoAuthenticationModule : Module get() = module {
	val moduleInstance = authentication.CognitoAuthenticationModule()
	single(createdAtStart=true) { _ -> moduleInstance.authenticationService()} bind(authentication.AuthenticationService::class)
}
public val authentication.CognitoAuthenticationModule.module : org.koin.core.module.Module get() = authentication_CognitoAuthenticationModule

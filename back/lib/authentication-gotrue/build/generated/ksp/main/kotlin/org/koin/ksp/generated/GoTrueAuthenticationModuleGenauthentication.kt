package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val authentication_GoTrueAuthenticationModule : Module get() = module {
	val moduleInstance = authentication.GoTrueAuthenticationModule()
	single(createdAtStart=true) { _ -> moduleInstance.authenticationService()} bind(authentication.AuthenticationService::class)
}
public val authentication.GoTrueAuthenticationModule.module : org.koin.core.module.Module get() = authentication_GoTrueAuthenticationModule

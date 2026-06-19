package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val http_HttpModule : Module get() = module {
	single(createdAtStart=true) { _ -> http.HttpService()} 
}
public val http.HttpModule.module : org.koin.core.module.Module get() = http_HttpModule

package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val properties_PropertiesModule : Module get() = module {
	single(createdAtStart=true) { _ -> properties.PropertiesService()} bind(properties.Properties::class)
}
public val properties.PropertiesModule.module : org.koin.core.module.Module get() = properties_PropertiesModule

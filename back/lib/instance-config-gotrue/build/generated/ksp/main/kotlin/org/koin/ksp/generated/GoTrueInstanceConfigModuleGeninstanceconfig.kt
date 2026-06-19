package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val instanceconfig_GoTrueInstanceConfigModule : Module get() = module {
	val moduleInstance = instanceconfig.GoTrueInstanceConfigModule()
	single() { _ -> moduleInstance.instanceAuthConfigSerializers()} bind(instanceconfig.InstanceAuthConfigSerializers::class)
	single(createdAtStart=true) { _ -> moduleInstance.instanceConfig()} bind(instanceconfig.InstanceConfig::class)
}
public val instanceconfig.GoTrueInstanceConfigModule.module : org.koin.core.module.Module get() = instanceconfig_GoTrueInstanceConfigModule

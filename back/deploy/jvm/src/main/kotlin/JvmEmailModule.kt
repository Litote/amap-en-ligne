package deploy.jvm

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import persistence.postgres.PostgresModule
import properties.PropertiesModule

@Module(includes = [PropertiesModule::class, PostgresModule::class])
@ComponentScan("deploy.jvm")
class JvmEmailModule

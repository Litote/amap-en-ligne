package properties

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single

@Module
@ComponentScan
class PropertiesModule

@Single(createdAtStart = true)
class PropertiesService : Properties

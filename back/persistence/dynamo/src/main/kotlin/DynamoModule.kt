package persistence.dynamo

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single
import properties.Properties
import properties.PropertiesModule

@Module(includes = [PropertiesModule::class])
@ComponentScan
class DynamoModule {
    @Single(createdAtStart = true)
    internal fun dynamoClient(properties: Properties): DynamoClient = DynamoClient(properties)
}

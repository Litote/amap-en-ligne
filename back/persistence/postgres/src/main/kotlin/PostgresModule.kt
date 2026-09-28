package persistence.postgres

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single
import properties.Properties
import properties.PropertiesModule
import javax.sql.DataSource

@Module(includes = [PropertiesModule::class])
@ComponentScan
class PostgresModule {
    @Single(createdAtStart = true)
    internal fun postgresClient(properties: Properties): PostgresClient = PostgresClient(properties)

    @Single(createdAtStart = true)
    internal fun dataSource(postgresClient: PostgresClient): DataSource = postgresClient.dataSource
}

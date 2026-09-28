package persistence.postgres

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.flywaydb.core.Flyway
import properties.Properties
import javax.sql.DataSource

internal class PostgresClient(
    properties: Properties,
) {
    val dataSource: DataSource = createDataSource(properties)

    init {
        Flyway
            .configure()
            .dataSource(dataSource)
            .locations("classpath:db/migration")
            .load()
            .migrate()
    }

    private companion object {
        fun createDataSource(properties: Properties): HikariDataSource {
            val config =
                HikariConfig().apply {
                    jdbcUrl = properties.property("POSTGRES_URL", "jdbc:postgresql://127.0.0.1:5432/postgres")
                    username = properties.property("POSTGRES_USER", "postgres")
                    // No default on purpose: a misconfigured deployment must fail at startup
                    // rather than silently connect with weak credentials.
                    password = properties.propertyOrFail("POSTGRES_PASSWORD")
                    maximumPoolSize = properties.intProperty("POSTGRES_POOL_MAX", 10)
                    driverClassName = "org.postgresql.Driver"
                }
            return HikariDataSource(config)
        }
    }
}

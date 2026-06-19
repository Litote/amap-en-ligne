package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ServerDAO
import persistence.dao.ServerDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ServerPostgresDAOTest : ServerDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val dao: ServerDAO by lazy { ServerPostgresDAO(postgresClient) }

    @BeforeAll
    fun setUp() {
        container.start()
        val properties =
            object : Properties {
                override fun propertyOrNull(name: String): String? =
                    when (name) {
                        "POSTGRES_URL" -> container.jdbcUrl
                        "POSTGRES_USER" -> container.username
                        "POSTGRES_PASSWORD" -> container.password
                        else -> null
                    }
            }
        postgresClient = PostgresClient(properties)
    }

    @AfterAll
    fun tearDown() {
        container.stop()
    }

    override fun insertServer(
        id: String,
        name: String,
        url: String,
    ) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement("INSERT INTO server(server_id, name, url) VALUES (?, ?, ?)")
                .use { stmt ->
                    stmt.setString(1, id)
                    stmt.setString(2, name)
                    stmt.setString(3, url)
                    stmt.executeUpdate()
                }
        }
    }

    override fun clearAll() {
        postgresClient.dataSource.connection.use { conn ->
            conn.createStatement().use { it.execute("TRUNCATE server") }
        }
    }
}

package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationPostgresDAOTest : OrganizationDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val dao: OrganizationDAO by lazy { OrganizationPostgresDAO(postgresClient) }

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

    override fun insertOrganization(
        id: String,
        name: String,
        email: String,
        active: Boolean,
    ) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    "INSERT INTO organization(organization_id, name, contact_email, active_status) VALUES (?, ?, ?, ?)",
                ).use { stmt ->
                    stmt.setString(1, id)
                    stmt.setString(2, name)
                    stmt.setString(3, email)
                    stmt.setBoolean(4, active)
                    stmt.executeUpdate()
                }
        }
    }
}

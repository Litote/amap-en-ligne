package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.dao.OrganizationRequestSyncDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationRequestSyncPostgresDAOTest : OrganizationRequestSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val organizationRequestSyncDAO: OrganizationRequestSyncDAO by lazy {
        OrganizationRequestSyncPostgresDAO(postgresClient)
    }
    override val changeDAO: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

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

    override fun clearAll() {
        postgresClient.dataSource.connection.use { conn ->
            conn.createStatement().use {
                it.execute("TRUNCATE activation_token, organization_request CASCADE")
                it.execute("DELETE FROM changes WHERE entity_type = 'OrganizationRequest'")
            }
        }
    }
}

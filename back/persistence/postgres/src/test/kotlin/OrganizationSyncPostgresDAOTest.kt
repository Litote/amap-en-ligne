package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OrganizationSyncDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationSyncPostgresDAOTest : OrganizationSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val organizationSyncDAO: OrganizationSyncDAO by lazy { OrganizationSyncPostgresDAO(postgresClient) }
    override val changeDAO: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

    override fun insertProducerAccount(producerAccountId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_account (producer_account_id, name, active_status, created_instant, last_updated_instant)
                    VALUES (?, 'Test Producer', true, 0, 0)
                    ON CONFLICT (producer_account_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccountId)
                    stmt.executeUpdate()
                }
        }
    }

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
}

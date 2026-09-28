package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.NotificationSyncDAO
import persistence.dao.NotificationSyncDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class NotificationSyncPostgresDAOTest : NotificationSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val notificationSyncDAO: NotificationSyncDAO by lazy { NotificationSyncPostgresDAO(postgresClient) }
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
}

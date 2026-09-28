package persistence.postgres

import id.toId
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.ProducerSyncDAO
import persistence.dao.ProducerSyncDAOContractTest
import persistence.model.UserSettings
import properties.Properties
import kotlin.time.Instant

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProducerSyncPostgresDAOTest : ProducerSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val producerSyncDAO: ProducerSyncDAO by lazy { ProducerSyncPostgresDAO(postgresClient) }
    override val changeDAO: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

    override fun buildTestUserSettings(now: Instant): UserSettings =
        UserSettings(
            language = "fr",
            timezone = TimeZone.of("Europe/Paris"),
            serverId = "server-1".toId(),
            lastUpdatedInstant = now,
        )

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
        insertServer()
    }

    @AfterAll
    fun tearDown() {
        container.stop()
    }

    private fun insertServer() {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO server (server_id, name, url)
                    VALUES ('server-1', 'Test Server', 'https://test.example.com/')
                    ON CONFLICT (server_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeUpdate()
                }
        }
    }
}

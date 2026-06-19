package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.dao.AttendanceEmailRequestSyncDAOContractTest
import persistence.dao.ChangeDAO
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class AttendanceEmailRequestSyncPostgresDAOTest : AttendanceEmailRequestSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val attendanceEmailRequestSyncDAO: AttendanceEmailRequestSyncDAO by lazy {
        AttendanceEmailRequestSyncPostgresDAO(
            postgresClient,
        )
    }
    override val changeDAO: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

    override fun insertOrganization(organizationId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization (organization_id, name, contact_email, active_status)
                    VALUES (?, 'Test Org', 'test@example.com', true)
                    ON CONFLICT (organization_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId)
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

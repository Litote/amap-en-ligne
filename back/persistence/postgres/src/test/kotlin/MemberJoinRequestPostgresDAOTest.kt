package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MemberJoinRequestPostgresDAOTest : MemberJoinRequestDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val dao: MemberJoinRequestDAO by lazy { MemberJoinRequestPostgresDAO(postgresClient) }

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
            conn.createStatement().use { it.execute("TRUNCATE member_join_request, organization CASCADE") }
        }
    }

    override fun ensureOrganizationExists(organizationId: String) {
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
}

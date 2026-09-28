package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberJoinRequestSyncDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MemberJoinRequestSyncPostgresDAOTest : MemberJoinRequestSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO by lazy {
        MemberJoinRequestSyncPostgresDAO(postgresClient)
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
                it.execute("TRUNCATE member_join_request, organization CASCADE")
                it.execute("DELETE FROM changes WHERE entity_type = 'MemberJoinRequest'")
            }
        }
    }

    override fun ensureOrganizationExists(organizationId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization (
                        organization_id, name, contact_email, active_status, timezone, default_language, created_instant, last_updated_instant
                    ) VALUES (?, ?, ?, TRUE, 'Europe/Paris', 'fr', 0, 0)
                    ON CONFLICT (organization_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId)
                    stmt.setString(2, "Org $organizationId")
                    stmt.setString(3, "$organizationId@example.com")
                    stmt.executeUpdate()
                }
        }
    }
}

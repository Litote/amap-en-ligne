package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ActivationTokenDAO
import persistence.dao.ActivationTokenDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ActivationTokenPostgresDAOTest : ActivationTokenDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val dao: ActivationTokenDAO by lazy { ActivationTokenPostgresDAO(postgresClient) }

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

    override fun insertOrganization(organizationId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization(organization_id, name, contact_email, active_status)
                    VALUES (?, 'Test Org', 'test@example.com', true)
                    ON CONFLICT (organization_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId)
                    stmt.executeUpdate()
                }
        }
    }

    override fun insertProducerAccount(producerAccountId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_account(producer_account_id, name, contact_email, active_status, created_instant, last_updated_instant)
                    VALUES (?, 'Test Producer', 'producer@example.com', true, 0, 0)
                    ON CONFLICT (producer_account_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccountId)
                    stmt.executeUpdate()
                }
        }
    }

    override fun insertOwnerInvitation(invitationId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO owner_invitation(invitation_id, first_name, last_name, email, status, submitted_at)
                    VALUES (?, 'Test', 'Owner', ?, 'PENDING_ACTIVATION', ?)
                    ON CONFLICT (invitation_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, invitationId)
                    stmt.setString(2, "inv-$invitationId@example.com")
                    stmt.setLong(3, System.currentTimeMillis())
                    stmt.executeUpdate()
                }
        }
    }

    override fun insertMemberInvitation(invitationId: String) {
        val organizationId = "org-for-$invitationId"
        insertOrganization(organizationId)
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO member_invitation(
                        invitation_id, organization_id, email, first_name, last_name, roles, status, created_at, expires_at
                    )
                    VALUES (?, ?, ?, 'Test', 'Member', '["VOLUNTEER"]', 'PENDING_ACTIVATION', ?, ?)
                    ON CONFLICT (invitation_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    val now = System.currentTimeMillis()
                    stmt.setString(1, invitationId)
                    stmt.setString(2, organizationId)
                    stmt.setString(3, "inv-$invitationId@example.com")
                    stmt.setLong(4, now)
                    stmt.setLong(5, now + 1000)
                    stmt.executeUpdate()
                }
        }
    }

    override fun insertOrganizationRequest(requestId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization_request(request_id, organization_name, organization_type, timezone, default_language,
                        admin_first_name, admin_last_name, admin_email, status, submitted_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, requestId)
                    stmt.setString(2, "AMAP-req-$requestId")
                    stmt.setString(3, "AMAP")
                    stmt.setString(4, "Europe/Paris")
                    stmt.setString(5, "fr")
                    stmt.setString(6, "Jean")
                    stmt.setString(7, "Dupont")
                    stmt.setString(8, "req-$requestId@example.com")
                    stmt.setString(9, "PENDING_VALIDATION")
                    stmt.setLong(10, System.currentTimeMillis())
                    stmt.executeUpdate()
                }
        }
    }

    override fun insertProducerRequest(requestId: String) {
        postgresClient.dataSource.connection.use { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_request(request_id, producer_name, admin_first_name, admin_last_name, admin_email, status, submitted_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, requestId)
                    stmt.setString(2, "Producer-$requestId")
                    stmt.setString(3, "Jean")
                    stmt.setString(4, "Dupont")
                    stmt.setString(5, "req-$requestId@example.com")
                    stmt.setString(6, "PENDING_VALIDATION")
                    stmt.setLong(7, System.currentTimeMillis())
                    stmt.executeUpdate()
                }
        }
    }
}

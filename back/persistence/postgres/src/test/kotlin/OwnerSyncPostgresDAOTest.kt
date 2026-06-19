package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OwnerPayload
import persistence.changes.SyncScope
import persistence.dao.MemberSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.OwnerSyncDAOContractTest
import persistence.model.EntityType
import persistence.model.Owner
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OwnerSyncPostgresDAOTest : OwnerSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val ownerDAO: OwnerSyncDAO by lazy { OwnerSyncPostgresDAO(postgresClient) }
    override val memberSyncDAO: MemberSyncDAO by lazy { MemberSyncPostgresDAO(postgresClient) }

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

    override fun buildChange(owner: Owner): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Owner,
            entityId = owner.ownerId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OwnerPayload(owner),
            producedAt = System.currentTimeMillis(),
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
    }

    @AfterAll
    fun tearDown() {
        container.stop()
    }
}

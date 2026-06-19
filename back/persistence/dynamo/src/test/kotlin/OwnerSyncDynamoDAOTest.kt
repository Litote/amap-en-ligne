package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
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

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OwnerSyncDynamoDAOTest : OwnerSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val ownerDAO: OwnerSyncDAO = OwnerSyncDynamoDAO(dynamoClient)
    override val memberSyncDAO: MemberSyncDAO = MemberSyncDynamoDAO(dynamoClient)

    override fun insertOrganization(organizationId: String) {
        // DynamoDB has no FK constraints — no pre-insert needed.
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
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }
}

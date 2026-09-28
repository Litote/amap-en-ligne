package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerInvitationSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OwnerInvitationSyncDynamoDAOTest : OwnerInvitationSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: OwnerInvitationSyncDAO = OwnerInvitationSyncDynamoDAO(dynamoClient)

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

package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.MemberSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MemberSyncDynamoDAOTest : MemberSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val memberSyncDAO: MemberSyncDAO = MemberSyncDynamoDAO(dynamoClient)
    override val changeDAO: ChangeDAO = ChangeDynamoDAO(dynamoClient)

    override fun insertOrganization(organizationId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }

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

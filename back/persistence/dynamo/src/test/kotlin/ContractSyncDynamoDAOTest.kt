package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.ContractSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ContractSyncDynamoDAOTest : ContractSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val contractSyncDAO: ContractSyncDAO = ContractSyncDynamoDAO(dynamoClient)
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

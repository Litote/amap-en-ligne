package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OrganizationSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationSyncDynamoDAOTest : OrganizationSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val organizationSyncDAO: OrganizationSyncDAO = OrganizationSyncDynamoDAO(dynamoClient)
    override val changeDAO: ChangeDAO = ChangeDynamoDAO(dynamoClient)

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

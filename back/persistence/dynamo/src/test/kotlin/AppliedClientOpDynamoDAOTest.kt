package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.AppliedClientOpDAO
import persistence.dao.AppliedClientOpDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class AppliedClientOpDynamoDAOTest : AppliedClientOpDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val appliedClientOpDAO: AppliedClientOpDAO =
        AppliedClientOpDynamoDAO(dynamoClient)

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

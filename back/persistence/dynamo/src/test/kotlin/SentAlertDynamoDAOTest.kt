package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.SentAlertDAO
import persistence.dao.SentAlertDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class SentAlertDynamoDAOTest : SentAlertDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val sentAlertDAO: SentAlertDAO = SentAlertDynamoDAO(dynamoClient)

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

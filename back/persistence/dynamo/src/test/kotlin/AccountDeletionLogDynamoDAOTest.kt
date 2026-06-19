package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.AccountDeletionLogDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class AccountDeletionLogDynamoDAOTest : AccountDeletionLogDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val accountDeletionLogDAO: AccountDeletionLogDAO =
        AccountDeletionLogDynamoDAO(dynamoClient)

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

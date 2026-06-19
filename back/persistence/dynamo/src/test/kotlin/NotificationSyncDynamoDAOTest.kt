package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.NotificationSyncDAO
import persistence.dao.NotificationSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class NotificationSyncDynamoDAOTest : NotificationSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val notificationSyncDAO: NotificationSyncDAO = NotificationSyncDynamoDAO(dynamoClient)
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

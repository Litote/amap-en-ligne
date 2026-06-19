package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.DeviceTokenSyncDAO
import persistence.dao.DeviceTokenSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class DeviceTokenSyncDynamoDAOTest : DeviceTokenSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val deviceTokenSyncDAO: DeviceTokenSyncDAO = DeviceTokenSyncDynamoDAO(dynamoClient)
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

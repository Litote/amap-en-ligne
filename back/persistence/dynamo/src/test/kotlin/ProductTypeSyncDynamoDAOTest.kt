package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.dao.ProductTypeSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProductTypeSyncDynamoDAOTest : ProductTypeSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val productTypeDao: ProductTypeSyncDAO = ProductTypeSyncDynamoDAO(dynamoClient)
    override val changeDao: ChangeDAO = ChangeDynamoDAO(dynamoClient)

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

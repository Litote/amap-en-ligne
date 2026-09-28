package persistence.dynamo

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerAccountSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProducerAccountSyncDynamoDAOTest : ProducerAccountSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val producerAccountSyncDAO: ProducerAccountSyncDAO = ProducerAccountSyncDynamoDAO(dynamoClient)
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

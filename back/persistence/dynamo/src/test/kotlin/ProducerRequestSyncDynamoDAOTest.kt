package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.DeleteItemRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.dao.ProducerRequestSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProducerRequestSyncDynamoDAOTest : ProducerRequestSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override val producerRequestSyncDAO: ProducerRequestSyncDAO = ProducerRequestSyncDynamoDAO(dynamoClient)
    override val changeDAO: ChangeDAO = ChangeDynamoDAO(dynamoClient)

    override fun clearAll() {
        CoroutineScope(Dispatchers.IO)
            .async {
                val items =
                    dynamoClient.client
                        .scan(
                            ScanRequest {
                                tableName = dynamoClient.table
                            },
                        ).items
                        .orEmpty()
                for (item in items) {
                    val pk = item["pk"] ?: continue
                    val sk = item["sk"] ?: continue
                    dynamoClient.client.deleteItem(
                        DeleteItemRequest {
                            tableName = dynamoClient.table
                            key = mapOf("pk" to pk, "sk" to sk)
                        },
                    )
                }
            }.asCompletableFuture()
            .get()
    }
}

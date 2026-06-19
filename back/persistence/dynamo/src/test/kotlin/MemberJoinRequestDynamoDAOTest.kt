package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.DeleteItemRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MemberJoinRequestDynamoDAOTest : MemberJoinRequestDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: MemberJoinRequestDAO = MemberJoinRequestDynamoDAO(dynamoClient)

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override fun clearAll() {
        CoroutineScope(Dispatchers.IO)
            .async {
                val items =
                    dynamoClient.client
                        .scan(
                            ScanRequest {
                                tableName = dynamoClient.table
                                filterExpression = "entity_type = :et"
                                expressionAttributeValues =
                                    mapOf(":et" to AttributeValue.S("MemberJoinRequest"))
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

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.DeleteItemRequest
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ServerDAO
import persistence.dao.ServerDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ServerDynamoDAOTest : ServerDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: ServerDAO = ServerDynamoDAO(dynamoClient)

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override fun insertServer(
        id: String,
        name: String,
        url: String,
    ) {
        CoroutineScope(Dispatchers.IO)
            .async {
                dynamoClient.client.putItem(
                    PutItemRequest {
                        tableName = dynamoClient.table
                        item =
                            mapOf(
                                "pk" to AttributeValue.S("SERVER"),
                                "sk" to AttributeValue.S(id),
                                "name" to AttributeValue.S(name),
                                "url" to AttributeValue.S(url),
                            )
                    },
                )
            }.asCompletableFuture()
            .get()
    }

    override fun clearAll() {
        CoroutineScope(Dispatchers.IO)
            .async {
                val items =
                    dynamoClient.client
                        .query(
                            QueryRequest {
                                tableName = dynamoClient.table
                                keyConditionExpression = "pk = :pk"
                                expressionAttributeValues = mapOf(":pk" to AttributeValue.S("SERVER"))
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

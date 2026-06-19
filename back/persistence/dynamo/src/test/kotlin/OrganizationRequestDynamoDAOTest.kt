package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.DeleteItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationRequestDynamoDAOTest : OrganizationRequestDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: OrganizationRequestDAO = OrganizationRequestDynamoDAO(dynamoClient)

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
                        .query(
                            QueryRequest {
                                tableName = dynamoClient.table
                                keyConditionExpression = "pk = :pk"
                                expressionAttributeValues = mapOf(":pk" to AttributeValue.S("ORGREQ"))
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

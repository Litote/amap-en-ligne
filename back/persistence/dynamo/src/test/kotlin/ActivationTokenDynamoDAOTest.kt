package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ActivationTokenDAO
import persistence.dao.ActivationTokenDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ActivationTokenDynamoDAOTest : ActivationTokenDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: ActivationTokenDAO = ActivationTokenDynamoDAO(dynamoClient)

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override fun insertOrganization(organizationId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }

    override fun insertProducerAccount(producerAccountId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }

    override fun insertOrganizationRequest(requestId: String) {
        CoroutineScope(Dispatchers.IO)
            .async {
                dynamoClient.client.putItem(
                    PutItemRequest {
                        tableName = dynamoClient.table
                        item =
                            mapOf(
                                "pk" to AttributeValue.S("ORGREQ"),
                                "sk" to AttributeValue.S(requestId),
                                "organization_name" to AttributeValue.S("AMAP-req-$requestId"),
                                "organization_type" to AttributeValue.S("AMAP"),
                                "admin_email" to AttributeValue.S("req-$requestId@example.com"),
                                "status" to AttributeValue.S("PENDING_VALIDATION"),
                                "submitted_at" to AttributeValue.N(System.currentTimeMillis().toString()),
                            )
                    },
                )
            }.asCompletableFuture()
            .get()
    }

    override fun insertProducerRequest(requestId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }
}

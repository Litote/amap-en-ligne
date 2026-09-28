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
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrganizationDynamoDAOTest : OrganizationDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: OrganizationDAO = OrganizationDynamoDAO(dynamoClient)

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override fun insertOrganization(
        id: String,
        name: String,
        email: String,
        active: Boolean,
    ) {
        CoroutineScope(Dispatchers.IO)
            .async {
                dynamoClient.client.putItem(
                    PutItemRequest {
                        tableName = dynamoClient.table
                        item =
                            mapOf(
                                "pk" to AttributeValue.S("ORGANIZATION"),
                                "sk" to AttributeValue.S(id),
                                "name" to AttributeValue.S(name),
                                "contact_email" to AttributeValue.S(email),
                                "active_status" to AttributeValue.Bool(active),
                            )
                    },
                )
            }.asCompletableFuture()
            .get()
    }
}

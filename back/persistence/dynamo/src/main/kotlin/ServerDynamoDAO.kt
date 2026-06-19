package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.ServerDAO
import persistence.model.Server

@Single(createdAtStart = true, binds = [ServerDAO::class])
internal class ServerDynamoDAO(
    private val client: DynamoClient,
) : ServerDAO {
    override suspend fun list(): List<Server> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S("SERVER"))
                },
            )
        return response.items.orEmpty().map { it.toServer() }
    }
}

private fun Map<String, AttributeValue>.toServer(): Server =
    Server(
        serverId = (get("sk") as AttributeValue.S).value.toId(),
        name = (get("name") as AttributeValue.S).value,
        url = (get("url") as AttributeValue.S).value,
    )

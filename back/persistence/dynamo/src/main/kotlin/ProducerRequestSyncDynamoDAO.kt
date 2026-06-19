package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProducerRequestSyncDAO
import persistence.model.ProducerRequest

@Single(createdAtStart = true, binds = [ProducerRequestSyncDAO::class])
internal class ProducerRequestSyncDynamoDAO(
    private val client: DynamoClient,
) : ProducerRequestSyncDAO {
    override suspend fun listAll(): List<ProducerRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to
                                aws.sdk.kotlin.services.dynamodb.model.AttributeValue
                                    .S("PRODREQ"),
                        )
                },
            )
        return response.items.orEmpty().map { it.toProducerRequest() }
    }

    override suspend fun put(
        request: ProducerRequest,
        change: Change,
    ) {
        client.transactPutEntityAndChange(request.toAttributeValueMap(), change)
    }
}

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OrganizationRequestSyncDAO
import persistence.model.OrganizationRequest

private const val ORGREQ_PK = "ORGREQ"

@Single(createdAtStart = true, binds = [OrganizationRequestSyncDAO::class])
internal class OrganizationRequestSyncDynamoDAO(
    private val client: DynamoClient,
) : OrganizationRequestSyncDAO {
    override suspend fun listAll(): List<OrganizationRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(ORGREQ_PK))
                },
            )
        return response.items.orEmpty().map { it.toOrganizationRequest() }
    }

    override suspend fun put(
        request: OrganizationRequest,
        change: Change,
    ) {
        client.transactPutEntityAndChange(request.toAttributeValueMap(), change)
    }
}

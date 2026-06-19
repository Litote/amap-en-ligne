package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.OrganizationDAO
import persistence.model.Organization
import persistence.model.PublicOrganizationSummary

@Single(createdAtStart = true, binds = [OrganizationDAO::class])
internal class OrganizationDynamoDAO(
    private val client: DynamoClient,
) : OrganizationDAO {
    override suspend fun listActive(): List<PublicOrganizationSummary> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "active_status = :active"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S("ORGANIZATION"),
                            ":active" to AttributeValue.Bool(true),
                        )
                },
            )
        return response.items.orEmpty().map { it.toPublicOrganizationSummary() }
    }

    override suspend fun create(organization: Organization) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = organization.toAttributeValueMap()
            },
        )
    }
}

private fun Organization.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("ORGANIZATION"))
        put("sk", AttributeValue.S(organizationId.id))
        put("name", AttributeValue.S(name))
        put("contact_email", AttributeValue.S(contactEmail))
        put("active_status", AttributeValue.Bool(activeStatus))
        put("timezone", AttributeValue.S(timezone.id))
        put("default_language", AttributeValue.S(defaultLanguage))
        website?.let { put("website", AttributeValue.S(it)) }
        defaultDeliveryTemplateId?.let { put("default_delivery_template_id", AttributeValue.S(it.id)) }
        put("created_instant", AttributeValue.N(createdInstant.toEpochMilliseconds().toString()))
        put("last_updated_instant", AttributeValue.N(lastUpdatedInstant.toEpochMilliseconds().toString()))
    }

private fun Map<String, AttributeValue>.toPublicOrganizationSummary(): PublicOrganizationSummary =
    PublicOrganizationSummary(
        organizationId = (get("sk") as AttributeValue.S).value.toId(),
        name = (get("name") as AttributeValue.S).value,
        contactEmail = (get("contact_email") as AttributeValue.S).value,
        activeStatus = (get("active_status") as AttributeValue.Bool).value,
    )

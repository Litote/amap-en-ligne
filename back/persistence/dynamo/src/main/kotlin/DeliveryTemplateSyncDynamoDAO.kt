package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.Organization
import serialization.json

@Single(createdAtStart = true, binds = [DeliveryTemplateSyncDAO::class])
internal class DeliveryTemplateSyncDynamoDAO(
    private val client: DynamoClient,
) : DeliveryTemplateSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<DeliveryTemplate> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("DLVTMPL#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toDeliveryTemplate() }
    }

    override suspend fun put(
        deliveryTemplate: DeliveryTemplate,
        change: Change,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    listOf(
                        TransactWriteItem {
                            put =
                                Put {
                                    tableName = client.table
                                    item = deliveryTemplate.toAttributeValueMap()
                                }
                        },
                        TransactWriteItem {
                            put =
                                Put {
                                    tableName = client.table
                                    item = change.toAttributeValueMap()
                                }
                        },
                    )
            },
        )
    }

    override suspend fun delete(
        deliveryTemplateId: Id<DeliveryTemplate>,
        organizationId: Id<Organization>,
        change: Change,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    listOf(
                        TransactWriteItem {
                            delete =
                                Delete {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S("DLVTMPL#${organizationId.id}"),
                                            "sk" to AttributeValue.S(deliveryTemplateId.id),
                                        )
                                }
                        },
                        TransactWriteItem {
                            put =
                                Put {
                                    tableName = client.table
                                    item = change.toAttributeValueMap()
                                }
                        },
                    )
            },
        )
    }
}

private fun DeliveryTemplate.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("DLVTMPL#${organizationId.id}"))
        put("sk", AttributeValue.S(deliveryTemplateId.id))
        put("entity_type", AttributeValue.S("DeliveryTemplate"))
        put("delivery_template_id", AttributeValue.S(deliveryTemplateId.id))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("name", AttributeValue.S(name))
        put("standard_start_time", AttributeValue.S(standardStartTime))
        put("standard_end_time", AttributeValue.S(standardEndTime))
        put("desired_volunteer_count", AttributeValue.N(desiredVolunteerCount.toString()))
        earlySlot?.let { slot ->
            put("early_slot", AttributeValue.S(json.encodeToString(EarlySlot.serializer(), slot)))
        }
        volunteerArrivalTime?.let { put("volunteer_arrival_time", AttributeValue.S(it)) }
    }

private fun Map<String, AttributeValue>.toDeliveryTemplate(): DeliveryTemplate =
    DeliveryTemplate(
        deliveryTemplateId = getValue("delivery_template_id").asS().toId(),
        organizationId = getValue("organization_id").asS().toId(),
        name = getValue("name").asS(),
        standardStartTime = getValue("standard_start_time").asS(),
        standardEndTime = getValue("standard_end_time").asS(),
        desiredVolunteerCount = get("desired_volunteer_count")?.asN()?.toInt() ?: 0,
        earlySlot = get("early_slot")?.asS()?.let { json.decodeFromString(EarlySlot.serializer(), it) },
        volunteerArrivalTime = get("volunteer_arrival_time")?.asS(),
    )

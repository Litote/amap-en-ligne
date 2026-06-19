@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import kotlinx.datetime.TimeZone
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OrganizationSyncDAO
import persistence.model.Delivery
import persistence.model.DeliveryTemplate
import persistence.model.ItemType
import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.Product
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val ORGANIZATION_PK = "ORGANIZATION"

@Single(createdAtStart = true, binds = [OrganizationSyncDAO::class])
internal class OrganizationSyncDynamoDAO(
    private val client: DynamoClient,
) : OrganizationSyncDAO {
    override suspend fun getById(organizationId: Id<Organization>): Organization? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(ORGANIZATION_PK),
                            "sk" to AttributeValue.S(organizationId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toOrganization()
    }

    override suspend fun listAll(): List<Organization> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(ORGANIZATION_PK))
                },
            )
        return response.items.orEmpty().map { it.toOrganization() }
    }

    override suspend fun put(
        organization: Organization,
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
                                    item = organization.toAttributeValueMap()
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
                                            "pk" to AttributeValue.S(ORGANIZATION_PK),
                                            "sk" to AttributeValue.S(organizationId.id),
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

private fun Organization.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(ORGANIZATION_PK))
        put("sk", AttributeValue.S(organizationId.id))
        put("entity_type", AttributeValue.S("Organization"))
        put("name", AttributeValue.S(name))
        put("contact_email", AttributeValue.S(contactEmail))
        put("active_status", AttributeValue.Bool(activeStatus))
        put("timezone", AttributeValue.S(timezone.id))
        put("default_language", AttributeValue.S(defaultLanguage))
        website?.let { put("website", AttributeValue.S(it)) }
        defaultDeliveryTemplateId?.let { put("default_delivery_template_id", AttributeValue.S(it.id)) }
        put("created_instant", AttributeValue.N(createdInstant.toEpochMilliseconds().toString()))
        put("last_updated_instant", AttributeValue.N(lastUpdatedInstant.toEpochMilliseconds().toString()))
        put(
            "producers",
            AttributeValue.S(json.encodeToString(ListSerializer(OrganizationProducer.serializer()), producers)),
        )
        put(
            "products",
            AttributeValue.S(json.encodeToString(ListSerializer(Product.serializer()), products)),
        )
        put(
            "deliveries",
            AttributeValue.S(json.encodeToString(ListSerializer(Delivery.serializer()), deliveries)),
        )
        put(
            "item_types",
            AttributeValue.S(json.encodeToString(ListSerializer(ItemType.serializer()), itemTypes)),
        )
        put(
            "notification_overrides",
            AttributeValue.S(
                json.encodeToString(
                    MapSerializer(NotificationCategory.serializer(), NotificationCopyOverride.serializer()),
                    notificationOverrides,
                ),
            ),
        )
    }

private fun Map<String, AttributeValue>.toOrganization(): Organization =
    Organization(
        organizationId = getValue("sk").asS().toId(),
        name = getValue("name").asS(),
        contactEmail = getValue("contact_email").asS(),
        activeStatus = getValue("active_status").asBool(),
        timezone = TimeZone.of(getValue("timezone").asS()),
        defaultLanguage = getValue("default_language").asS(),
        website = get("website")?.asS(),
        defaultDeliveryTemplateId = get("default_delivery_template_id")?.asS()?.toId<DeliveryTemplate>(),
        createdInstant = Instant.fromEpochMilliseconds(getValue("created_instant").asN().toLong()),
        lastUpdatedInstant = Instant.fromEpochMilliseconds(getValue("last_updated_instant").asN().toLong()),
        producers =
            json.decodeFromString(
                ListSerializer(OrganizationProducer.serializer()),
                get("producers")?.asS() ?: "[]",
            ),
        products =
            json.decodeFromString(
                ListSerializer(Product.serializer()),
                get("products")?.asS() ?: "[]",
            ),
        deliveries =
            json.decodeFromString(
                ListSerializer(Delivery.serializer()),
                get("deliveries")?.asS() ?: "[]",
            ),
        itemTypes =
            json.decodeFromString(
                ListSerializer(ItemType.serializer()),
                get("item_types")?.asS() ?: "[]",
            ),
        notificationOverrides =
            json.decodeFromString(
                MapSerializer(NotificationCategory.serializer(), NotificationCopyOverride.serializer()),
                get("notification_overrides")?.asS() ?: "{}",
            ),
    )

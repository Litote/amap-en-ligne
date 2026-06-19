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
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.NotificationSyncDAO
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [NotificationSyncDAO::class])
internal class NotificationSyncDynamoDAO(
    private val client: DynamoClient,
) : NotificationSyncDAO {
    override suspend fun getByRecipientScope(recipientScope: String): List<Notification> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(pk(recipientScope)))
                },
            )
        return response.items.orEmpty().map { it.toNotification() }
    }

    override suspend fun findById(
        recipientScope: String,
        notificationId: Id<Notification>,
    ): Notification? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(pk(recipientScope)),
                            "sk" to AttributeValue.S(notificationId.id),
                        )
                },
            )
        return response.item?.toNotification()
    }

    override suspend fun put(
        notification: Notification,
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
                                    item = notification.toAttributeValueMap()
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
        recipientScope: String,
        notificationId: Id<Notification>,
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
                                            "pk" to AttributeValue.S(pk(recipientScope)),
                                            "sk" to AttributeValue.S(notificationId.id),
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

    private fun pk(recipientScope: String) = "NOTIF#$recipientScope"

    private fun Notification.toAttributeValueMap(): Map<String, AttributeValue> =
        buildMap {
            put("pk", AttributeValue.S(pk(recipientScope)))
            put("sk", AttributeValue.S(notificationId.id))
            put("entity_type", AttributeValue.S("Notification"))
            put("notification_id", AttributeValue.S(notificationId.id))
            put("recipient_scope", AttributeValue.S(recipientScope))
            put("notification_type", AttributeValue.S(type.name))
            put("category", AttributeValue.S(category.name))
            put("title", AttributeValue.S(title))
            put("body", AttributeValue.S(body))
            deepLink?.let { put("deep_link", AttributeValue.S(it)) }
            relatedEntityId?.let { put("related_entity_id", AttributeValue.S(it)) }
            put("created_at", AttributeValue.N(createdAt.toEpochMilliseconds().toString()))
            readAt?.let { put("read_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        }
}

@OptIn(ExperimentalTime::class)
private fun Map<String, AttributeValue>.toNotification(): Notification =
    Notification(
        notificationId = getValue("notification_id").asS().toId(),
        recipientScope = getValue("recipient_scope").asS(),
        type = NotificationType.valueOf(getValue("notification_type").asS()),
        category = NotificationCategory.valueOf(getValue("category").asS()),
        title = getValue("title").asS(),
        body = getValue("body").asS(),
        deepLink = get("deep_link")?.asS(),
        relatedEntityId = get("related_entity_id")?.asS(),
        createdAt = Instant.fromEpochMilliseconds(getValue("created_at").asN().toLong()),
        readAt = get("read_at")?.asN()?.let { Instant.fromEpochMilliseconds(it.toLong()) },
    )

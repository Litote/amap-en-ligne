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
import persistence.dao.DeviceTokenSyncDAO
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [DeviceTokenSyncDAO::class])
internal class DeviceTokenSyncDynamoDAO(
    private val client: DynamoClient,
) : DeviceTokenSyncDAO {
    override suspend fun getByRecipientScope(recipientScope: String): List<DeviceToken> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(pk(recipientScope)))
                },
            )
        return response.items.orEmpty().map { it.toDeviceToken() }
    }

    override suspend fun findById(
        recipientScope: String,
        deviceTokenId: Id<DeviceToken>,
    ): DeviceToken? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(pk(recipientScope)),
                            "sk" to AttributeValue.S(deviceTokenId.id),
                        )
                },
            )
        return response.item?.toDeviceToken()
    }

    override suspend fun put(
        deviceToken: DeviceToken,
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
                                    item = deviceToken.toAttributeValueMap()
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
        deviceTokenId: Id<DeviceToken>,
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
                                            "sk" to AttributeValue.S(deviceTokenId.id),
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

    private fun pk(recipientScope: String) = "DEVTOK#$recipientScope"

    private fun DeviceToken.toAttributeValueMap(): Map<String, AttributeValue> =
        buildMap {
            put("pk", AttributeValue.S(pk(recipientScope)))
            put("sk", AttributeValue.S(deviceTokenId.id))
            put("entity_type", AttributeValue.S("DeviceToken"))
            put("device_token_id", AttributeValue.S(deviceTokenId.id))
            put("recipient_scope", AttributeValue.S(recipientScope))
            put("platform", AttributeValue.S(platform.name))
            put("token", AttributeValue.S(token))
            put("created_at", AttributeValue.N(createdAt.toEpochMilliseconds().toString()))
            put("last_seen_at", AttributeValue.N(lastSeenAt.toEpochMilliseconds().toString()))
        }
}

@OptIn(ExperimentalTime::class)
private fun Map<String, AttributeValue>.toDeviceToken(): DeviceToken =
    DeviceToken(
        deviceTokenId = getValue("device_token_id").asS().toId(),
        recipientScope = getValue("recipient_scope").asS(),
        platform = DevicePlatform.valueOf(getValue("platform").asS()),
        token = getValue("token").asS(),
        createdAt = Instant.fromEpochMilliseconds(getValue("created_at").asN().toLong()),
        lastSeenAt = Instant.fromEpochMilliseconds(getValue("last_seen_at").asN().toLong()),
    )

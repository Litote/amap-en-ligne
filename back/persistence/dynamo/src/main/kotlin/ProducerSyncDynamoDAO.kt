@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProducerSyncDAO
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ProducerSyncDAO::class])
internal class ProducerSyncDynamoDAO(
    private val client: DynamoClient,
) : ProducerSyncDAO {
    override suspend fun put(
        producer: Producer,
        changes: List<Change>,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        add(
                            TransactWriteItem {
                                put =
                                    Put {
                                        tableName = client.table
                                        item = producer.toAttributeValueMap()
                                    }
                            },
                        )
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }

    override suspend fun findByProducerId(producerId: Id<Producer>): Producer? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(producerId.id),
                        )
                },
            )
        return response.item?.toProducer()
    }

    override suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<Producer> {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "entity_type = :entity_type AND producer_account_id = :producer_account_id"
                    expressionAttributeValues =
                        mapOf(
                            ":entity_type" to AttributeValue.S(ENTITY_TYPE),
                            ":producer_account_id" to AttributeValue.S(producerAccountId.id),
                        )
                },
            )
        return response.items.orEmpty().map { it.toProducer() }
    }

    override suspend fun delete(
        producerId: Id<Producer>,
        changes: List<Change>,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        add(
                            TransactWriteItem {
                                delete =
                                    Delete {
                                        tableName = client.table
                                        key =
                                            mapOf(
                                                "pk" to AttributeValue.S(PK),
                                                "sk" to AttributeValue.S(producerId.id),
                                            )
                                    }
                            },
                        )
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }

    private companion object {
        const val PK = "PRODUCER"
        const val ENTITY_TYPE = "Producer"
    }
}

private fun Producer.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("PRODUCER"))
        put("sk", AttributeValue.S(producerId.id))
        put("entity_type", AttributeValue.S("Producer"))
        put("producer_id", AttributeValue.S(producerId.id))
        put("producer_account_id", AttributeValue.S(producerAccountId.id))
        put("role", AttributeValue.S(role.name))
        put("association_instant", AttributeValue.N(associationInstant.toEpochMilliseconds().toString()))
        put("status", AttributeValue.S(status.name))
        put("producer_preferences", AttributeValue.S(json.encodeToString(ProducerPreferences.serializer(), producerPreferences)))
        put("user_preferences", AttributeValue.S(json.encodeToString(UserPreferences.serializer(), userPreferences)))
        put("user_settings", AttributeValue.S(json.encodeToString(UserSettings.serializer(), userSettings)))
    }

private fun Map<String, AttributeValue>.toProducer(): Producer =
    Producer(
        producerId = getValue("producer_id").asSOrNull()!!.toId(),
        producerAccountId = getValue("producer_account_id").asSOrNull()!!.toId(),
        role = ProducerRole.valueOf(getValue("role").asSOrNull()!!),
        associationInstant = Instant.fromEpochMilliseconds(getValue("association_instant").asNOrNull()!!.toLong()),
        status = ProducerStatus.valueOf(getValue("status").asSOrNull()!!),
        producerPreferences =
            json.decodeFromString(
                ProducerPreferences.serializer(),
                getValue("producer_preferences").asSOrNull()!!,
            ),
        userPreferences =
            json.decodeFromString(
                UserPreferences.serializer(),
                getValue("user_preferences").asSOrNull()!!,
            ),
        userSettings =
            json.decodeFromString(
                UserSettings.serializer(),
                getValue("user_settings").asSOrNull()!!,
            ),
    )

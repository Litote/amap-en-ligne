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
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.BasketExchangeSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Member
import persistence.model.Organization
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private val requestListSerializer = ListSerializer(BasketExchangeRequest.serializer())

@Single(createdAtStart = true, binds = [BasketExchangeSyncDAO::class])
internal class BasketExchangeSyncDynamoDAO(
    private val client: DynamoClient,
) : BasketExchangeSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<BasketExchange> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("BSKEX#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toBasketExchange() }
    }

    override suspend fun findById(
        organizationId: Id<Organization>,
        basketExchangeId: Id<BasketExchange>,
    ): BasketExchange? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S("BSKEX#${organizationId.id}"),
                            "sk" to AttributeValue.S(basketExchangeId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toBasketExchange()
    }

    override suspend fun put(
        basketExchange: BasketExchange,
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
                                    item = basketExchange.toAttributeValueMap()
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
        basketExchangeId: Id<BasketExchange>,
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
                                            "pk" to AttributeValue.S("BSKEX#${organizationId.id}"),
                                            "sk" to AttributeValue.S(basketExchangeId.id),
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

private fun BasketExchange.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("BSKEX#${organizationId.id}"))
        put("sk", AttributeValue.S(basketExchangeId.id))
        put("entity_type", AttributeValue.S("BasketExchange"))
        put("basket_exchange_id", AttributeValue.S(basketExchangeId.id))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("delivery_id", AttributeValue.S(deliveryId.id))
        put("contract_id", AttributeValue.S(contractId.id))
        put("offering_member_id", AttributeValue.S(offeringMemberId.id))
        put("status", AttributeValue.S(status.name))
        put("created_at", AttributeValue.N(createdAt.toEpochMilliseconds().toString()))
        motive?.let { put("motive", AttributeValue.S(it)) }
        decidedAt?.let { put("decided_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        acceptedRequestId?.let { put("accepted_request_id", AttributeValue.S(it.id)) }
        put("requests", AttributeValue.S(json.encodeToString(requestListSerializer, requests)))
    }

private fun Map<String, AttributeValue>.toBasketExchange(): BasketExchange =
    BasketExchange(
        basketExchangeId = getValue("basket_exchange_id").asS().toId(),
        organizationId = getValue("organization_id").asS().toId(),
        deliveryId = getValue("delivery_id").asS().toId(),
        contractId = getValue("contract_id").asS().toId(),
        offeringMemberId = getValue("offering_member_id").asS().toId<Member>(),
        motive = get("motive")?.asS(),
        status = BasketExchangeStatus.valueOf(getValue("status").asS()),
        createdAt = Instant.fromEpochMilliseconds(getValue("created_at").asN().toLong()),
        decidedAt =
            get("decided_at")?.asN()?.let { Instant.fromEpochMilliseconds(it.toLong()) },
        acceptedRequestId =
            get("accepted_request_id")?.asS()?.toId<BasketExchangeRequest>(),
        requests =
            json.decodeFromString(
                requestListSerializer,
                get("requests")?.asS() ?: "[]",
            ),
    )

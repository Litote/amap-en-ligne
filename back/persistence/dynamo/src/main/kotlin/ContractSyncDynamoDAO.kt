@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ContractSyncDAO
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.DeliveryTemplate
import persistence.model.Member
import persistence.model.Organization
import persistence.model.ProductPrice
import persistence.model.SharedBasket
import serialization.json
import kotlin.time.ExperimentalTime

private val stringListSerializer = ListSerializer(String.serializer())
private val contractMemberListSerializer = ListSerializer(ContractMember.serializer())
private val productPriceListSerializer = ListSerializer(ProductPrice.serializer())
private val sharedBasketListSerializer = ListSerializer(SharedBasket.serializer())

@Single(createdAtStart = true, binds = [ContractSyncDAO::class])
internal class ContractSyncDynamoDAO(
    private val client: DynamoClient,
) : ContractSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Contract> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("CONTRACT#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toContract() }
    }

    override suspend fun put(
        contract: Contract,
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
                                    item = contract.toAttributeValueMap()
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
        contractId: Id<Contract>,
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
                                            "pk" to AttributeValue.S("CONTRACT#${organizationId.id}"),
                                            "sk" to AttributeValue.S(contractId.id),
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

private fun Contract.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("CONTRACT#${organizationId.id}"))
        put("sk", AttributeValue.S(contractId.id))
        put("entity_type", AttributeValue.S("Contract"))
        put("contract_id", AttributeValue.S(contractId.id))
        put("name", AttributeValue.S(name))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("producer_account_id", AttributeValue.S(producerAccountId.id))
        put("product_prices_json", AttributeValue.S(json.encodeToString(productPriceListSerializer, productPrices)))
        put("min_delivery_date", AttributeValue.S(minDeliveryDate.toString()))
        put("max_delivery_date", AttributeValue.S(maxDeliveryDate.toString()))
        put("delivery_count", AttributeValue.N(deliveryCount.toString()))
        put("season_year", AttributeValue.N(seasonYear.toString()))
        put(
            "coordinators",
            AttributeValue.S(json.encodeToString(stringListSerializer, coordinators.map { it.id })),
        )
        put(
            "members_json",
            AttributeValue.S(json.encodeToString(contractMemberListSerializer, members)),
        )
        put("status", AttributeValue.S(status.name))
        val templateId = deliveryTemplateId
        if (templateId != null) {
            put("delivery_template_id", AttributeValue.S(templateId.id))
        }
        put(
            "shared_baskets",
            AttributeValue.S(json.encodeToString(sharedBasketListSerializer, sharedBaskets)),
        )
        put("is_main_contract", AttributeValue.Bool(isMainContract))
    }

private fun Map<String, AttributeValue>.toContract(): Contract =
    Contract(
        contractId = getValue("contract_id").asS().toId(),
        name = getValue("name").asS(),
        organizationId = getValue("organization_id").asS().toId(),
        producerAccountId = getValue("producer_account_id").asS().toId(),
        productPrices =
            json.decodeFromString(
                productPriceListSerializer,
                get("product_prices_json")?.asS() ?: "[]",
            ),
        minDeliveryDate = LocalDate.parse(getValue("min_delivery_date").asS()),
        maxDeliveryDate = LocalDate.parse(getValue("max_delivery_date").asS()),
        deliveryCount = getValue("delivery_count").asN().toInt(),
        seasonYear = getValue("season_year").asN().toInt(),
        coordinators =
            json
                .decodeFromString(stringListSerializer, get("coordinators")?.asS() ?: "[]")
                .map { it.toId<Member>() },
        members =
            json.decodeFromString(
                contractMemberListSerializer,
                get("members_json")?.asS() ?: "[]",
            ),
        status = get("status")?.asS()?.let { ContractStatus.valueOf(it) } ?: ContractStatus.IN_PREPARATION,
        deliveryTemplateId = get("delivery_template_id")?.asS()?.toId<DeliveryTemplate>(),
        sharedBaskets =
            json.decodeFromString(
                sharedBasketListSerializer,
                get("shared_baskets")?.asS() ?: "[]",
            ),
        isMainContract = get("is_main_contract")?.asBool() ?: false,
    )

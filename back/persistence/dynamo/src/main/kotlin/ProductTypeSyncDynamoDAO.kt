package persistence.dynamo

import aws.sdk.kotlin.hll.dynamodbmapper.DynamoDbAttribute
import aws.sdk.kotlin.hll.dynamodbmapper.DynamoDbItem
import aws.sdk.kotlin.hll.dynamodbmapper.DynamoDbPartitionKey
import aws.sdk.kotlin.hll.dynamodbmapper.DynamoDbSortKey
import aws.sdk.kotlin.hll.dynamodbmapper.expressions.KeyFilter
import aws.sdk.kotlin.hll.dynamodbmapper.operations.items
import aws.sdk.kotlin.hll.dynamodbmapper.operations.queryPaginated
import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import kotlinx.coroutines.flow.toList
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketSize
import persistence.model.ProducerAccount
import persistence.model.ProductType

@Single(createdAtStart = true, binds = [ProductTypeSyncDAO::class])
internal class ProductTypeSyncDynamoDAO(
    val client: DynamoClient,
) : ProductTypeSyncDAO {
    override suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<ProductType> =
        client
            .productTypeTable
            .queryPaginated {
                keyCondition = KeyFilter("PT#${producerAccountId.id}")
            }.items()
            .toList()
            .map { ProductType(it) }

    override suspend fun put(
        productType: ProductType,
        change: Change,
    ) {
        val item = ProductTypeDynamo(productType)
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    listOf(
                        TransactWriteItem {
                            put =
                                Put {
                                    tableName = client.table
                                    this.item = item.toAttributeValueMap()
                                }
                        },
                        TransactWriteItem {
                            put =
                                Put {
                                    tableName = client.table
                                    this.item = change.toAttributeValueMap()
                                }
                        },
                    )
            },
        )
    }

    override suspend fun delete(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
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
                                            "pk" to AttributeValue.S("PT#${producerAccountId.id}"),
                                            "sk" to AttributeValue.S(id.id),
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

@DynamoDbItem
internal data class ProductTypeDynamo(
    @DynamoDbPartitionKey
    val pk: String,
    @DynamoDbSortKey
    val sk: String,
    @DynamoDbAttribute("supported_basket_sizes")
    val supportedBasketSizes: List<BasketSizeDynamo>,
    val name: String,
    val description: String? = null,
) {
    constructor(model: ProductType) :
        this(
            pk = "PT#${model.producerAccountId.id}",
            sk = model.productTypeId.id,
            supportedBasketSizes = model.supportedBasketSizes.map { BasketSizeDynamo(it) },
            name = model.name,
            description = model.description,
        )

    fun toAttributeValueMap(): Map<String, AttributeValue> =
        buildMap {
            put("pk", AttributeValue.S(pk))
            put("sk", AttributeValue.S(sk))
            put("entity_type", AttributeValue.S("ProductType"))
            put(
                "supported_basket_sizes",
                AttributeValue.L(
                    supportedBasketSizes.map {
                        AttributeValue.M(mapOf("name" to AttributeValue.S(it.name)))
                    },
                ),
            )
            put("name", AttributeValue.S(name))
            description?.let { put("description", AttributeValue.S(it)) }
        }
}

internal fun ProductType(dynamo: ProductTypeDynamo): ProductType =
    ProductType(
        dynamo.sk.toId(),
        dynamo.pk.removePrefix("PT#").toId(),
        dynamo.supportedBasketSizes.map { BasketSize(it) },
        dynamo.name,
        dynamo.description,
    )

@DynamoDbItem
internal data class BasketSizeDynamo(
    @DynamoDbPartitionKey val name: String,
) {
    constructor(model: BasketSize) : this(model.name)
}

internal fun BasketSize(dynamo: BasketSizeDynamo): BasketSize = BasketSize(dynamo.name)

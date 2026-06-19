package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import persistence.changes.Change

// Extension functions for DynamoDB transaction patterns.
// Eliminates boilerplate around transactWriteItems by factoring out the common
// "put entity + put change" and "delete entity + put change" scaffolding.

/**
 * Atomically write an entity and a Change record in a single transaction.
 * Used by put() methods across all sync DAOs.
 */
internal suspend fun DynamoClient.transactPutEntityAndChange(
    entityItem: Map<String, AttributeValue>,
    change: Change,
) {
    client.transactWriteItems(
        TransactWriteItemsRequest {
            transactItems =
                listOf(
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = table
                                item = entityItem
                            }
                    },
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = table
                                item = change.toAttributeValueMap()
                            }
                    },
                )
        },
    )
}

/**
 * Atomically delete an entity and write a Change record in a single transaction.
 * Used by delete() methods across all sync DAOs.
 */
internal suspend fun DynamoClient.transactDeleteEntityAndChange(
    pk: String,
    sk: String,
    change: Change,
) {
    client.transactWriteItems(
        TransactWriteItemsRequest {
            transactItems =
                listOf(
                    TransactWriteItem {
                        delete =
                            Delete {
                                tableName = table
                                key =
                                    mapOf(
                                        "pk" to AttributeValue.S(pk),
                                        "sk" to AttributeValue.S(sk),
                                    )
                            }
                    },
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = table
                                item = change.toAttributeValueMap()
                            }
                    },
                )
        },
    )
}

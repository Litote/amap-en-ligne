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
 * Used by put() methods across all sync DAOs; [extraChanges] records the same
 * change on further scopes (fan-out) within the same transaction.
 */
internal suspend fun DynamoClient.transactPutEntityAndChange(
    entityItem: Map<String, AttributeValue>,
    change: Change,
    extraChanges: List<Change> = emptyList(),
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
                ) + extraChanges.map { it.toChangePut(table) }
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
    extraChanges: List<Change> = emptyList(),
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
                ) + extraChanges.map { it.toChangePut(table) }
        },
    )
}

private fun Change.toChangePut(table: String): TransactWriteItem =
    TransactWriteItem {
        put =
            Put {
                tableName = table
                item = toAttributeValueMap()
            }
    }

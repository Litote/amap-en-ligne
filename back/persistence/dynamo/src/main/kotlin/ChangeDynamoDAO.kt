package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.Select
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.EntityPayload
import persistence.dao.ChangeDAO
import persistence.model.EntityType
import serialization.json

@Single(createdAtStart = true, binds = [ChangeDAO::class])
internal class ChangeDynamoDAO(
    private val client: DynamoClient,
) : ChangeDAO {
    override suspend fun countSince(
        scopeKey: String,
        cursor: String?,
        limit: Int,
    ): Int {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    indexName = client.changesByCursorIndex
                    keyConditionExpression = buildKeyCondition(cursor)
                    expressionAttributeValues = buildValues(scopeKey, cursor)
                    expressionAttributeNames = cursorNames(cursor)
                    select = Select.Count
                    this.limit = limit
                },
            )
        return response.count
    }

    override suspend fun since(
        scopeKey: String,
        cursor: String?,
    ): List<Change> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    indexName = client.changesByCursorIndex
                    keyConditionExpression = buildKeyCondition(cursor)
                    expressionAttributeValues = buildValues(scopeKey, cursor)
                    expressionAttributeNames = cursorNames(cursor)
                },
            )
        return response.items.orEmpty().map { it.toChange() }
    }

    private fun buildKeyCondition(cursor: String?): String =
        if (cursor == null) {
            "change_pk = :change_pk"
        } else {
            "change_pk = :change_pk AND #cursor > :cursor"
        }

    private fun buildValues(
        scopeKey: String,
        cursor: String?,
    ): Map<String, AttributeValue> =
        buildMap {
            put(":change_pk", AttributeValue.S(changePk(scopeKey)))
            if (cursor != null) {
                put(":cursor", AttributeValue.S(cursor))
            }
        }

    private fun cursorNames(cursor: String?): Map<String, String>? =
        if (cursor == null) {
            null
        } else {
            mapOf("#cursor" to "cursor")
        }
}

internal fun partitionKey(scopeKey: String): String = "CHANGE#$scopeKey"

internal fun changePk(scopeKey: String): String = scopeKey

internal fun changeSk(
    entityType: EntityType,
    entityId: String,
): String = "${entityType.name}#$entityId"

internal fun Change.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(partitionKey(scopeKey)))
        put("sk", AttributeValue.S(changeSk(entityType, entityId)))
        put("change_pk", AttributeValue.S(changePk(scopeKey)))
        put("entity_id", AttributeValue.S(entityId))
        put("cursor", AttributeValue.S(cursor))
        put("entity_type", AttributeValue.S(entityType.name))
        put("scope_key", AttributeValue.S(scopeKey))
        put("op", AttributeValue.S(op.name))
        put("produced_at", AttributeValue.N(producedAt.toString()))
        payload?.let {
            put("payload", AttributeValue.S(json.encodeToString(EntityPayload.serializer(), it)))
        }
    }

private fun Map<String, AttributeValue>.toChange(): Change {
    val payload: EntityPayload? =
        (get("payload") as? AttributeValue.S)?.value?.let {
            json.decodeFromString(EntityPayload.serializer(), it)
        }
    return Change(
        cursor = (get("cursor") as AttributeValue.S).value,
        entityType = EntityType.valueOf((get("entity_type") as AttributeValue.S).value),
        scopeKey = (get("scope_key") as AttributeValue.S).value,
        entityId = (get("entity_id") as AttributeValue.S).value,
        op = ChangeOp.valueOf((get("op") as AttributeValue.S).value),
        payload = payload,
        producedAt = (get("produced_at") as AttributeValue.N).value.toLong(),
    )
}

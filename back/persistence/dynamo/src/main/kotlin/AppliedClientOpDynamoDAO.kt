@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import org.koin.core.annotation.Single
import persistence.dao.AppliedClientOpDAO
import persistence.model.AppliedClientOp
import persistence.model.EntityType
import kotlin.time.Duration.Companion.days
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "APPLIED_OP"

/** Retention of idempotency records — long enough for any realistic offline retry. */
private val RETENTION = 30.days

@Single(createdAtStart = true, binds = [AppliedClientOpDAO::class])
internal class AppliedClientOpDynamoDAO(
    private val client: DynamoClient,
) : AppliedClientOpDAO {
    override suspend fun record(entry: AppliedClientOp) {
        // Plain put: the pipeline looks the record up before applying, so a
        // duplicate write can only carry the same content — overwriting is a
        // deterministic no-op.
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = entry.toAttributeValueMap()
            },
        )
    }

    override suspend fun find(clientOpId: String): AppliedClientOp? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(clientOpId),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toAppliedClientOp()
    }
}

private fun AppliedClientOp.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PK))
        put("sk", AttributeValue.S(clientOpId))
        put("caller_sub", AttributeValue.S(callerSub))
        put("entity_type", AttributeValue.S(entityType.name))
        serverEntityId?.let { put("server_entity_id", AttributeValue.S(it)) }
        put("applied_at", AttributeValue.N(appliedAt.toEpochMilliseconds().toString()))
        // Epoch seconds, as required by DynamoDB TTL (enabled in Terraform).
        put("ttl", AttributeValue.N((appliedAt + RETENTION).epochSeconds.toString()))
    }

private fun Map<String, AttributeValue>.toAppliedClientOp(): AppliedClientOp =
    AppliedClientOp(
        clientOpId = getValue("sk").asS(),
        callerSub = getValue("caller_sub").asS(),
        entityType = EntityType.valueOf(getValue("entity_type").asS()),
        serverEntityId = get("server_entity_id")?.asS(),
        appliedAt = Instant.fromEpochMilliseconds(getValue("applied_at").asN().toLong()),
    )

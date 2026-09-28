@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.ConditionalCheckFailedException
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import org.koin.core.annotation.Single
import persistence.dao.SentAlertDAO
import kotlin.time.Duration.Companion.days
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "SENT_ALERT"

/** Retention of sent-alert records — far beyond the alert lead times. */
private val RETENTION = 30.days

@Single(createdAtStart = true, binds = [SentAlertDAO::class])
internal class SentAlertDynamoDAO(
    private val client: DynamoClient,
) : SentAlertDAO {
    override suspend fun markIfAbsent(
        key: String,
        sentAt: Instant,
    ): Boolean =
        try {
            client.client.putItem(
                PutItemRequest {
                    tableName = client.table
                    item =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(key),
                            "sent_at" to AttributeValue.N(sentAt.toEpochMilliseconds().toString()),
                            // Epoch seconds, as required by DynamoDB TTL (enabled in Terraform).
                            "ttl" to AttributeValue.N((sentAt + RETENTION).epochSeconds.toString()),
                        )
                    conditionExpression = "attribute_not_exists(pk)"
                },
            )
            true
        } catch (_: ConditionalCheckFailedException) {
            false
        }

    // Expired records are removed by the table TTL.
    override suspend fun purgeBefore(instant: Instant) = Unit
}

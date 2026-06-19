@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.UpdateItemRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.ProducerRequestDAO
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PRODREQ_PK = "PRODREQ"
private const val GSI_BY_ADMIN_EMAIL = "by_admin_email"

@Single(createdAtStart = true, binds = [ProducerRequestDAO::class])
internal class ProducerRequestDynamoDAO(
    private val client: DynamoClient,
) : ProducerRequestDAO {
    override suspend fun create(request: ProducerRequest) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = request.toAttributeValueMap()
            },
        )
    }

    override suspend fun existsByProducerName(
        name: String,
        excludedStatuses: Set<ProducerRequestStatus>,
    ): ProducerRequestStatus? {
        val excludedNames = excludedStatuses.map { it.name }.toSet()
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "producer_name = :producer_name"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PRODREQ_PK),
                            ":producer_name" to AttributeValue.S(name),
                        )
                },
            )
        for (item in response.items.orEmpty()) {
            val statusStr = item["status"]?.asS() ?: continue
            if (statusStr !in excludedNames) return ProducerRequestStatus.valueOf(statusStr)
        }
        return null
    }

    override suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<ProducerRequestStatus>,
    ): ProducerRequestStatus? {
        val gsiResponse =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    indexName = GSI_BY_ADMIN_EMAIL
                    keyConditionExpression = "admin_email = :email"
                    filterExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(
                            ":email" to AttributeValue.S(email),
                            ":pk" to AttributeValue.S(PRODREQ_PK),
                        )
                },
            )
        val excludedNames = excludedStatuses.map { it.name }.toSet()
        for (item in gsiResponse.items.orEmpty()) {
            val fullItem =
                client.client
                    .getItem(
                        GetItemRequest {
                            tableName = client.table
                            key = mapOf("pk" to AttributeValue.S(PRODREQ_PK), "sk" to item.getValue("sk"))
                        },
                    ).item ?: continue
            val statusStr = fullItem["status"]?.asS() ?: continue
            if (statusStr !in excludedNames) return ProducerRequestStatus.valueOf(statusStr)
        }
        return null
    }

    override suspend fun listAll(): List<ProducerRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(PRODREQ_PK))
                },
            )
        return response.items.orEmpty().map { it.toProducerRequest() }
    }

    override suspend fun listByStatus(status: ProducerRequestStatus): List<ProducerRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "#status = :status"
                    expressionAttributeNames = mapOf("#status" to "status")
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PRODREQ_PK),
                            ":status" to AttributeValue.S(status.name),
                        )
                },
            )
        return response.items.orEmpty().map { it.toProducerRequest() }
    }

    override suspend fun findById(requestId: Id<ProducerRequest>): ProducerRequest? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PRODREQ_PK),
                            "sk" to AttributeValue.S(requestId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toProducerRequest()
    }

    override suspend fun updateStatus(
        requestId: Id<ProducerRequest>,
        status: ProducerRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) {
        val (updateExpression, expressionValues) =
            if (reviewComment != null) {
                "SET #status = :status, reviewed_at = :reviewed_at, review_comment = :review_comment" to
                    mapOf(
                        ":status" to AttributeValue.S(status.name),
                        ":reviewed_at" to AttributeValue.N(reviewedAt.toEpochMilliseconds().toString()),
                        ":review_comment" to AttributeValue.S(reviewComment),
                    )
            } else {
                "SET #status = :status, reviewed_at = :reviewed_at REMOVE review_comment" to
                    mapOf(
                        ":status" to AttributeValue.S(status.name),
                        ":reviewed_at" to AttributeValue.N(reviewedAt.toEpochMilliseconds().toString()),
                    )
            }
        client.client.updateItem(
            UpdateItemRequest {
                tableName = client.table
                key =
                    mapOf(
                        "pk" to AttributeValue.S(PRODREQ_PK),
                        "sk" to AttributeValue.S(requestId.id),
                    )
                this.updateExpression = updateExpression
                expressionAttributeNames = mapOf("#status" to "status")
                expressionAttributeValues = expressionValues
            },
        )
    }
}

internal fun ProducerRequest.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PRODREQ_PK))
        put("sk", AttributeValue.S(requestId.id))
        put("entity_type", AttributeValue.S("ProducerRequest"))
        put("producer_name", AttributeValue.S(producerName))
        put("admin_first_name", AttributeValue.S(adminFirstName))
        put("admin_last_name", AttributeValue.S(adminLastName))
        put("admin_email", AttributeValue.S(adminEmail))
        put("status", AttributeValue.S(status.name))
        put("submitted_at", AttributeValue.N(submittedAt.toEpochMilliseconds().toString()))
        reviewedAt?.let { put("reviewed_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        reviewComment?.let { put("review_comment", AttributeValue.S(it)) }
        submitterComment?.let { put("submitter_comment", AttributeValue.S(it)) }
        producerAccountId?.let { put("producer_account_id", AttributeValue.S(it.id)) }
        resendRequestedAt?.let { put("resend_requested_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
    }

internal fun Map<String, AttributeValue>.toProducerRequest(): ProducerRequest =
    ProducerRequest(
        requestId = getValue("sk").asS().toId(),
        producerName = getValue("producer_name").asS(),
        adminFirstName = getValue("admin_first_name").asS(),
        adminLastName = getValue("admin_last_name").asS(),
        adminEmail = getValue("admin_email").asS(),
        status = ProducerRequestStatus.valueOf(getValue("status").asS()),
        submittedAt = Instant.fromEpochMilliseconds(getValue("submitted_at").asN().toLong()),
        reviewedAt = get("reviewed_at")?.asN()?.toLong()?.let(Instant::fromEpochMilliseconds),
        reviewComment = get("review_comment")?.asS(),
        submitterComment = get("submitter_comment")?.asS(),
        producerAccountId = get("producer_account_id")?.asS()?.toId(),
        resendRequestedAt = get("resend_requested_at")?.asN()?.toLong()?.let(Instant::fromEpochMilliseconds),
    )

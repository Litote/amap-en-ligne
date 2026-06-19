@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.UpdateItemRequest
import id.Id
import id.toId
import kotlinx.datetime.TimeZone
import org.koin.core.annotation.Single
import persistence.dao.OrganizationRequestDAO
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "ORGREQ"
private const val GSI_BY_ORG_NAME = "by_organization_name"
private const val GSI_BY_ADMIN_EMAIL = "by_admin_email"

@Single(createdAtStart = true, binds = [OrganizationRequestDAO::class])
internal class OrganizationRequestDynamoDAO(
    private val client: DynamoClient,
) : OrganizationRequestDAO {
    override suspend fun create(request: OrganizationRequest) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = request.toAttributeValueMap()
            },
        )
    }

    override suspend fun existsByOrganizationName(
        name: String,
        excludedStatuses: Set<OrganizationRequestStatus>,
    ): OrganizationRequestStatus? {
        val gsiResponse =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    indexName = GSI_BY_ORG_NAME
                    keyConditionExpression = "organization_name = :name"
                    expressionAttributeValues = mapOf(":name" to AttributeValue.S(name))
                },
            )
        val excludedNames = excludedStatuses.map { it.name }.toSet()
        for (item in gsiResponse.items.orEmpty()) {
            val fullItem =
                client.client
                    .getItem(
                        GetItemRequest {
                            tableName = client.table
                            key = mapOf("pk" to AttributeValue.S(PK), "sk" to item.getValue("sk"))
                        },
                    ).item ?: continue
            val statusStr = fullItem["status"]?.asS() ?: continue
            if (statusStr !in excludedNames) return OrganizationRequestStatus.valueOf(statusStr)
        }
        return null
    }

    override suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<OrganizationRequestStatus>,
    ): OrganizationRequestStatus? {
        val gsiResponse =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    indexName = GSI_BY_ADMIN_EMAIL
                    keyConditionExpression = "admin_email = :email"
                    expressionAttributeValues = mapOf(":email" to AttributeValue.S(email))
                },
            )
        val excludedNames = excludedStatuses.map { it.name }.toSet()
        for (item in gsiResponse.items.orEmpty()) {
            val fullItem =
                client.client
                    .getItem(
                        GetItemRequest {
                            tableName = client.table
                            key = mapOf("pk" to AttributeValue.S(PK), "sk" to item.getValue("sk"))
                        },
                    ).item ?: continue
            val statusStr = fullItem["status"]?.asS() ?: continue
            if (statusStr !in excludedNames) return OrganizationRequestStatus.valueOf(statusStr)
        }
        return null
    }

    override suspend fun listAll(): List<OrganizationRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(PK))
                },
            )
        return response.items.orEmpty().map { it.toOrganizationRequest() }
    }

    override suspend fun listByStatus(status: OrganizationRequestStatus): List<OrganizationRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "#s = :status"
                    expressionAttributeNames = mapOf("#s" to "status")
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PK),
                            ":status" to AttributeValue.S(status.name),
                        )
                },
            )
        return response.items.orEmpty().map { it.toOrganizationRequest() }
    }

    override suspend fun findById(requestId: Id<OrganizationRequest>): OrganizationRequest? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(requestId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toOrganizationRequest()
    }

    override suspend fun updateStatus(
        requestId: Id<OrganizationRequest>,
        status: OrganizationRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) {
        val (updateExpression, expressionValues) =
            if (reviewComment != null) {
                "SET #s = :status, reviewed_at = :reviewed_at, review_comment = :review_comment" to
                    mapOf(
                        ":status" to AttributeValue.S(status.name),
                        ":reviewed_at" to AttributeValue.N(reviewedAt.toEpochMilliseconds().toString()),
                        ":review_comment" to AttributeValue.S(reviewComment),
                    )
            } else {
                "SET #s = :status, reviewed_at = :reviewed_at REMOVE review_comment" to
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
                        "pk" to AttributeValue.S(PK),
                        "sk" to AttributeValue.S(requestId.id),
                    )
                this.updateExpression = updateExpression
                expressionAttributeNames = mapOf("#s" to "status")
                expressionAttributeValues = expressionValues
            },
        )
    }
}

internal fun OrganizationRequest.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PK))
        put("sk", AttributeValue.S(requestId.id))
        put("entity_type", AttributeValue.S("OrganizationRequest"))
        put("organization_name", AttributeValue.S(organizationName))
        put("organization_type", AttributeValue.S(organizationType.name))
        put("timezone", AttributeValue.S(timezone.id))
        put("default_language", AttributeValue.S(defaultLanguage))
        put("admin_first_name", AttributeValue.S(adminFirstName))
        put("admin_last_name", AttributeValue.S(adminLastName))
        put("admin_email", AttributeValue.S(adminEmail))
        put("status", AttributeValue.S(status.name))
        put("submitted_at", AttributeValue.N(submittedAt.toEpochMilliseconds().toString()))
        reviewedAt?.let { put("reviewed_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        reviewComment?.let { put("review_comment", AttributeValue.S(it)) }
        submitterComment?.let { put("submitter_comment", AttributeValue.S(it)) }
        organizationId?.let { put("organization_id", AttributeValue.S(it.id)) }
        resendRequestedAt?.let { put("resend_requested_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
    }

internal fun Map<String, AttributeValue>.toOrganizationRequest(): OrganizationRequest =
    OrganizationRequest(
        requestId = getValue("sk").asS().toId(),
        organizationName = getValue("organization_name").asS(),
        organizationType = OrganizationType.valueOf(getValue("organization_type").asS()),
        timezone = TimeZone.of(getValue("timezone").asS()),
        defaultLanguage = getValue("default_language").asS(),
        adminFirstName = getValue("admin_first_name").asS(),
        adminLastName = getValue("admin_last_name").asS(),
        adminEmail = getValue("admin_email").asS(),
        status = OrganizationRequestStatus.valueOf(getValue("status").asS()),
        submittedAt = Instant.fromEpochMilliseconds(getValue("submitted_at").asN().toLong()),
        reviewedAt = get("reviewed_at")?.asN()?.toLong()?.let { Instant.fromEpochMilliseconds(it) },
        reviewComment = get("review_comment")?.asS(),
        submitterComment = get("submitter_comment")?.asS(),
        organizationId = get("organization_id")?.asS()?.toId(),
        resendRequestedAt = get("resend_requested_at")?.asN()?.toLong()?.let { Instant.fromEpochMilliseconds(it) },
    )

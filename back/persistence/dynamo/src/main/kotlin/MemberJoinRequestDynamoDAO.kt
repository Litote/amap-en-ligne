@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import aws.sdk.kotlin.services.dynamodb.model.UpdateItemRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.MemberJoinRequestDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val ENTITY_TYPE = "MemberJoinRequest"

private fun pkForOrg(organizationId: Id<Organization>) = "MJREQ#${organizationId.id}"

@Single(createdAtStart = true, binds = [MemberJoinRequestDAO::class])
internal class MemberJoinRequestDynamoDAO(
    private val client: DynamoClient,
) : MemberJoinRequestDAO {
    override suspend fun create(request: MemberJoinRequest) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = request.toAttributeValueMap()
            },
        )
    }

    override suspend fun existsPendingByEmailAndOrganization(
        email: String,
        organizationId: Id<Organization>,
    ): Boolean {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "email = :email AND #s = :status"
                    expressionAttributeNames = mapOf("#s" to "status")
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(pkForOrg(organizationId)),
                            ":email" to AttributeValue.S(email),
                            ":status" to AttributeValue.S("PENDING"),
                        )
                    limit = 1
                },
            )
        return (response.count ?: 0) > 0
    }

    override suspend fun listByOrganization(organizationId: Id<Organization>): List<MemberJoinRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S(pkForOrg(organizationId)))
                },
            )
        return response.items.orEmpty().map { it.toMemberJoinRequest() }
    }

    override suspend fun listByOrganizationAndStatus(
        organizationId: Id<Organization>,
        status: MemberJoinRequestStatus,
    ): List<MemberJoinRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "#s = :status"
                    expressionAttributeNames = mapOf("#s" to "status")
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(pkForOrg(organizationId)),
                            ":status" to AttributeValue.S(status.name),
                        )
                },
            )
        return response.items.orEmpty().map { it.toMemberJoinRequest() }
    }

    override suspend fun findById(requestId: Id<MemberJoinRequest>): MemberJoinRequest? {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "sk = :sk AND entity_type = :et"
                    expressionAttributeValues =
                        mapOf(
                            ":sk" to AttributeValue.S(requestId.id),
                            ":et" to AttributeValue.S(ENTITY_TYPE),
                        )
                },
            )
        return response.items
            .orEmpty()
            .firstOrNull()
            ?.toMemberJoinRequest()
    }

    override suspend fun updateStatus(
        requestId: Id<MemberJoinRequest>,
        status: MemberJoinRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    ) {
        val existing = findById(requestId) ?: return
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
                        "pk" to AttributeValue.S(pkForOrg(existing.organizationId)),
                        "sk" to AttributeValue.S(requestId.id),
                    )
                this.updateExpression = updateExpression
                expressionAttributeNames = mapOf("#s" to "status")
                expressionAttributeValues = expressionValues
            },
        )
    }
}

private fun MemberJoinRequest.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(pkForOrg(organizationId)))
        put("sk", AttributeValue.S(requestId.id))
        put("entity_type", AttributeValue.S(ENTITY_TYPE))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("email", AttributeValue.S(email))
        put("first_name", AttributeValue.S(firstName))
        put("last_name", AttributeValue.S(lastName))
        put("status", AttributeValue.S(status.name))
        put("submitted_at", AttributeValue.N(submittedAt.toEpochMilliseconds().toString()))
        reviewedAt?.let { put("reviewed_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        reviewComment?.let { put("review_comment", AttributeValue.S(it)) }
    }

private fun Map<String, AttributeValue>.toMemberJoinRequest(): MemberJoinRequest =
    MemberJoinRequest(
        requestId = getValue("sk").asS().toId(),
        organizationId = getValue("organization_id").asS().toId(),
        email = getValue("email").asS(),
        firstName = getValue("first_name").asS(),
        lastName = getValue("last_name").asS(),
        status = MemberJoinRequestStatus.valueOf(getValue("status").asS()),
        submittedAt = Instant.fromEpochMilliseconds(getValue("submitted_at").asN().toLong()),
        reviewedAt = get("reviewed_at")?.asN()?.toLong()?.let { Instant.fromEpochMilliseconds(it) },
        reviewComment = get("review_comment")?.asS(),
    )

@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val MEMBER_JOIN_REQUEST_ENTITY_TYPE = "MemberJoinRequest"

private fun memberJoinRequestPk(organizationId: Id<Organization>) = "MJREQ#${organizationId.id}"

@Single(createdAtStart = true, binds = [MemberJoinRequestSyncDAO::class])
internal class MemberJoinRequestSyncDynamoDAO(
    private val client: DynamoClient,
) : MemberJoinRequestSyncDAO {
    override suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberJoinRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S(memberJoinRequestPk(organizationId)))
                },
            )
        return response.items.orEmpty().map { it.toMemberJoinRequest() }
    }

    override suspend fun put(
        request: MemberJoinRequest,
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
                                    item = request.toAttributeValueMap()
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

private fun MemberJoinRequest.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(memberJoinRequestPk(organizationId)))
        put("sk", AttributeValue.S(requestId.id))
        put("entity_type", AttributeValue.S(MEMBER_JOIN_REQUEST_ENTITY_TYPE))
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
        reviewedAt = get("reviewed_at")?.asN()?.toLong()?.let(Instant::fromEpochMilliseconds),
        reviewComment = get("review_comment")?.asS(),
    )

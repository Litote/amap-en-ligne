@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OwnerInvitationSyncDAO
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "OWNERINV"

@Single(createdAtStart = true, binds = [OwnerInvitationSyncDAO::class])
internal class OwnerInvitationSyncDynamoDAO(
    private val client: DynamoClient,
) : OwnerInvitationSyncDAO {
    override suspend fun listAll(): List<OwnerInvitation> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(PK))
                },
            )
        return response.items.orEmpty().map { it.toOwnerInvitation() }
    }

    override suspend fun put(
        invitation: OwnerInvitation,
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
                                    item = invitation.toAttributeValueMap()
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

    override suspend fun findById(invitationId: Id<OwnerInvitation>): OwnerInvitation? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(invitationId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toOwnerInvitation()
    }

    override suspend fun existsPendingByEmail(email: String): Boolean {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "email = :email AND #st = :status"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PK),
                            ":email" to AttributeValue.S(email),
                            ":status" to AttributeValue.S(OwnerInvitationStatus.PENDING_ACTIVATION.name),
                        )
                    expressionAttributeNames = mapOf("#st" to "status")
                },
            )
        return response.count > 0
    }
}

private fun OwnerInvitation.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PK))
        put("sk", AttributeValue.S(invitationId.id))
        put("invitation_id", AttributeValue.S(invitationId.id))
        put("first_name", AttributeValue.S(firstName))
        put("last_name", AttributeValue.S(lastName))
        put("email", AttributeValue.S(email))
        put("status", AttributeValue.S(status.name))
        put("submitted_at", AttributeValue.N(submittedAt.toEpochMilliseconds().toString()))
        resendRequestedAt?.let { put("resend_requested_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        activatedAt?.let { put("activated_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
    }

private fun Map<String, AttributeValue>.toOwnerInvitation(): OwnerInvitation =
    OwnerInvitation(
        invitationId = (getValue("invitation_id") as AttributeValue.S).value.toId(),
        firstName = (getValue("first_name") as AttributeValue.S).value,
        lastName = (getValue("last_name") as AttributeValue.S).value,
        email = (getValue("email") as AttributeValue.S).value,
        status = OwnerInvitationStatus.valueOf((getValue("status") as AttributeValue.S).value),
        submittedAt = Instant.fromEpochMilliseconds((getValue("submitted_at") as AttributeValue.N).value.toLong()),
        resendRequestedAt =
            (get("resend_requested_at") as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
        activatedAt = (get("activated_at") as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
    )

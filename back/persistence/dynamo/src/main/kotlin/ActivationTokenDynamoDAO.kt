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
import persistence.dao.ActivationTokenDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.MemberInvitation
import persistence.model.OrganizationRequest
import persistence.model.OwnerInvitation
import persistence.model.ProducerRequest
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ActivationTokenDAO::class])
internal class ActivationTokenDynamoDAO(
    private val client: DynamoClient,
) : ActivationTokenDAO {
    override suspend fun create(token: ActivationToken) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item =
                    buildMap {
                        put("pk", AttributeValue.S("ACTIVATION_TOKEN"))
                        put("sk", AttributeValue.S(token.token))
                        put("kind", AttributeValue.S(token.kind.name))
                        token.requestId?.let { put("request_id", AttributeValue.S(it.id)) }
                        token.producerRequestId?.let { put("producer_request_id", AttributeValue.S(it.id)) }
                        put("admin_email", AttributeValue.S(token.adminEmail))
                        token.organizationId?.let { put("organization_id", AttributeValue.S(it.id)) }
                        token.producerAccountId?.let { put("producer_account_id", AttributeValue.S(it.id)) }
                        token.ownerInvitationId?.let { put("owner_invitation_id", AttributeValue.S(it.id)) }
                        token.memberInvitationId?.let { put("member_invitation_id", AttributeValue.S(it.id)) }
                        put("created_at", AttributeValue.N(token.createdAt.toEpochMilliseconds().toString()))
                        put("expires_at", AttributeValue.N(token.expiresAt.toEpochMilliseconds().toString()))
                        token.invalidatedAt?.let { put("invalidated_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
                    }
            },
        )
    }

    override suspend fun findByToken(token: String): ActivationToken? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S("ACTIVATION_TOKEN"),
                            "sk" to AttributeValue.S(token),
                        )
                },
            )
        val item = response.item ?: return null
        if (item.isEmpty()) return null
        return ActivationToken(
            token = (item.getValue("sk") as AttributeValue.S).value,
            kind = ActivationKind.valueOf((item.getValue("kind") as AttributeValue.S).value),
            requestId = (item["request_id"] as? AttributeValue.S)?.value?.toId(),
            producerRequestId = (item["producer_request_id"] as? AttributeValue.S)?.value?.toId(),
            // Removed by anonymiseByMemberInvitationId: an index key cannot be an empty string.
            adminEmail = (item["admin_email"] as? AttributeValue.S)?.value.orEmpty(),
            organizationId = (item["organization_id"] as? AttributeValue.S)?.value?.toId(),
            producerAccountId = (item["producer_account_id"] as? AttributeValue.S)?.value?.toId(),
            ownerInvitationId = (item["owner_invitation_id"] as? AttributeValue.S)?.value?.toId(),
            memberInvitationId = (item["member_invitation_id"] as? AttributeValue.S)?.value?.toId(),
            createdAt = Instant.fromEpochMilliseconds((item.getValue("created_at") as AttributeValue.N).value.toLong()),
            expiresAt = Instant.fromEpochMilliseconds((item.getValue("expires_at") as AttributeValue.N).value.toLong()),
            invalidatedAt = (item["invalidated_at"] as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
            activatedAt = (item["activated_at"] as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
        )
    }

    override suspend fun markActivated(
        token: String,
        activatedAt: Instant,
    ) {
        client.client.updateItem(
            UpdateItemRequest {
                tableName = client.table
                key =
                    mapOf(
                        "pk" to AttributeValue.S("ACTIVATION_TOKEN"),
                        "sk" to AttributeValue.S(token),
                    )
                updateExpression = "SET activated_at = :activated_at"
                expressionAttributeValues =
                    mapOf(
                        ":activated_at" to AttributeValue.N(activatedAt.toEpochMilliseconds().toString()),
                    )
            },
        )
    }

    override suspend fun invalidateByOwnerInvitationId(
        invitationId: Id<OwnerInvitation>,
        invalidatedAt: Instant,
    ) {
        invalidateWhere("owner_invitation_id", invitationId.id, invalidatedAt)
    }

    override suspend fun invalidateByMemberInvitationId(
        invitationId: Id<MemberInvitation>,
        invalidatedAt: Instant,
    ) {
        invalidateWhere("member_invitation_id", invitationId.id, invalidatedAt)
    }

    override suspend fun anonymiseByMemberInvitationId(invitationId: Id<MemberInvitation>) {
        tokenKeysWhere("member_invitation_id", invitationId.id).forEach { token ->
            client.client.updateItem(
                UpdateItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S("ACTIVATION_TOKEN"),
                            "sk" to AttributeValue.S(token),
                        )
                    // admin_email keys a secondary index, which rejects an empty string.
                    updateExpression = "REMOVE admin_email"
                },
            )
        }
    }

    override suspend fun invalidateByOrganizationRequestId(
        requestId: Id<OrganizationRequest>,
        invalidatedAt: Instant,
    ) {
        invalidateWhere("request_id", requestId.id, invalidatedAt)
    }

    override suspend fun invalidateByProducerRequestId(
        requestId: Id<ProducerRequest>,
        invalidatedAt: Instant,
    ) {
        invalidateWhere("producer_request_id", requestId.id, invalidatedAt)
    }

    /** The token ids (sort keys) whose [attributeName] equals [referenceId]. */
    private suspend fun tokenKeysWhere(
        attributeName: String,
        referenceId: String,
    ): List<String> =
        client.client
            .query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "$attributeName = :reference_id"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S("ACTIVATION_TOKEN"),
                            ":reference_id" to AttributeValue.S(referenceId),
                        )
                },
            ).items
            .orEmpty()
            .mapNotNull { (it["sk"] as? AttributeValue.S)?.value }

    private suspend fun invalidateWhere(
        attributeName: String,
        referenceId: String,
        invalidatedAt: Instant,
    ) {
        tokenKeysWhere(attributeName, referenceId).forEach { token ->
            client.client.updateItem(
                UpdateItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S("ACTIVATION_TOKEN"),
                            "sk" to AttributeValue.S(token),
                        )
                    updateExpression = "SET invalidated_at = :invalidated_at"
                    expressionAttributeValues =
                        mapOf(
                            ":invalidated_at" to AttributeValue.N(invalidatedAt.toEpochMilliseconds().toString()),
                        )
                },
            )
        }
    }
}

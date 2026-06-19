@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import authentication.Role
import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactionCanceledException
import id.Id
import id.toId
import kotlinx.serialization.builtins.SetSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.DuplicatePendingInvitationException
import persistence.dao.MemberInvitationSyncDAO
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "MINV"
private const val LOCK_PK_PREFIX = "MINV_LOCK#"
private const val LOCK_SK = "LOCK"

@Single(createdAtStart = true, binds = [MemberInvitationSyncDAO::class])
internal class MemberInvitationSyncDynamoDAO(
    private val client: DynamoClient,
) : MemberInvitationSyncDAO {
    override suspend fun put(
        invitation: MemberInvitation,
        change: Change,
    ) {
        val lockPk = "$LOCK_PK_PREFIX${invitation.email}"
        val transactItems =
            buildList {
                add(
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = client.table
                                item = invitation.toAttributeValueMap()
                            }
                    },
                )
                add(
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = client.table
                                item = change.toAttributeValueMap()
                            }
                    },
                )
                when (invitation.status) {
                    MemberInvitationStatus.PENDING_ACTIVATION -> {
                        // Acquire or hold the email lock.
                        // Condition: no lock exists for this email, OR the lock has expired (ttl < now,
                        // covering the up-to-48h AWS TTL delay window), OR the lock is already held by
                        // this invitation (idempotent resend).
                        val nowEpochSeconds =
                            kotlin.time.Clock.System
                                .now()
                                .epochSeconds
                        add(
                            TransactWriteItem {
                                put =
                                    Put {
                                        tableName = client.table
                                        item =
                                            mapOf(
                                                "pk" to AttributeValue.S(lockPk),
                                                "sk" to AttributeValue.S(LOCK_SK),
                                                "invitation_id" to AttributeValue.S(invitation.invitationId),
                                                "ttl" to AttributeValue.N(invitation.expiresAt.epochSeconds.toString()),
                                            )
                                        conditionExpression =
                                            "attribute_not_exists(pk) OR #ttl < :now OR invitation_id = :inv_id"
                                        expressionAttributeNames = mapOf("#ttl" to "ttl")
                                        expressionAttributeValues =
                                            mapOf(
                                                ":inv_id" to AttributeValue.S(invitation.invitationId),
                                                ":now" to AttributeValue.N(nowEpochSeconds.toString()),
                                            )
                                    }
                            },
                        )
                    }

                    MemberInvitationStatus.ACTIVATED, MemberInvitationStatus.CANCELLED -> {
                        // Release the email lock so the email can be re-invited in the future.
                        add(
                            TransactWriteItem {
                                delete =
                                    Delete {
                                        tableName = client.table
                                        key =
                                            mapOf(
                                                "pk" to AttributeValue.S(lockPk),
                                                "sk" to AttributeValue.S(LOCK_SK),
                                            )
                                    }
                            },
                        )
                    }
                }
            }

        try {
            client.client.transactWriteItems(
                TransactWriteItemsRequest {
                    this.transactItems = transactItems
                },
            )
        } catch (e: TransactionCanceledException) {
            // A ConditionalCheckFailed reason on the lock item means a concurrent PENDING invitation
            // already holds the lock for this email.
            val isTakenLock =
                e.cancellationReasons
                    ?.any { it.code == "ConditionalCheckFailed" }
                    ?: false
            if (isTakenLock) throw DuplicatePendingInvitationException()
            throw e
        }
    }

    override suspend fun findById(invitationId: String): MemberInvitation? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(invitationId),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toMemberInvitation()
    }

    override suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberInvitation> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "organization_id = :org_id"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PK),
                            ":org_id" to AttributeValue.S(organizationId.id),
                        )
                },
            )
        return response.items.orEmpty().map { it.toMemberInvitation() }
    }

    override suspend fun findPendingByEmail(email: String): MemberInvitation? {
        // Step 1: look up the email lock item to find the invitation id.
        val lockPk = "$LOCK_PK_PREFIX$email"
        val lockResponse =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(lockPk),
                            "sk" to AttributeValue.S(LOCK_SK),
                        )
                },
            )
        val lockItem = lockResponse.item?.takeIf { it.isNotEmpty() } ?: return null
        val invitationId = (lockItem["invitation_id"] as? AttributeValue.S)?.value ?: return null

        // Step 2: fetch the invitation row by its id.
        return findById(invitationId)
    }
}

private fun MemberInvitation.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PK))
        put("sk", AttributeValue.S(invitationId))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("email", AttributeValue.S(email))
        put("first_name", AttributeValue.S(firstName))
        put("last_name", AttributeValue.S(lastName))
        put("roles", AttributeValue.S(json.encodeToString(SetSerializer(Role.serializer()), roles)))
        put("status", AttributeValue.S(status.name))
        put("created_at", AttributeValue.N(createdAt.toEpochMilliseconds().toString()))
        put("expires_at", AttributeValue.N(expiresAt.toEpochMilliseconds().toString()))
        resendRequestedAt?.let { put("resend_requested_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        activatedAt?.let { put("activated_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
        customEmailSubject?.let { put("custom_email_subject", AttributeValue.S(it)) }
        customEmailBody?.let { put("custom_email_body", AttributeValue.S(it)) }
    }

private fun Map<String, AttributeValue>.toMemberInvitation(): MemberInvitation =
    MemberInvitation(
        invitationId = (getValue("sk") as AttributeValue.S).value,
        organizationId = (getValue("organization_id") as AttributeValue.S).value.toId(),
        email = (getValue("email") as AttributeValue.S).value,
        firstName = (getValue("first_name") as AttributeValue.S).value,
        lastName = (getValue("last_name") as AttributeValue.S).value,
        roles = json.decodeFromString(SetSerializer(Role.serializer()), (getValue("roles") as AttributeValue.S).value),
        status = MemberInvitationStatus.valueOf((getValue("status") as AttributeValue.S).value),
        createdAt = Instant.fromEpochMilliseconds((getValue("created_at") as AttributeValue.N).value.toLong()),
        expiresAt = Instant.fromEpochMilliseconds((getValue("expires_at") as AttributeValue.N).value.toLong()),
        resendRequestedAt =
            (get("resend_requested_at") as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
        activatedAt = (get("activated_at") as? AttributeValue.N)?.value?.toLong()?.let(Instant::fromEpochMilliseconds),
        customEmailSubject = (get("custom_email_subject") as? AttributeValue.S)?.value,
        customEmailBody = (get("custom_email_body") as? AttributeValue.S)?.value,
    )

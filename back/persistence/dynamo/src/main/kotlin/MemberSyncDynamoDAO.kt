@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import authentication.Role
import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.MemberSyncDAO
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContract
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.UserPreferences
import persistence.model.UserSettings
import serialization.json
import kotlin.time.ExperimentalTime

/**
 * Dynamo pk prefix for the lightweight sub→organizationId lookup items.
 *
 * Each account-backed member creation atomically writes a secondary item
 * `pk=MEMBER_SUB#<memberId>, sk=LOOKUP` that maps the auth subject to its
 * organization id. One partition per member avoids a hot-partition on a
 * shared pk. The [MemberSyncDAO.findOrganizationIdBySub] method reads this
 * item directly instead of scanning the full member table.
 */
private const val MEMBER_SUB_PK_PREFIX = "MEMBER_SUB#"
private const val MEMBER_SUB_SK = "LOOKUP"

@Single(createdAtStart = true, binds = [MemberSyncDAO::class])
internal class MemberSyncDynamoDAO(
    private val client: DynamoClient,
) : MemberSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Member> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("MEMBER#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toMember() }
    }

    override suspend fun listAll(): List<Member> {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    // Filter by entity_type AND presence of member_id to exclude Change tombstone/upsert records
                    // which share the same entity_type but lack the member_id attribute.
                    filterExpression = "entity_type = :et AND attribute_exists(member_id)"
                    expressionAttributeValues = mapOf(":et" to AttributeValue.S("Member"))
                },
            )
        return response.items.orEmpty().map { it.toMember() }
    }

    override suspend fun findOrganizationIdBySub(sub: String): Id<Organization>? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S("$MEMBER_SUB_PK_PREFIX$sub"),
                            "sk" to AttributeValue.S(MEMBER_SUB_SK),
                        )
                },
            )
        val item = response.item ?: return null
        if (item.isEmpty()) return null
        return item["organization_id"]?.asS()?.toId()
    }

    override suspend fun getMembersBySub(sub: String): List<Member> {
        // Since memberId == sub by convention, a member row lives at
        // pk=MEMBER#<orgId>, sk=<sub>. We look up the orgId first via
        // the lightweight lookup item, then fetch the single member row.
        val organizationId = findOrganizationIdBySub(sub) ?: return emptyList()
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk AND sk = :sk"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S("MEMBER#${organizationId.id}"),
                            ":sk" to AttributeValue.S(sub),
                        )
                },
            )
        return response.items.orEmpty().map { it.toMember() }
    }

    override suspend fun put(
        member: Member,
        changes: List<Change>,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        add(
                            TransactWriteItem {
                                put =
                                    Put {
                                        tableName = client.table
                                        item = member.toAttributeValueMap()
                                    }
                            },
                        )
                        // Write the lightweight sub→organizationId lookup item atomically.
                        add(
                            TransactWriteItem {
                                put =
                                    Put {
                                        tableName = client.table
                                        item =
                                            mapOf(
                                                "pk" to AttributeValue.S("$MEMBER_SUB_PK_PREFIX${member.memberId.id}"),
                                                "sk" to AttributeValue.S(MEMBER_SUB_SK),
                                                "organization_id" to AttributeValue.S(member.organizationId.id),
                                            )
                                    }
                            },
                        )
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }

    override suspend fun delete(
        memberId: Id<Member>,
        organizationId: Id<Organization>,
        changes: List<Change>,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        add(
                            TransactWriteItem {
                                delete =
                                    Delete {
                                        tableName = client.table
                                        key =
                                            mapOf(
                                                "pk" to AttributeValue.S("MEMBER#${organizationId.id}"),
                                                "sk" to AttributeValue.S(memberId.id),
                                            )
                                    }
                            },
                        )
                        // Also delete the lookup item.
                        add(
                            TransactWriteItem {
                                delete =
                                    Delete {
                                        tableName = client.table
                                        key =
                                            mapOf(
                                                "pk" to AttributeValue.S("$MEMBER_SUB_PK_PREFIX${memberId.id}"),
                                                "sk" to AttributeValue.S(MEMBER_SUB_SK),
                                            )
                                    }
                            },
                        )
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }

    override suspend fun setActiveStatusBySub(
        sub: String,
        activeStatus: Boolean,
        changes: List<Change>,
    ) {
        // Since memberId == sub, we find the member via the lookup item
        // and update the single row directly.
        val members = getMembersBySub(sub)
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        members.forEach { member ->
                            add(
                                TransactWriteItem {
                                    update =
                                        aws.sdk.kotlin.services.dynamodb.model.Update {
                                            tableName = client.table
                                            key =
                                                mapOf(
                                                    "pk" to
                                                        AttributeValue.S(
                                                            "MEMBER#${member.organizationId.id}",
                                                        ),
                                                    "sk" to AttributeValue.S(member.memberId.id),
                                                )
                                            updateExpression = "SET active_status = :status, account_status = :account_status"
                                            expressionAttributeValues =
                                                mapOf(
                                                    ":status" to AttributeValue.Bool(activeStatus),
                                                    ":account_status" to
                                                        AttributeValue.S(
                                                            if (activeStatus) {
                                                                MemberAccountStatus.ACTIVE.name
                                                            } else {
                                                                MemberAccountStatus.SUSPENDED.name
                                                            },
                                                        ),
                                                )
                                        }
                                },
                            )
                        }
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }

    override suspend fun anonymiseBySub(
        sub: String,
        changes: List<Change>,
    ) {
        // Since memberId == sub, we find the member via the lookup item.
        val members = getMembersBySub(sub)
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    buildList {
                        members.forEach { member ->
                            add(
                                TransactWriteItem {
                                    update =
                                        aws.sdk.kotlin.services.dynamodb.model.Update {
                                            tableName = client.table
                                            key =
                                                mapOf(
                                                    "pk" to
                                                        AttributeValue.S(
                                                            "MEMBER#${member.organizationId.id}",
                                                        ),
                                                    "sk" to AttributeValue.S(member.memberId.id),
                                                )
                                            updateExpression =
                                                "REMOVE first_name, last_name, email, phone " +
                                                "SET active_status = :false_val, account_status = :account_status"
                                            expressionAttributeValues =
                                                mapOf(
                                                    ":false_val" to AttributeValue.Bool(false),
                                                    ":account_status" to AttributeValue.S(MemberAccountStatus.SUSPENDED.name),
                                                )
                                        }
                                },
                            )
                        }
                        changes.forEach { change ->
                            add(
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                },
                            )
                        }
                    }
            },
        )
    }
}

private fun Member.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("MEMBER#${organizationId.id}"))
        put("sk", AttributeValue.S(memberId.id))
        put("entity_type", AttributeValue.S("Member"))
        put("member_id", AttributeValue.S(memberId.id))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("roles", AttributeValue.Ss(roles.map { it.name }))
        put("active_status", AttributeValue.Bool(activeStatus))
        firstName?.let { put("first_name", AttributeValue.S(it)) }
        lastName?.let { put("last_name", AttributeValue.S(it)) }
        email?.let { put("email", AttributeValue.S(it)) }
        phone?.let { put("phone", AttributeValue.S(it)) }
        accountStatus?.let { put("account_status", AttributeValue.S(it.name)) }
        put(
            "contracts",
            AttributeValue.S(json.encodeToString(ListSerializer(MemberContract.serializer()), contracts)),
        )
        put(
            "registrations",
            AttributeValue.S(json.encodeToString(ListSerializer(MemberRegistration.serializer()), registrations)),
        )
        put("member_settings", AttributeValue.S(json.encodeToString(MemberSettings.serializer(), memberSettings)))
        put(
            "member_preferences",
            AttributeValue.S(json.encodeToString(MemberPreferences.serializer(), memberPreferences)),
        )
        put("user_preferences", AttributeValue.S(json.encodeToString(UserPreferences.serializer(), userPreferences)))
        put("user_settings", AttributeValue.S(json.encodeToString(UserSettings.serializer(), userSettings)))
    }

private fun Map<String, AttributeValue>.toMember(): Member =
    Member(
        memberId = getValue("member_id").asS().toId(),
        organizationId = getValue("organization_id").asS().toId(),
        roles = get("roles")?.asSs()?.mapNotNull { Role.fromString(it) }?.toSet() ?: setOf(Role.VOLUNTEER),
        activeStatus = getValue("active_status").asBool(),
        firstName = get("first_name")?.asS(),
        lastName = get("last_name")?.asS(),
        email = get("email")?.asS(),
        phone = get("phone")?.asS(),
        accountStatus =
            get("account_status")?.asS()?.let { value ->
                runCatching { MemberAccountStatus.valueOf(value) }.getOrNull()
            },
        contracts =
            json.decodeFromString(
                ListSerializer(MemberContract.serializer()),
                get("contracts")?.asS() ?: "[]",
            ),
        registrations =
            json.decodeFromString(
                ListSerializer(MemberRegistration.serializer()),
                get("registrations")?.asS() ?: "[]",
            ),
        memberSettings =
            json.decodeFromString(
                MemberSettings.serializer(),
                getValue("member_settings").asS(),
            ),
        memberPreferences =
            json.decodeFromString(
                MemberPreferences.serializer(),
                getValue("member_preferences").asS(),
            ),
        userPreferences =
            json.decodeFromString(
                UserPreferences.serializer(),
                getValue("user_preferences").asS(),
            ),
        userSettings =
            json.decodeFromString(
                UserSettings.serializer(),
                getValue("user_settings").asS(),
            ),
    )

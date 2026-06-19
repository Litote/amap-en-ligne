@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import aws.sdk.kotlin.services.dynamodb.model.Update
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.Member
import persistence.model.Owner
import persistence.model.UserPreferences
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "OWNER"

@Single(createdAtStart = true, binds = [OwnerSyncDAO::class])
internal class OwnerSyncDynamoDAO(
    private val client: DynamoClient,
) : OwnerSyncDAO {
    override suspend fun listAll(): List<Owner> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S(PK))
                },
            )
        return response.items.orEmpty().map { it.toOwner() }
    }

    override suspend fun findById(ownerId: Id<Owner>): Owner? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(ownerId.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toOwner()
    }

    override suspend fun put(
        owner: Owner,
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
                                    item = owner.toAttributeValueMap()
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

    override suspend fun updateStatus(
        ownerId: Id<Owner>,
        accountStatus: AccountStatus,
        change: Change,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    listOf(
                        TransactWriteItem {
                            update =
                                Update {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S(PK),
                                            "sk" to AttributeValue.S(ownerId.id),
                                        )
                                    updateExpression = "SET account_status = :status"
                                    expressionAttributeValues =
                                        mapOf(":status" to AttributeValue.S(accountStatus.name))
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

    override suspend fun existsByEmail(email: String): Boolean {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    filterExpression = "email = :email"
                    expressionAttributeValues =
                        mapOf(
                            ":pk" to AttributeValue.S(PK),
                            ":email" to AttributeValue.S(email),
                        )
                },
            )
        return response.count > 0
    }

    override suspend fun existsBySub(sub: String): Boolean {
        // Since ownerId == sub by convention, existsBySub is equivalent to findById != null.
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(sub),
                        )
                },
            )
        return response.item?.isNotEmpty() == true
    }

    override suspend fun findBySub(sub: String): Owner? {
        // Since ownerId == sub by convention, findBySub is equivalent to findById.
        return findById(Id(sub))
    }

    override suspend fun delete(
        ownerId: Id<Owner>,
        change: Change,
    ) {
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems =
                    listOf(
                        TransactWriteItem {
                            delete =
                                Delete {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S(PK),
                                            "sk" to AttributeValue.S(ownerId.id),
                                        )
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

    override suspend fun promoteToOwner(
        owner: Owner,
        ownerChange: Change,
        membersToRevoke: List<Member>,
        memberChanges: List<Change>,
    ) {
        val items =
            buildList {
                // Insert new owner row
                add(
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = client.table
                                item = owner.toAttributeValueMap()
                            }
                    },
                )
                // Write owner Change record
                add(
                    TransactWriteItem {
                        put =
                            Put {
                                tableName = client.table
                                item = ownerChange.toAttributeValueMap()
                            }
                    },
                )
                // Delete each member row
                membersToRevoke.forEach { member ->
                    add(
                        TransactWriteItem {
                            delete =
                                Delete {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S("MEMBER#${member.organizationId.id}"),
                                            "sk" to AttributeValue.S(member.memberId.id),
                                        )
                                }
                        },
                    )
                }
                memberChanges.forEach { change ->
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
        client.client.transactWriteItems(
            TransactWriteItemsRequest {
                transactItems = items
            },
        )
    }
}

private fun Owner.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(PK))
        put("sk", AttributeValue.S(ownerId.id))
        put("entity_type", AttributeValue.S("Owner"))
        put("owner_id", AttributeValue.S(ownerId.id))
        put("first_name", AttributeValue.S(firstName))
        put("last_name", AttributeValue.S(lastName))
        put("email", AttributeValue.S(email))
        phone?.let { put("phone", AttributeValue.S(it)) }
        put("account_status", AttributeValue.S(accountStatus.name))
        put("registered_at", AttributeValue.N(registeredAt.toEpochMilliseconds().toString()))
        put("updated_at", AttributeValue.N(updatedAt.toEpochMilliseconds().toString()))
        put("user_preferences", AttributeValue.S(json.encodeToString(UserPreferences.serializer(), userPreferences)))
    }

private val defaultUserPreferences =
    UserPreferences(
        emailNotificationsEnabled = true,
        pushNotificationsEnabled = false,
        lastUpdatedInstant = Instant.fromEpochMilliseconds(0L),
    )

private fun Map<String, AttributeValue>.toOwner(): Owner =
    Owner(
        ownerId = getValue("owner_id").asS().toId(),
        firstName = getValue("first_name").asS(),
        lastName = getValue("last_name").asS(),
        email = getValue("email").asS(),
        phone = get("phone")?.asS(),
        accountStatus = AccountStatus.valueOf(getValue("account_status").asS()),
        registeredAt = Instant.fromEpochMilliseconds(getValue("registered_at").asN().toLong()),
        updatedAt = Instant.fromEpochMilliseconds(getValue("updated_at").asN().toLong()),
        userPreferences =
            get("user_preferences")?.asS()?.let {
                json.decodeFromString(UserPreferences.serializer(), it)
            } ?: defaultUserPreferences,
    )

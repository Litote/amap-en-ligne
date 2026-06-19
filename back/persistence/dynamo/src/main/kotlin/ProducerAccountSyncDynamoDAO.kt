@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Delete
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import aws.sdk.kotlin.services.dynamodb.model.Update
import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.LinkedProducerAccount
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.ProducerProduct
import persistence.model.UserPreferences
import serialization.json
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ProducerAccountSyncDAO::class])
internal class ProducerAccountSyncDynamoDAO(
    private val client: DynamoClient,
) : ProducerAccountSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<ProducerAccount> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("PA#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toProducerAccount() }
    }

    override suspend fun put(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
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
                                        item = producerAccount.toAttributeValueMap(organizationId)
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
        producerAccountId: Id<ProducerAccount>,
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
                                                "pk" to AttributeValue.S("PA#${organizationId.id}"),
                                                "sk" to AttributeValue.S(producerAccountId.id),
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

    override suspend fun listAll(): List<ProducerAccount> {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "entity_type = :entity_type AND begins_with(pk, :pk_prefix)"
                    expressionAttributeValues =
                        mapOf(
                            ":entity_type" to AttributeValue.S("ProducerAccount"),
                            ":pk_prefix" to AttributeValue.S("PA#"),
                        )
                },
            )
        return response.items
            .orEmpty()
            .map { it.toProducerAccount() }
            .deduplicate()
    }

    override suspend fun findById(producerAccountId: Id<ProducerAccount>): ProducerAccount? {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "entity_type = :entity_type AND begins_with(pk, :pk_prefix) AND sk = :sk"
                    expressionAttributeValues =
                        mapOf(
                            ":entity_type" to AttributeValue.S("ProducerAccount"),
                            ":pk_prefix" to AttributeValue.S("PA#"),
                            ":sk" to AttributeValue.S(producerAccountId.id),
                        )
                },
            )
        return response.items
            .orEmpty()
            .map { it.toProducerAccount() }
            .deduplicate()
            .firstOrNull()
    }

    override suspend fun updateActiveStatus(
        producerAccountId: Id<ProducerAccount>,
        activeStatus: Boolean,
        changes: List<Change>,
    ) {
        // Scan to find every pk under which this producer is stored — one row
        // per org link in the denormalised schema. Then transact-write the
        // status flip on every row + the change tombstones in a single op.
        val rows =
            client.client
                .scan(
                    ScanRequest {
                        tableName = client.table
                        filterExpression = "entity_type = :entity_type AND begins_with(pk, :pk_prefix) AND sk = :sk"
                        expressionAttributeValues =
                            mapOf(
                                ":entity_type" to AttributeValue.S("ProducerAccount"),
                                ":pk_prefix" to AttributeValue.S("PA#"),
                                ":sk" to AttributeValue.S(producerAccountId.id),
                            )
                    },
                ).items
                .orEmpty()
        if (rows.isEmpty()) {
            // Idempotent — nothing to update but still write the Changes so
            // the OWNER feed records the (no-op) flip.
            if (changes.isNotEmpty()) {
                client.client.transactWriteItems(
                    TransactWriteItemsRequest {
                        transactItems =
                            changes.map { change ->
                                TransactWriteItem {
                                    put =
                                        Put {
                                            tableName = client.table
                                            item = change.toAttributeValueMap()
                                        }
                                }
                            }
                    },
                )
            }
            return
        }
        val items =
            buildList {
                rows.forEach { row ->
                    val pk = row.getValue("pk").asS()
                    add(
                        TransactWriteItem {
                            update =
                                Update {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S(pk),
                                            "sk" to AttributeValue.S(producerAccountId.id),
                                        )
                                    updateExpression =
                                        "SET active_status = :status, last_updated_instant = :ts"
                                    expressionAttributeValues =
                                        mapOf(
                                            ":status" to AttributeValue.Bool(activeStatus),
                                            ":ts" to AttributeValue.N(System.currentTimeMillis().toString()),
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
        client.client.transactWriteItems(
            TransactWriteItemsRequest { transactItems = items },
        )
    }

    override suspend fun search(
        organizationId: Id<Organization>,
        query: String,
    ): List<ProducerAccount> {
        val existingIds =
            getByOrganizationId(organizationId)
        val excludedIds =
            buildSet {
                addAll(existingIds.map { it.producerAccountId.id })
                addAll(
                    existingIds
                        .filter { it.managementMode == ProducerManagementMode.NO_ACCOUNT }
                        .mapNotNull { it.linkedProducerAccount?.producerAccountId?.id },
                )
            }

        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "entity_type = :et AND begins_with(pk, :pk_prefix) AND active_status = :active"
                    expressionAttributeValues =
                        mapOf(
                            ":et" to AttributeValue.S("ProducerAccount"),
                            ":pk_prefix" to AttributeValue.S("PA#"),
                            ":active" to AttributeValue.Bool(true),
                        )
                },
            )
        val lowerQuery = query.lowercase()
        return response.items
            .orEmpty()
            .map { it.toProducerAccount() }
            .deduplicate()
            .filter { pa ->
                pa.managementMode == ProducerManagementMode.ACCOUNT_BACKED &&
                    pa.producerAccountId.id !in excludedIds &&
                    (
                        pa.name.lowercase().contains(lowerQuery) ||
                            pa.contactEmail?.lowercase()?.contains(lowerQuery) == true
                    )
            }.take(20)
    }

    override suspend fun createInitial(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
    ) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = producerAccount.toAttributeValueMap(organizationId)
            },
        )
    }

    override suspend fun createStandalone(producerAccount: ProducerAccount) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = producerAccount.toStandaloneAttributeValueMap()
            },
        )
    }

    override suspend fun updateProfile(
        producerAccount: ProducerAccount,
        changes: List<Change>,
    ) {
        // Scan to find every pk under which this producer is stored — one row
        // per org link (PA#<orgId>) plus a standalone row (PA#UNASSIGNED).
        val rows =
            client.client
                .scan(
                    ScanRequest {
                        tableName = client.table
                        filterExpression =
                            "entity_type = :entity_type AND begins_with(pk, :pk_prefix) AND sk = :sk"
                        expressionAttributeValues =
                            mapOf(
                                ":entity_type" to AttributeValue.S("ProducerAccount"),
                                ":pk_prefix" to AttributeValue.S("PA#"),
                                ":sk" to AttributeValue.S(producerAccount.producerAccountId.id),
                            )
                    },
                ).items
                .orEmpty()

        val setExpressionParts = mutableListOf<String>()
        val removeExpressionParts = mutableListOf<String>()
        val expressionAttributeValues = mutableMapOf<String, AttributeValue>()
        val expressionAttributeNames = mutableMapOf<String, String>()

        // `name` is a DynamoDB reserved word — use an alias.
        expressionAttributeNames["#n"] = "name"
        setExpressionParts.add("#n = :name")
        expressionAttributeValues[":name"] = AttributeValue.S(producerAccount.name)

        producerAccount.contactEmail?.let { contactEmail ->
            setExpressionParts.add("contact_email = :contact_email")
            expressionAttributeValues[":contact_email"] = AttributeValue.S(contactEmail)
        } ?: run {
            removeExpressionParts.add("contact_email")
        }
        producerAccount.address?.let { address ->
            setExpressionParts.add("address = :address")
            expressionAttributeValues[":address"] = AttributeValue.S(address)
        } ?: run {
            removeExpressionParts.add("address")
        }
        producerAccount.website?.let { website ->
            setExpressionParts.add("website = :website")
            expressionAttributeValues[":website"] = AttributeValue.S(website)
        } ?: run {
            removeExpressionParts.add("website")
        }
        setExpressionParts.add("last_updated_instant = :ts")
        expressionAttributeValues[":ts"] =
            AttributeValue.N(producerAccount.lastUpdatedInstant.toEpochMilliseconds().toString())

        val updateExpression =
            buildString {
                append("SET ")
                append(setExpressionParts.joinToString(", "))
                if (removeExpressionParts.isNotEmpty()) {
                    append(" REMOVE ")
                    append(removeExpressionParts.joinToString(", "))
                }
            }

        val items =
            buildList {
                rows.forEach { row ->
                    val pk = row.getValue("pk").asS()
                    add(
                        TransactWriteItem {
                            update =
                                Update {
                                    tableName = client.table
                                    key =
                                        mapOf(
                                            "pk" to AttributeValue.S(pk),
                                            "sk" to AttributeValue.S(producerAccount.producerAccountId.id),
                                        )
                                    this.updateExpression = updateExpression
                                    this.expressionAttributeValues = expressionAttributeValues
                                    this.expressionAttributeNames = expressionAttributeNames
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

        if (items.isNotEmpty()) {
            client.client.transactWriteItems(
                TransactWriteItemsRequest { transactItems = items },
            )
        }
    }
}

private fun ProducerAccount.toAttributeValueMap(organizationId: Id<Organization>): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("PA#${organizationId.id}"))
        put("sk", AttributeValue.S(producerAccountId.id))
        put("entity_type", AttributeValue.S("ProducerAccount"))
        put("name", AttributeValue.S(name))
        contactEmail?.let { put("contact_email", AttributeValue.S(it)) }
        address?.let { put("address", AttributeValue.S(it)) }
        website?.let { put("website", AttributeValue.S(it)) }
        put("active_status", AttributeValue.Bool(activeStatus))
        put("created_instant", AttributeValue.N(createdInstant.toEpochMilliseconds().toString()))
        put("last_updated_instant", AttributeValue.N(lastUpdatedInstant.toEpochMilliseconds().toString()))
        put("management_mode", AttributeValue.S(managementMode.name))
        linkedProducerAccount?.let {
            put("linked_producer_account_id", AttributeValue.S(it.producerAccountId.id))
            put("linked_producer_account_name", AttributeValue.S(it.name))
        }
        put(
            "organizations",
            AttributeValue.S(json.encodeToString(ListSerializer(ProducerOrganization.serializer()), organizations)),
        )
        put(
            "products",
            AttributeValue.S(json.encodeToString(ListSerializer(ProducerProduct.serializer()), products)),
        )
        put("user_preferences", AttributeValue.S(json.encodeToString(UserPreferences.serializer(), userPreferences)))
    }

private fun ProducerAccount.toStandaloneAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("PA#UNASSIGNED"))
        put("sk", AttributeValue.S(producerAccountId.id))
        put("entity_type", AttributeValue.S("ProducerAccount"))
        put("name", AttributeValue.S(name))
        contactEmail?.let { put("contact_email", AttributeValue.S(it)) }
        address?.let { put("address", AttributeValue.S(it)) }
        website?.let { put("website", AttributeValue.S(it)) }
        put("active_status", AttributeValue.Bool(activeStatus))
        put("created_instant", AttributeValue.N(createdInstant.toEpochMilliseconds().toString()))
        put("last_updated_instant", AttributeValue.N(lastUpdatedInstant.toEpochMilliseconds().toString()))
        put("management_mode", AttributeValue.S(managementMode.name))
        linkedProducerAccount?.let {
            put("linked_producer_account_id", AttributeValue.S(it.producerAccountId.id))
            put("linked_producer_account_name", AttributeValue.S(it.name))
        }
        put("organizations", AttributeValue.S(json.encodeToString(ListSerializer(ProducerOrganization.serializer()), organizations)))
        put("products", AttributeValue.S(json.encodeToString(ListSerializer(ProducerProduct.serializer()), products)))
        put("user_preferences", AttributeValue.S(json.encodeToString(UserPreferences.serializer(), userPreferences)))
    }

private val defaultProducerUserPreferences =
    UserPreferences(
        emailNotificationsEnabled = true,
        pushNotificationsEnabled = false,
        lastUpdatedInstant = Instant.fromEpochMilliseconds(0L),
    )

private fun Map<String, AttributeValue>.toProducerAccount(): ProducerAccount =
    ProducerAccount(
        producerAccountId = getValue("sk").asS().toId(),
        name = getValue("name").asS(),
        contactEmail = get("contact_email")?.asS(),
        address = get("address")?.asS(),
        website = get("website")?.asS(),
        activeStatus = getValue("active_status").asBool(),
        createdInstant = Instant.fromEpochMilliseconds(getValue("created_instant").asN().toLong()),
        lastUpdatedInstant = Instant.fromEpochMilliseconds(getValue("last_updated_instant").asN().toLong()),
        users = emptyList(),
        organizations =
            json.decodeFromString(
                ListSerializer(ProducerOrganization.serializer()),
                getValue("organizations").asS(),
            ),
        products =
            json.decodeFromString(
                ListSerializer(ProducerProduct.serializer()),
                getValue("products").asS(),
            ),
        userPreferences =
            get("user_preferences")?.asS()?.let {
                json.decodeFromString(UserPreferences.serializer(), it)
            } ?: defaultProducerUserPreferences,
        managementMode =
            get("management_mode")?.asS()?.let(ProducerManagementMode::valueOf)
                ?: ProducerManagementMode.ACCOUNT_BACKED,
        linkedProducerAccount =
            get("linked_producer_account_id")?.asS()?.toId<ProducerAccount>()?.let { linkedProducerAccountId ->
                LinkedProducerAccount(
                    producerAccountId = linkedProducerAccountId,
                    name = get("linked_producer_account_name")?.asS() ?: "",
                )
            },
    )

private fun List<ProducerAccount>.deduplicate(): List<ProducerAccount> =
    groupBy { it.producerAccountId }
        .values
        .map { accounts ->
            val representative = accounts.maxBy { it.organizations.size * 1000 + it.products.size }
            representative.copy(
                organizations = accounts.flatMap { it.organizations }.distinctBy { it.organizationId },
                products = accounts.flatMap { it.products }.distinctBy { it.productTypeId },
            )
        }

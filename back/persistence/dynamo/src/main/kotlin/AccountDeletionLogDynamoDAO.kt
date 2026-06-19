@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.GetItemRequest
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.dao.AccountDeletionLogDAO
import persistence.model.AccountDeletionLog
import persistence.model.DeletedAccountRole
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val PK = "ACCT_DEL_LOG"

@Single(createdAtStart = true, binds = [AccountDeletionLogDAO::class])
internal class AccountDeletionLogDynamoDAO(
    private val client: DynamoClient,
) : AccountDeletionLogDAO {
    override suspend fun append(entry: AccountDeletionLog) {
        client.client.putItem(
            PutItemRequest {
                tableName = client.table
                item = entry.toAttributeValueMap()
            },
        )
    }

    override suspend fun listAll(): List<AccountDeletionLog> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(PK))
                },
            )
        return response.items.orEmpty().map { it.toAccountDeletionLog() }
    }

    override suspend fun findById(id: Id<AccountDeletionLog>): AccountDeletionLog? {
        val response =
            client.client.getItem(
                GetItemRequest {
                    tableName = client.table
                    key =
                        mapOf(
                            "pk" to AttributeValue.S(PK),
                            "sk" to AttributeValue.S(id.id),
                        )
                },
            )
        return response.item?.takeIf { it.isNotEmpty() }?.toAccountDeletionLog()
    }
}

private fun AccountDeletionLog.toAttributeValueMap(): Map<String, AttributeValue> =
    mapOf(
        "pk" to AttributeValue.S(PK),
        "sk" to AttributeValue.S(id.id),
        "entity_type" to AttributeValue.S("AccountDeletionLog"),
        "deleted_sub_hash" to AttributeValue.S(deletedSubHash),
        "deleted_role" to AttributeValue.S(deletedRole.name),
        "deleted_at" to AttributeValue.N(deletedAt.toEpochMilliseconds().toString()),
        "actor_owner_id" to AttributeValue.S(actorOwnerId.id),
    )

private fun Map<String, AttributeValue>.toAccountDeletionLog(): AccountDeletionLog =
    AccountDeletionLog(
        id = getValue("sk").asS().toId(),
        deletedSubHash = getValue("deleted_sub_hash").asS(),
        deletedRole = DeletedAccountRole.valueOf(getValue("deleted_role").asS()),
        deletedAt = Instant.fromEpochMilliseconds(getValue("deleted_at").asN().toLong()),
        actorOwnerId = getValue("actor_owner_id").asS().toId(),
    )

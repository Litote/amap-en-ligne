@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ErrorReportSyncDAO
import persistence.model.ErrorReport
import kotlin.time.Instant

private const val ERRRPT_PK = "ERRRPT"

@Single(createdAtStart = true, binds = [ErrorReportSyncDAO::class])
internal class ErrorReportSyncDynamoDAO(
    private val client: DynamoClient,
) : ErrorReportSyncDAO {
    override suspend fun listAll(): List<ErrorReport> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues = mapOf(":pk" to AttributeValue.S(ERRRPT_PK))
                },
            )
        return response.items.orEmpty().map { it.toErrorReport() }
    }

    override suspend fun put(
        errorReport: ErrorReport,
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
                                    item = errorReport.toAttributeValueMap()
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

private fun ErrorReport.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S(ERRRPT_PK))
        put("sk", AttributeValue.S(errorReportId.id))
        put("entity_type", AttributeValue.S("ErrorReport"))
        put("error_report_id", AttributeValue.S(errorReportId.id))
        put("error_message", AttributeValue.S(errorMessage))
        put("reported_at", AttributeValue.N(reportedAt.toEpochMilliseconds().toString()))
    }

private fun Map<String, AttributeValue>.toErrorReport(): ErrorReport =
    ErrorReport(
        errorReportId = getValue("error_report_id").asS().toId(),
        errorMessage = getValue("error_message").asS(),
        reportedAt = Instant.fromEpochMilliseconds(getValue("reported_at").asN().toLong()),
    )

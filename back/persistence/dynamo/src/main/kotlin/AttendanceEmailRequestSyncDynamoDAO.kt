@file:OptIn(ExperimentalTime::class)

package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.Put
import aws.sdk.kotlin.services.dynamodb.model.QueryRequest
import aws.sdk.kotlin.services.dynamodb.model.ScanRequest
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItem
import aws.sdk.kotlin.services.dynamodb.model.TransactWriteItemsRequest
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.model.AttendanceEmailRequest
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [AttendanceEmailRequestSyncDAO::class])
internal class AttendanceEmailRequestSyncDynamoDAO(
    private val client: DynamoClient,
) : AttendanceEmailRequestSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<AttendanceEmailRequest> {
        val response =
            client.client.query(
                QueryRequest {
                    tableName = client.table
                    keyConditionExpression = "pk = :pk"
                    expressionAttributeValues =
                        mapOf(":pk" to AttributeValue.S("ATTENDREQ#${organizationId.id}"))
                },
            )
        return response.items.orEmpty().map { it.toAttendanceEmailRequest() }
    }

    override suspend fun findById(id: Id<AttendanceEmailRequest>): AttendanceEmailRequest? {
        val response =
            client.client.scan(
                ScanRequest {
                    tableName = client.table
                    filterExpression = "entity_type = :entity_type AND sk = :sk"
                    expressionAttributeValues =
                        mapOf(
                            ":entity_type" to AttributeValue.S("AttendanceEmailRequest"),
                            ":sk" to AttributeValue.S(id.id),
                        )
                },
            )
        return response.items
            .orEmpty()
            .firstOrNull()
            ?.toAttendanceEmailRequest()
    }

    override suspend fun put(
        request: AttendanceEmailRequest,
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

private fun AttendanceEmailRequest.toAttributeValueMap(): Map<String, AttributeValue> =
    buildMap {
        put("pk", AttributeValue.S("ATTENDREQ#${organizationId.id}"))
        put("sk", AttributeValue.S(attendanceEmailRequestId.id))
        put("entity_type", AttributeValue.S("AttendanceEmailRequest"))
        put("attendance_email_request_id", AttributeValue.S(attendanceEmailRequestId.id))
        put("organization_id", AttributeValue.S(organizationId.id))
        put("delivery_id", AttributeValue.S(deliveryId))
        put("recipient_email", AttributeValue.S(recipientEmail))
        put("requested_at", AttributeValue.N(requestedAt.toEpochMilliseconds().toString()))
        sentAt?.let { put("sent_at", AttributeValue.N(it.toEpochMilliseconds().toString())) }
    }

private fun Map<String, AttributeValue>.toAttendanceEmailRequest(): AttendanceEmailRequest =
    AttendanceEmailRequest(
        attendanceEmailRequestId = getValue("attendance_email_request_id").asS().toId(),
        organizationId = getValue("organization_id").asS().toId(),
        deliveryId = getValue("delivery_id").asS(),
        recipientEmail = getValue("recipient_email").asS(),
        requestedAt = Instant.fromEpochMilliseconds(getValue("requested_at").asN().toLong()),
        sentAt = get("sent_at")?.asN()?.let { Instant.fromEpochMilliseconds(it.toLong()) },
    )

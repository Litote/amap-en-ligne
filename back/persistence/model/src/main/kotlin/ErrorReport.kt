@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

/**
 * An error report submitted by any authenticated user.
 *
 * Scope: instance-owner (visible only to owners).
 * Reports are immutable: upsert with a real id is FORBIDDEN; delete is FORBIDDEN.
 */
@Serializable
data class ErrorReport(
    @SerialName("error_report_id") val errorReportId: Id<ErrorReport>,
    @SerialName("error_message") val errorMessage: String,
    @SerialName("reported_at") val reportedAt: Instant,
)

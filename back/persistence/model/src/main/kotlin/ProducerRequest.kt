@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
data class ProducerRequest(
    @SerialName("request_id") val requestId: Id<ProducerRequest>,
    @SerialName("producer_name") val producerName: String,
    @SerialName("admin_first_name") val adminFirstName: String,
    @SerialName("admin_last_name") val adminLastName: String,
    @SerialName("admin_email") val adminEmail: String,
    val status: ProducerRequestStatus,
    @SerialName("submitted_at") val submittedAt: Instant,
    @SerialName("reviewed_at") val reviewedAt: Instant? = null,
    @SerialName("review_comment") val reviewComment: String? = null,
    @SerialName("submitter_comment") val submitterComment: String? = null,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>? = null,
    @SerialName("resend_requested_at") val resendRequestedAt: Instant? = null,
)

@Serializable
enum class ProducerRequestStatus {
    PENDING_VALIDATION,
    APPROVED,
    REJECTED,
}

@Serializable
data class CreateProducerRequestBody(
    @SerialName("producer_name") val producerName: String,
    @SerialName("admin_first_name") val adminFirstName: String,
    @SerialName("admin_last_name") val adminLastName: String,
    @SerialName("admin_email") val adminEmail: String,
    @SerialName("submitter_comment") val submitterComment: String? = null,
)

@Serializable
data class ProducerRequestCreated(
    @SerialName("request_id") val requestId: Id<ProducerRequest>,
    val status: ProducerRequestStatus,
)

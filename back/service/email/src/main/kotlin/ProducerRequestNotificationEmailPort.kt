package email

import persistence.model.ProducerRequest

fun interface ProducerRequestNotificationEmailPort {
    suspend fun notifyOwners(request: ProducerRequest)

    /** Acknowledges the submission to the requester (best-effort). No-op by default. */
    suspend fun acknowledgeRequester(request: ProducerRequest) = Unit
}

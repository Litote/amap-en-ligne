package email

import persistence.model.OrganizationRequest

fun interface OrganizationRequestNotificationEmailPort {
    suspend fun notifyOwners(request: OrganizationRequest)

    /** Acknowledges the submission to the requester (best-effort). No-op by default. */
    suspend fun acknowledgeRequester(request: OrganizationRequest) = Unit
}

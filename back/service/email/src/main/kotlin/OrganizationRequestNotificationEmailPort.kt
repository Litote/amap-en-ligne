package email

import persistence.model.OrganizationRequest

fun interface OrganizationRequestNotificationEmailPort {
    suspend fun notifyOwners(request: OrganizationRequest)
}

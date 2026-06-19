package email

import persistence.model.OrganizationRequest

interface OrganizationRequestNotificationEmailPort {
    suspend fun notifyOwners(request: OrganizationRequest)
}

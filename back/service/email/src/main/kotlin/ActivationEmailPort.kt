package email

import persistence.model.ActivationToken
import persistence.model.OrganizationRequest

interface ActivationEmailPort {
    suspend fun scheduleActivationEmail(
        token: ActivationToken,
        request: OrganizationRequest,
    )
}

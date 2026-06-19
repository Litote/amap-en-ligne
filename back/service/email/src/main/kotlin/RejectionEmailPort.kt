package email

import persistence.model.OrganizationRequest

interface RejectionEmailPort {
    suspend fun sendRejectionEmail(
        request: OrganizationRequest,
        reviewComment: String?,
    )
}

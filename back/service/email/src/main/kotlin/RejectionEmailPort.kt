package email

import persistence.model.OrganizationRequest

fun interface RejectionEmailPort {
    suspend fun sendRejectionEmail(
        request: OrganizationRequest,
        reviewComment: String?,
    )
}

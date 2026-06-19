package email

import persistence.model.MemberJoinRequest

interface MemberJoinRequestRejectionEmailPort {
    suspend fun sendRejectionEmail(
        request: MemberJoinRequest,
        organizationName: String? = null,
    )
}

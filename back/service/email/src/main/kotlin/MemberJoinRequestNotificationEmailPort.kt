package email

import persistence.model.MemberJoinRequest

interface MemberJoinRequestNotificationEmailPort {
    suspend fun notifyAdmins(
        request: MemberJoinRequest,
        organizationName: String? = null,
    )
}

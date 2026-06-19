package email

import persistence.model.ActivationToken
import persistence.model.MemberInvitation

interface MemberInvitationEmailPort {
    suspend fun sendInvitationEmail(
        invitation: MemberInvitation,
        token: ActivationToken,
        organizationName: String? = null,
    )
}

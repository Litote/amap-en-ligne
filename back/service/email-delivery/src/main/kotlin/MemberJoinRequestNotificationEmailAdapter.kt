package email.delivery

import authentication.Role
import email.EmailTemplates
import email.MemberJoinRequestNotificationEmailPort
import org.koin.core.annotation.Single
import persistence.dao.MemberSyncDAO
import persistence.model.EmailMessage
import persistence.model.MemberJoinRequest

/**
 * Notifies the AMAP's active administrators (best-effort) that a new member
 * join request was submitted. Recipients are resolved from the member feed of
 * the request's organization.
 */
@Single(createdAtStart = true, binds = [MemberJoinRequestNotificationEmailPort::class])
internal class MemberJoinRequestNotificationEmailAdapter(
    private val gateway: EmailGateway,
    private val memberSyncDAO: MemberSyncDAO,
) : MemberJoinRequestNotificationEmailPort {
    override suspend fun notifyAdmins(
        request: MemberJoinRequest,
        organizationName: String?,
    ) {
        val content = EmailTemplates.memberJoinRequestSubmitted(request, organizationName)
        memberSyncDAO
            .getByOrganizationId(request.organizationId)
            .filter { it.activeStatus && Role.ADMIN in it.roles }
            .forEach { admin ->
                val email = admin.email
                if (!email.isNullOrBlank()) {
                    gateway.deliver(EmailMessage(to = email, subject = content.subject, body = content.body))
                }
            }
    }
}

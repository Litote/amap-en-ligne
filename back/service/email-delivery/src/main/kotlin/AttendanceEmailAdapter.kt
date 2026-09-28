package email.delivery

import email.AttendanceEmailPort
import email.EmailTemplates
import org.koin.core.annotation.Single
import persistence.model.BasketExchange
import persistence.model.Delivery
import persistence.model.EmailMessage
import persistence.model.Member
import persistence.model.Organization

/** Sends the attendance sheets email (best-effort). */
@Single(createdAtStart = true, binds = [AttendanceEmailPort::class])
internal class AttendanceEmailAdapter(
    private val gateway: EmailGateway,
) : AttendanceEmailPort {
    override suspend fun sendAttendanceSheets(
        organization: Organization,
        delivery: Delivery,
        basketExchanges: List<BasketExchange>,
        members: List<Member>,
        recipientEmail: String,
    ) {
        val content = EmailTemplates.attendanceSheets(organization, delivery, basketExchanges, members)
        gateway.deliver(EmailMessage(to = recipientEmail, subject = content.subject, body = content.body))
    }
}

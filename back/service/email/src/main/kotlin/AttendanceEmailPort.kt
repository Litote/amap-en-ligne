package email

import persistence.model.BasketExchange
import persistence.model.Delivery
import persistence.model.Member
import persistence.model.Organization

fun interface AttendanceEmailPort {
    suspend fun sendAttendanceSheets(
        organization: Organization,
        delivery: Delivery,
        basketExchanges: List<BasketExchange>,
        members: List<Member>,
        recipientEmail: String,
    )
}

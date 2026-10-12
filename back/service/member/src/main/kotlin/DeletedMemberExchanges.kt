package member

import id.Id
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Member
import kotlin.time.Instant

/**
 * What a deleted member leaves in the basket exchanges still under way:
 * - their OPEN offer is cancelled and its PENDING requests rejected (what cancelling it would
 *   do), so nobody can take a basket that will never be handed over;
 * - their PENDING request on someone else's OPEN offer is withdrawn.
 * Settled or closed exchanges are history and stay as they are.
 */
internal object DeletedMemberExchanges {
    /** [exchange] once [memberId] is deleted, or null when it does not change. */
    fun close(
        exchange: BasketExchange,
        memberId: Id<Member>,
        now: Instant,
    ): BasketExchange? {
        if (exchange.status != BasketExchangeStatus.OPEN) return null
        if (exchange.offeringMemberId == memberId) {
            return exchange.copy(
                status = BasketExchangeStatus.CANCELLED,
                decidedAt = now,
                requests =
                    exchange.requests.map {
                        if (it.status == BasketExchangeRequestStatus.PENDING) {
                            it.copy(status = BasketExchangeRequestStatus.REJECTED, decidedAt = now)
                        } else {
                            it
                        }
                    },
            )
        }
        val ownPending = exchange.requests.filter { it.requesterMemberId == memberId && it.status == BasketExchangeRequestStatus.PENDING }
        if (ownPending.isEmpty()) return null
        return exchange.copy(
            requests =
                exchange.requests.map {
                    if (it in ownPending) it.copy(status = BasketExchangeRequestStatus.WITHDRAWN, decidedAt = now) else it
                },
        )
    }
}

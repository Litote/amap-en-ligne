@file:OptIn(ExperimentalTime::class)

package member

import id.toId
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

class DeletedMemberExchangesTest {
    private val deleted = "deleted-sub"
    private val now = Instant.fromEpochMilliseconds(5_000L)

    private fun request(
        id: String,
        requester: String,
        status: BasketExchangeRequestStatus = BasketExchangeRequestStatus.PENDING,
    ) = BasketExchangeRequest(
        requestId = id.toId(),
        requesterMemberId = requester.toId(),
        createdAt = Instant.fromEpochMilliseconds(1_000L),
        status = status,
        proposedDeliveryId = "delivery-2".toId(),
        proposedContractId = "contract-1".toId(),
    )

    private fun exchange(
        offerer: String,
        status: BasketExchangeStatus,
        requests: List<BasketExchangeRequest>,
    ) = BasketExchange(
        basketExchangeId = "exchange-1".toId(),
        organizationId = "org-1".toId(),
        deliveryId = "delivery-1".toId(),
        contractId = "contract-1".toId(),
        offeringMemberId = offerer.toId(),
        status = status,
        createdAt = Instant.fromEpochMilliseconds(1_000L),
        requests = requests,
    )

    @Test
    fun `GIVEN an open offer of the deleted member WHEN closed THEN it is cancelled and its pending requests rejected`() {
        val offer =
            exchange(
                deleted,
                BasketExchangeStatus.OPEN,
                listOf(request("r1", "alice"), request("r2", "bob", BasketExchangeRequestStatus.WITHDRAWN)),
            )

        val closed = DeletedMemberExchanges.close(offer, deleted.toId(), now)

        assertEquals(
            offer.copy(
                status = BasketExchangeStatus.CANCELLED,
                decidedAt = now,
                requests =
                    listOf(
                        request("r1", "alice").copy(status = BasketExchangeRequestStatus.REJECTED, decidedAt = now),
                        request("r2", "bob", BasketExchangeRequestStatus.WITHDRAWN),
                    ),
            ),
            closed,
        )
    }

    @Test
    fun `GIVEN a pending request of the deleted member on an open offer WHEN closed THEN only that request is withdrawn`() {
        val offer = exchange("alice", BasketExchangeStatus.OPEN, listOf(request("r1", deleted), request("r2", "bob")))

        val closed = DeletedMemberExchanges.close(offer, deleted.toId(), now)

        assertEquals(
            offer.copy(
                requests =
                    listOf(
                        request("r1", deleted).copy(status = BasketExchangeRequestStatus.WITHDRAWN, decidedAt = now),
                        request("r2", "bob"),
                    ),
            ),
            closed,
        )
    }

    @Test
    fun `GIVEN a settled swap of the deleted member WHEN closed THEN history is kept`() {
        val accepted =
            exchange(deleted, BasketExchangeStatus.ACCEPTED, listOf(request("r1", "alice", BasketExchangeRequestStatus.ACCEPTED)))

        assertNull(DeletedMemberExchanges.close(accepted, deleted.toId(), now))
    }

    @Test
    fun `GIVEN an offer the deleted member is not part of WHEN closed THEN it is untouched`() {
        assertNull(
            DeletedMemberExchanges.close(exchange("alice", BasketExchangeStatus.OPEN, listOf(request("r1", "bob"))), deleted.toId(), now),
        )
    }
}

package exchange

import id.Id
import persistence.changes.ClientMutation
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus

/** A mutation limited to the embedded [BasketExchange.requests] list, the offer itself unchanged. */
internal sealed interface BasketExchangeRequestMutation {
    data class Add(
        val request: BasketExchangeRequest,
    ) : BasketExchangeRequestMutation

    data class Withdraw(
        val request: BasketExchangeRequest,
    ) : BasketExchangeRequestMutation

    data class Refuse(
        val request: BasketExchangeRequest,
    ) : BasketExchangeRequestMutation
}

/**
 * Detects whether the incoming payload differs from [existing] only in the [BasketExchange.requests]
 * list (add one new request or update one existing request to WITHDRAWN) while all other fields
 * remain equal.
 *
 * Returns the detected [BasketExchangeRequestMutation] or null if the delta spans more than just requests.
 */
internal fun detectRequestMutation(
    existing: BasketExchange,
    incoming: BasketExchange,
): BasketExchangeRequestMutation? {
    val offerFieldsEqual =
        existing.copy(requests = emptyList()) == incoming.copy(requests = emptyList())
    if (!offerFieldsEqual) return null

    val existingIds = existing.requests.map { it.requestId }.toSet()
    val incomingIds = incoming.requests.map { it.requestId }.toSet()

    // New request added (tmp_ id = creation)
    val newRequests = incoming.requests.filter { it.requestId.id.startsWith(ClientMutation.TMP_ID_PREFIX) }
    if (newRequests.size == 1 && existingIds == (incomingIds - newRequests.first().requestId)) {
        return BasketExchangeRequestMutation.Add(newRequests.first())
    }

    // Existing request transitioned (withdrawn by requester or refused by offerer), offer unchanged
    val singleTransition = detectSingleRequestTransition(existing, incoming, existingIds, incomingIds)
    if (singleTransition != null) return singleTransition

    return null
}

/**
 * Detects a single existing request transitioning from PENDING to either WITHDRAWN (by the
 * requester) or REJECTED (individual refusal by the offerer, the offer staying OPEN), with all
 * other requests unchanged.
 */
private fun detectSingleRequestTransition(
    existing: BasketExchange,
    incoming: BasketExchange,
    existingIds: Set<Id<BasketExchangeRequest>>,
    incomingIds: Set<Id<BasketExchangeRequest>>,
): BasketExchangeRequestMutation? {
    if (existingIds != incomingIds) return null
    val transitioned =
        incoming.requests.filter { req ->
            val old = existing.requests.find { it.requestId == req.requestId }
            old != null && old.status == BasketExchangeRequestStatus.PENDING &&
                (req.status == BasketExchangeRequestStatus.WITHDRAWN || req.status == BasketExchangeRequestStatus.REJECTED)
        }
    if (transitioned.size != 1) return null
    val target = transitioned.first()
    val unchangedOthers =
        incoming.requests.all { req ->
            req.requestId == target.requestId ||
                existing.requests.find { it.requestId == req.requestId } == req
        }
    if (!unchangedOthers) return null
    return when (target.status) {
        BasketExchangeRequestStatus.WITHDRAWN -> BasketExchangeRequestMutation.Withdraw(target)
        BasketExchangeRequestStatus.REJECTED -> BasketExchangeRequestMutation.Refuse(target)
        else -> null
    }
}

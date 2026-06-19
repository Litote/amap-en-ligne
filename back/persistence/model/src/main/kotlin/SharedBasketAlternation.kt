package persistence.model

import id.Id

/**
 * Pure round-robin alternation for a [SharedBasket].
 *
 * The caller supplies [orderedDeliveryIds]: the ids of the contract's deliveries already sorted by
 * `(scheduledDate, deliveryId)` (see [Organization.orderedDeliveryIdsForContract]).
 *
 * Resolution:
 *  - `a` = index of [SharedBasket.anchorDeliveryId] in [orderedDeliveryIds] (0 if null/unknown),
 *  - `p` = index of [deliveryId],
 *  - picker = `memberIds[((p - a) mod N + N) mod N]`.
 *
 * Returns null when the basket has no members or [deliveryId] is not part of the contract.
 *
 * This formula is mirrored verbatim by the front (`shared_basket_view.dart`) and pinned by the
 * shared acceptance scenario.
 */
fun SharedBasket.pickerFor(
    orderedDeliveryIds: List<Id<Delivery>>,
    deliveryId: Id<Delivery>,
): Id<Member>? {
    val n = memberIds.size
    if (n == 0) return null
    val p = orderedDeliveryIds.indexOf(deliveryId)
    if (p < 0) return null
    val a = anchorDeliveryId?.let { orderedDeliveryIds.indexOf(it) }?.takeIf { it >= 0 } ?: 0
    val index = ((p - a) % n + n) % n
    return memberIds[index]
}

/**
 * The ids of [this] organization's deliveries linked to [contractId], ordered by
 * `(scheduledDate, deliveryId)` — the canonical order used by the alternation.
 */
fun Organization.orderedDeliveryIdsForContract(contractId: Id<Contract>): List<Id<Delivery>> =
    deliveries
        .filter { delivery -> delivery.contracts.any { it.contractId == contractId } }
        .sortedWith(compareBy({ it.scheduledDate }, { it.deliveryId.id }))
        .map { it.deliveryId }

/**
 * Whether [memberId] effectively holds [this] contract's basket on the delivery [deliveryId].
 *
 * A member who is not part of any shared basket always holds their own basket (no change to the
 * non-shared case). A member who shares a basket holds it **only** on the deliveries where the
 * alternation designates them as the picker.
 *
 * [orderedDeliveryIds] = [Organization.orderedDeliveryIdsForContract] for this contract.
 */
fun Contract.holdsBasketOn(
    memberId: Id<Member>,
    orderedDeliveryIds: List<Id<Delivery>>,
    deliveryId: Id<Delivery>,
): Boolean {
    val basket = sharedBaskets.firstOrNull { it.memberIds.contains(memberId) } ?: return true
    return basket.pickerFor(orderedDeliveryIds, deliveryId) == memberId
}

package core

import id.Id
import persistence.model.BasketExchange
import persistence.model.Contract
import persistence.model.Member
import persistence.model.Organization

/*
 * Rewrites every reference to the member id `from` into `to` inside the organization aggregates.
 *
 * Used when a member imported without auth account activates: account-backed members must have
 * `memberId == sub`, so the imported row is re-keyed to the new sub and every reference follows.
 * Each function returns the receiver itself when it does not reference `from`, so callers can skip
 * the write with an identity check.
 */

/** Delivery coordinators, slot registrations and slot exchanges. */
fun Organization.withMemberIdReplaced(
    from: Id<Member>,
    to: Id<Member>,
): Organization {
    val rewritten =
        copy(
            deliveries =
                deliveries.map { delivery ->
                    delivery.copy(
                        contracts =
                            delivery.contracts.map { link ->
                                link.copy(
                                    coordinators = link.coordinators.replaced(from, to),
                                    slots =
                                        link.slots.map { slot ->
                                            slot.copy(
                                                registrations =
                                                    slot.registrations.map {
                                                        if (it.memberId == from) it.copy(memberId = to) else it
                                                    },
                                            )
                                        },
                                    exchanges =
                                        link.exchanges.map {
                                            it.copy(
                                                memberId = if (it.memberId == from) to else it.memberId,
                                                targetMemberId = if (it.targetMemberId == from) to else it.targetMemberId,
                                            )
                                        },
                                )
                            },
                    )
                },
        )
    return if (rewritten == this) this else rewritten
}

/** Contract coordinators, member subscriptions and shared baskets. */
fun Contract.withMemberIdReplaced(
    from: Id<Member>,
    to: Id<Member>,
): Contract {
    val rewritten =
        copy(
            coordinators = coordinators.replaced(from, to),
            members = members.map { if (it.memberId == from) it.copy(memberId = to) else it },
            sharedBaskets = sharedBaskets.map { it.copy(memberIds = it.memberIds.replaced(from, to)) },
        )
    return if (rewritten == this) this else rewritten
}

/** The offering member and the requesters. */
fun BasketExchange.withMemberIdReplaced(
    from: Id<Member>,
    to: Id<Member>,
): BasketExchange {
    val rewritten =
        copy(
            offeringMemberId = if (offeringMemberId == from) to else offeringMemberId,
            requests = requests.map { if (it.requesterMemberId == from) it.copy(requesterMemberId = to) else it },
        )
    return if (rewritten == this) this else rewritten
}

private fun List<Id<Member>>.replaced(
    from: Id<Member>,
    to: Id<Member>,
): List<Id<Member>> = map { if (it == from) to else it }

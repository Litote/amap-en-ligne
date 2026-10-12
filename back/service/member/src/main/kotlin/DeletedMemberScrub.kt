package member

import id.Id
import kotlinx.datetime.LocalDate
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.Member
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus

/**
 * What a deleted member leaves in the organization's deliveries:
 * - upcoming deliveries (still active, scheduled today or later): their registrations and their
 *   coordinator role are removed — they will not come, so their places are freed and the
 *   « Coordinateur manquant » alert shows instead of a phantom coordinator;
 * - history (past, completed or cancelled deliveries): their registrations stay — counters,
 *   ranking and statistics remain right — but lose the copied name and email.
 */
internal object DeletedMemberScrub {
    fun scrub(
        organization: Organization,
        memberId: Id<Member>,
        today: LocalDate,
    ): Organization =
        organization.copy(
            deliveries =
                organization.deliveries.map { delivery ->
                    if (delivery.isUpcoming(today)) withoutMember(delivery, memberId) else anonymised(delivery, memberId)
                },
        )

    private fun Delivery.isUpcoming(today: LocalDate): Boolean = status.isActive() && scheduledDate.date >= today

    private fun withoutMember(
        delivery: Delivery,
        memberId: Id<Member>,
    ): Delivery =
        delivery.mapLinks { link ->
            link.copy(
                coordinators = link.coordinators - memberId,
                slots = link.slots.map { slot -> withoutRegistrationsOf(slot, memberId) },
            )
        }

    private fun withoutRegistrationsOf(
        slot: MemberSlot,
        memberId: Id<Member>,
    ): MemberSlot {
        val removed = slot.registrations.filter { it.memberId == memberId }
        if (removed.isEmpty()) return slot
        return slot.copy(
            registrations = slot.registrations - removed.toSet(),
            currentRegistrations =
                (slot.currentRegistrations - removed.count { it.status != RegistrationStatus.CANCELLED }).coerceAtLeast(0),
        )
    }

    private fun anonymised(
        delivery: Delivery,
        memberId: Id<Member>,
    ): Delivery =
        delivery.mapLinks { link ->
            link.copy(
                slots =
                    link.slots.map { slot ->
                        slot.copy(
                            registrations =
                                slot.registrations.map {
                                    if (it.memberId == memberId) it.copy(displayName = "", memberEmail = "") else it
                                },
                        )
                    },
            )
        }

    private fun Delivery.mapLinks(transform: (DeliveryContract) -> DeliveryContract): Delivery = copy(contracts = contracts.map(transform))
}

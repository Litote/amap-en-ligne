package organization

import id.Id
import persistence.model.Member
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus

/**
 * A volunteer (plain member) can only change their own registrations, but writes the whole
 * organization back — a copy that may be stale (another member registered since, a coordinator
 * edited a delivery, a delivery was auto-closed) and that was served masked
 * (`PlainMemberRedaction`). Rejecting every difference would refuse honest concurrent
 * registrations, so the write is rebased: the stored organization with, in each slot, the
 * caller's own registrations taken from [incoming]. Everything else the caller sent is ignored;
 * [VolunteerMutationValidator] then checks the own-registration deltas (capacity, cancelled
 * slot, inactive delivery) against the stored state.
 */
internal object VolunteerWriteRebase {
    fun ownRegistrationsOnto(
        persisted: Organization,
        incoming: Organization,
        memberId: Id<Member>,
    ): Organization {
        val sentDeliveries = incoming.deliveries.associateBy { it.deliveryId }
        return persisted.copy(
            deliveries =
                persisted.deliveries.map { stored ->
                    val sent = sentDeliveries[stored.deliveryId] ?: return@map stored
                    val sentLinks = sent.contracts.associateBy { it.contractId }
                    stored.copy(
                        contracts =
                            stored.contracts.map { link ->
                                val sentLink = sentLinks[link.contractId] ?: return@map link
                                link.copy(
                                    slots =
                                        link.slots.mapIndexed { index, slot ->
                                            val sentSlot = matchingSlot(slot, index, sentLink.slots) ?: return@mapIndexed slot
                                            withOwnRegistrations(slot, sentSlot, memberId)
                                        },
                                )
                            },
                    )
                },
        )
    }

    /** The sent slot standing for [stored]: same server id, else same position without a different id. */
    private fun matchingSlot(
        stored: MemberSlot,
        index: Int,
        sentSlots: List<MemberSlot>,
    ): MemberSlot? =
        stored.slotId?.let { id -> sentSlots.firstOrNull { it.slotId == id } }
            ?: sentSlots.getOrNull(index)?.takeIf { it.slotId == null || it.slotId == stored.slotId }

    private fun withOwnRegistrations(
        stored: MemberSlot,
        sent: MemberSlot,
        memberId: Id<Member>,
    ): MemberSlot {
        val storedOwn = stored.registrations.filter { it.memberId == memberId }
        val sentOwn = sent.registrations.filter { it.memberId == memberId }
        if (storedOwn == sentOwn) return stored
        return stored.copy(
            registrations = stored.registrations.filter { it.memberId != memberId } + sentOwn,
            currentRegistrations =
                (stored.currentRegistrations + activeCount(sentOwn) - activeCount(storedOwn)).coerceAtLeast(0),
        )
    }

    private fun activeCount(registrations: List<MemberRegistration>): Int =
        registrations.count { it.status != RegistrationStatus.CANCELLED }
}

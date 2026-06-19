package organization

import core.EntityTypeService
import id.Id
import id.generateId
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.Member
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus

/**
 * Normalizes and validates the slot lifecycle inside an [Organization] upsert submitted by a
 * privileged caller (OWNER / ADMIN / COORDINATOR).
 *
 * Slot identity: slots are matched between the persisted and incoming aggregates by [MemberSlot.slotId]
 * first; the slots left unmatched then fall back to their natural key (start_time, end_time,
 * activity_type) — this covers persisted legacy slots without id as well as incoming payloads that
 * do not carry ids yet. An incoming slot with no match is a creation. Every slot persisted without
 * a [MemberSlot.slotId] is backfilled with a generated id on the first privileged write of the
 * organization.
 *
 * Guard scope: validation only applies to (delivery, contract) pairs present on both sides — deleting
 * a whole delivery or contract keeps its existing unguarded behaviour.
 *
 * Rules per matched (delivery, contract):
 *  - a persisted slot that disappears while it still has at least one active registration
 *    (status != CANCELLED) → CONFLICT;
 *  - a slot transitioning to [SlotStatus.CANCELLED] is normalized server-side: every non-CANCELLED
 *    registration is forced to CANCELLED and current_registrations is reset to 0 (the cancellation
 *    is authoritative even if the client did not cascade);
 *  - [SlotStatus.CANCELLED] is terminal: transitioning back to any other status → FORBIDDEN;
 *  - editing start/end times of a slot with active registrations is allowed and keeps the
 *    registrations — it only emits a RESCHEDULED event.
 */
internal object SlotLifecycleNormalizer {
    enum class SlotEventKind {
        CANCELLED,
        RESCHEDULED,
    }

    data class SlotEvent(
        val kind: SlotEventKind,
        val deliveryId: Id<Delivery>,
        val slot: MemberSlot,
        val affectedMemberIds: List<Id<Member>>,
    )

    sealed interface Result {
        data class Rejected(
            val outcome: MutationOutcome,
        ) : Result

        data class Normalized(
            val organization: Organization,
            val events: List<SlotEvent>,
        ) : Result
    }

    fun process(
        persisted: Organization?,
        incoming: Organization,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): Result {
        val events = mutableListOf<SlotEvent>()
        val normalizedDeliveries = mutableListOf<Delivery>()

        for (incomingDelivery in incoming.deliveries) {
            val persistedDelivery = persisted?.deliveries?.find { it.deliveryId == incomingDelivery.deliveryId }
            val normalizedContracts = mutableListOf<DeliveryContract>()
            for (incomingContract in incomingDelivery.contracts) {
                when (val result = normalizeContract(persistedDelivery, incomingDelivery, incomingContract, mutation, service)) {
                    is ContractNormalization.Rejected -> {
                        return Result.Rejected(result.outcome)
                    }

                    is ContractNormalization.Ok -> {
                        normalizedContracts += result.contract
                        events += result.events
                    }
                }
            }
            normalizedDeliveries += incomingDelivery.copy(contracts = normalizedContracts)
        }

        return Result.Normalized(incoming.copy(deliveries = normalizedDeliveries), events)
    }

    private sealed interface ContractNormalization {
        data class Rejected(
            val outcome: MutationOutcome,
        ) : ContractNormalization

        data class Ok(
            val contract: DeliveryContract,
            val events: List<SlotEvent>,
        ) : ContractNormalization
    }

    private fun normalizeContract(
        persistedDelivery: Delivery?,
        incomingDelivery: Delivery,
        incomingContract: DeliveryContract,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): ContractNormalization {
        val persistedContract =
            persistedDelivery?.contracts?.find { it.contractId == incomingContract.contractId }
                ?: return ContractNormalization.Ok(
                    incomingContract.copy(slots = incomingContract.slots.map(::withBackfilledId)),
                    emptyList(),
                )

        val matchedPersistedByIncomingIndex = matchSlots(persistedContract.slots, incomingContract.slots)

        val deletedSlotOutcome =
            checkDeletedSlots(persistedContract.slots, matchedPersistedByIncomingIndex.values, mutation, service)
        if (deletedSlotOutcome != null) return ContractNormalization.Rejected(deletedSlotOutcome)

        val normalizedSlots = mutableListOf<MemberSlot>()
        val events = mutableListOf<SlotEvent>()
        for ((incomingIndex, incomingSlot) in incomingContract.slots.withIndex()) {
            val persistedSlot = matchedPersistedByIncomingIndex[incomingIndex]
            if (persistedSlot == null) {
                normalizedSlots += withBackfilledId(incomingSlot)
                continue
            }
            when (val result = normalizeSlot(incomingSlot, persistedSlot, incomingDelivery.deliveryId, mutation, service)) {
                is SlotNormalization.Rejected -> {
                    return ContractNormalization.Rejected(result.outcome)
                }

                is SlotNormalization.Ok -> {
                    normalizedSlots += result.slot
                    result.event?.let { events += it }
                }
            }
        }
        return ContractNormalization.Ok(incomingContract.copy(slots = normalizedSlots), events)
    }

    private sealed interface SlotNormalization {
        data class Rejected(
            val outcome: MutationOutcome,
        ) : SlotNormalization

        data class Ok(
            val slot: MemberSlot,
            val event: SlotEvent?,
        ) : SlotNormalization
    }

    private fun normalizeSlot(
        incomingSlot: MemberSlot,
        persistedSlot: MemberSlot,
        deliveryId: Id<Delivery>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): SlotNormalization {
        if (persistedSlot.status == SlotStatus.CANCELLED && incomingSlot.status != SlotStatus.CANCELLED) {
            return SlotNormalization.Rejected(
                service.rejected(
                    mutation,
                    MutationErrorCode.FORBIDDEN,
                    "cancelled slot ${slotLabel(persistedSlot)} cannot be reopened",
                ),
            )
        }
        val activeMemberIds =
            persistedSlot.registrations
                .filter { it.status != RegistrationStatus.CANCELLED }
                .map { it.memberId }
        if (incomingSlot.status == SlotStatus.CANCELLED && persistedSlot.status != SlotStatus.CANCELLED) {
            val cancelledSlot =
                withInheritedId(incomingSlot, persistedSlot).copy(
                    registrations = cancelAllRegistrations(incomingSlot.registrations),
                    currentRegistrations = 0,
                )
            val event =
                if (activeMemberIds.isNotEmpty()) {
                    SlotEvent(SlotEventKind.CANCELLED, deliveryId, cancelledSlot, activeMemberIds)
                } else {
                    null
                }
            return SlotNormalization.Ok(cancelledSlot, event)
        }
        val rescheduled =
            incomingSlot.startTime != persistedSlot.startTime || incomingSlot.endTime != persistedSlot.endTime
        val normalizedSlot = withInheritedId(incomingSlot, persistedSlot)
        val event =
            if (rescheduled && activeMemberIds.isNotEmpty()) {
                SlotEvent(SlotEventKind.RESCHEDULED, deliveryId, normalizedSlot, activeMemberIds)
            } else {
                null
            }
        return SlotNormalization.Ok(normalizedSlot, event)
    }

    private fun cancelAllRegistrations(registrations: List<MemberRegistration>): List<MemberRegistration> =
        registrations.map {
            if (it.status == RegistrationStatus.CANCELLED) it else it.copy(status = RegistrationStatus.CANCELLED)
        }

    /**
     * Matches incoming slots to persisted slots in two passes: by [MemberSlot.slotId] first,
     * then by natural key among the slots left unmatched on both sides. Returns the matched
     * persisted slot per incoming slot index; persisted slots absent from the values are deletions.
     */
    private fun matchSlots(
        persistedSlots: List<MemberSlot>,
        incomingSlots: List<MemberSlot>,
    ): Map<Int, MemberSlot> {
        val matched = mutableMapOf<Int, MemberSlot>()
        val remainingPersisted = persistedSlots.toMutableList()

        for ((index, incomingSlot) in incomingSlots.withIndex()) {
            val incomingId = incomingSlot.slotId ?: continue
            val persistedSlot = remainingPersisted.find { it.slotId == incomingId } ?: continue
            matched[index] = persistedSlot
            remainingPersisted.remove(persistedSlot)
        }

        for ((index, incomingSlot) in incomingSlots.withIndex()) {
            if (index in matched) continue
            val persistedSlot = remainingPersisted.find { naturalKey(it) == naturalKey(incomingSlot) } ?: continue
            matched[index] = persistedSlot
            remainingPersisted.remove(persistedSlot)
        }

        return matched
    }

    private fun checkDeletedSlots(
        persistedSlots: List<MemberSlot>,
        matchedPersistedSlots: Collection<MemberSlot>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        for (persistedSlot in persistedSlots) {
            if (persistedSlot in matchedPersistedSlots) continue
            val activeCount = persistedSlot.registrations.count { it.status != RegistrationStatus.CANCELLED }
            if (activeCount > 0) {
                return service.rejected(
                    mutation,
                    MutationErrorCode.CONFLICT,
                    "slot ${slotLabel(persistedSlot)} cannot be deleted: $activeCount active registration(s)",
                )
            }
        }
        return null
    }

    private fun naturalKey(slot: MemberSlot) = Triple(slot.startTime, slot.endTime, slot.activityType)

    /**
     * Re-applies the persisted slot ids onto [incoming] for slots that do not carry one.
     *
     * Used on the VOLUNTEER write path: the volunteer replaces the whole aggregate after
     * [VolunteerMutationValidator] proved the slot lists are positionally identical, so a
     * legacy payload echo without `slot_id`s must not erase the server-allocated ids.
     */
    fun inheritSlotIds(
        persisted: Organization,
        incoming: Organization,
    ): Organization =
        incoming.copy(
            deliveries =
                incoming.deliveries.map { delivery ->
                    val persistedDelivery =
                        persisted.deliveries.find { it.deliveryId == delivery.deliveryId }
                            ?: return@map delivery
                    delivery.copy(
                        contracts =
                            delivery.contracts.map { contract ->
                                val persistedContract =
                                    persistedDelivery.contracts.find { it.contractId == contract.contractId }
                                        ?: return@map contract
                                if (persistedContract.slots.size != contract.slots.size) return@map contract
                                contract.copy(
                                    slots =
                                        contract.slots.mapIndexed { index, slot ->
                                            if (slot.slotId == null) {
                                                slot.copy(slotId = persistedContract.slots[index].slotId)
                                            } else {
                                                slot
                                            }
                                        },
                                )
                            },
                    )
                },
        )

    private fun withBackfilledId(slot: MemberSlot): MemberSlot =
        if (slot.slotId != null) slot else slot.copy(slotId = generateId<MemberSlot>().id)

    /** Keeps the identity of a matched slot stable: incoming id, else persisted id, else a fresh one. */
    private fun withInheritedId(
        incomingSlot: MemberSlot,
        persistedSlot: MemberSlot,
    ): MemberSlot =
        when {
            incomingSlot.slotId != null -> incomingSlot
            persistedSlot.slotId != null -> incomingSlot.copy(slotId = persistedSlot.slotId)
            else -> withBackfilledId(incomingSlot)
        }

    private fun slotLabel(slot: MemberSlot) = "${slot.startTime}–${slot.endTime}"
}

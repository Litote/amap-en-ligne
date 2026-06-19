package organization

import authentication.AuthenticatedInfo
import core.EntityTypeService
import id.Id
import id.toId
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryTemplate
import persistence.model.Member
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus

private data class VolunteerRegistrationContext(
    val memberId: Id<Member>,
    val delivery: Delivery,
    val coordinatorIds: Set<Id<Member>>,
    val templateById: Map<Id<DeliveryTemplate>, DeliveryTemplate>,
    val mutation: ClientMutation,
    val service: EntityTypeService<OrganizationPayload>,
)

/**
 * Validates that a VOLUNTEER-only caller only mutates their own [MemberRegistration]s
 * within the [Organization] aggregate, and respects slot capacity and delivery status rules.
 *
 * Returns a rejected [MutationOutcome] on the first violation, or null if all checks pass.
 */
internal object VolunteerMutationValidator {
    private const val VOLUNTEER_OWN_REGISTRATIONS_ONLY = "volunteer may only modify own registrations"

    fun validate(
        auth: AuthenticatedInfo,
        persisted: Organization,
        incoming: Organization,
        templates: List<DeliveryTemplate>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        val memberId: Id<Member> = auth.memberId.toId()

        // Structural checks: everything except deliveries[].contracts[].slots[].registrations must be identical
        if (!areNonRegistrationFieldsEqual(persisted, incoming)) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        // Check each delivery delta
        val persistedDeliveriesById = persisted.deliveries.associateBy { it.deliveryId }
        val incomingDeliveriesById = incoming.deliveries.associateBy { it.deliveryId }

        // Volunteer cannot add or remove deliveries
        if (persistedDeliveriesById.keys != incomingDeliveriesById.keys) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        val templateById = templates.associateBy { it.deliveryTemplateId }

        for ((deliveryId, incomingDelivery) in incomingDeliveriesById) {
            val persistedDelivery = persistedDeliveriesById[deliveryId] ?: continue
            validateDeliveryDelta(persistedDelivery, incomingDelivery, templateById, memberId, mutation, service)
                ?.let { return it }
        }

        return null
    }

    private fun validateDeliveryDelta(
        persistedDelivery: Delivery,
        incomingDelivery: Delivery,
        templateById: Map<Id<DeliveryTemplate>, DeliveryTemplate>,
        memberId: Id<Member>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        // Everything except slots[].registrations must be equal in each delivery
        if (!areNonRegistrationDeliveryFieldsEqual(persistedDelivery, incomingDelivery)) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        val persistedContractsById = persistedDelivery.contracts.associateBy { it.contractId }
        val incomingContractsById = incomingDelivery.contracts.associateBy { it.contractId }

        if (persistedContractsById.keys != incomingContractsById.keys) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        for ((contractId, incomingContract) in incomingContractsById) {
            val persistedContract = persistedContractsById[contractId] ?: continue
            validateContractDelta(persistedContract, incomingContract, incomingDelivery, templateById, memberId, mutation, service)
                ?.let { return it }
        }
        return null
    }

    private fun validateContractDelta(
        persistedContract: DeliveryContract,
        incomingContract: DeliveryContract,
        incomingDelivery: Delivery,
        templateById: Map<Id<DeliveryTemplate>, DeliveryTemplate>,
        memberId: Id<Member>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        if (!areNonRegistrationContractFieldsEqual(persistedContract, incomingContract)) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        val persistedSlotsOrdered = persistedContract.slots
        val incomingSlotsOrdered = incomingContract.slots

        if (persistedSlotsOrdered.size != incomingSlotsOrdered.size) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        val coordinatorIds = incomingContract.coordinators.toSet()
        val context =
            VolunteerRegistrationContext(
                memberId = memberId,
                delivery = incomingDelivery,
                coordinatorIds = coordinatorIds,
                templateById = templateById,
                mutation = mutation,
                service = service,
            )
        for ((slotIndex, incomingSlot) in incomingSlotsOrdered.withIndex()) {
            val persistedSlot = persistedSlotsOrdered[slotIndex]
            validateSlotRegistrationDelta(
                persistedSlot,
                incomingSlot,
                context,
            )?.let { return it }
        }
        return null
    }

    private fun validateSlotRegistrationDelta(
        persistedSlot: MemberSlot,
        incomingSlot: MemberSlot,
        context: VolunteerRegistrationContext,
    ): MutationOutcome? {
        if (!areNonRegistrationSlotFieldsEqual(persistedSlot, incomingSlot)) {
            return context.service.rejected(context.mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        val persistedRegistrations = persistedSlot.registrations.toSet()
        val incomingRegistrations = incomingSlot.registrations.toSet()

        if (persistedRegistrations == incomingRegistrations) return null

        // Delta: added and removed registrations
        val added = incomingRegistrations - persistedRegistrations
        val removed = persistedRegistrations - incomingRegistrations
        val delta = added + removed

        // All delta entries must belong to the caller
        if (delta.any { it.memberId != context.memberId }) {
            return context.service.rejected(context.mutation, MutationErrorCode.FORBIDDEN, VOLUNTEER_OWN_REGISTRATIONS_ONLY)
        }

        // A cancelled slot accepts no registration change at all
        if (persistedSlot.status == SlotStatus.CANCELLED) {
            return context.service.rejected(
                context.mutation,
                MutationErrorCode.FORBIDDEN,
                "cannot register or unregister on a cancelled slot",
            )
        }

        // If adding registrations, delivery must be active
        if (added.isNotEmpty() && !context.delivery.status.isActive()) {
            return context.service.rejected(
                context.mutation,
                MutationErrorCode.FORBIDDEN,
                "cannot register to a delivery that is no longer active",
            )
        }

        // Capacity check for additions
        if (added.isNotEmpty()) {
            return checkCapacity(
                slot = incomingSlot,
                delivery = context.delivery,
                coordinatorIds = context.coordinatorIds,
                templateById = context.templateById,
                mutation = context.mutation,
                service = context.service,
            )
        }
        return null
    }

    private fun checkCapacity(
        slot: MemberSlot,
        delivery: Delivery,
        coordinatorIds: Set<Id<Member>>,
        templateById: Map<Id<DeliveryTemplate>, DeliveryTemplate>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        // Coordinators assigned to this contract are excluded: their presence on a slot
        // does not consume volunteer capacity.
        val activeCount =
            slot.registrations.count {
                it.status != RegistrationStatus.CANCELLED && it.memberId !in coordinatorIds
            }
        return when (slot.slotKind) {
            SlotKind.STANDARD -> {
                if (activeCount > slot.requiredVolunteers) {
                    service.rejected(mutation, MutationErrorCode.FORBIDDEN, "standard slot is at capacity")
                } else {
                    null
                }
            }

            SlotKind.EARLY -> {
                // The delivery's own early-slot override wins; the linked template is the fallback
                // so a delivery may define an early slot without any template.
                val earlySlotMax =
                    delivery.earlySlot?.maxVolunteers
                        ?: delivery.deliveryTemplateId?.let { templateById[it]?.earlySlot?.maxVolunteers }
                if (earlySlotMax == null) {
                    service.rejected(mutation, MutationErrorCode.FORBIDDEN, "no early slot configuration for this delivery")
                } else if (activeCount > earlySlotMax) {
                    service.rejected(mutation, MutationErrorCode.FORBIDDEN, "early slot is at capacity")
                } else {
                    null
                }
            }
        }
    }

    // ---- structural equality helpers (everything except registrations) ----

    private fun areNonRegistrationFieldsEqual(
        persisted: Organization,
        incoming: Organization,
    ): Boolean =
        persisted.copy(deliveries = emptyList()) == incoming.copy(deliveries = emptyList()) &&
            persisted.deliveries.size == incoming.deliveries.size

    private fun areNonRegistrationDeliveryFieldsEqual(
        persisted: Delivery,
        incoming: Delivery,
    ): Boolean = persisted.copy(contracts = emptyList()) == incoming.copy(contracts = emptyList())

    private fun areNonRegistrationContractFieldsEqual(
        persisted: DeliveryContract,
        incoming: DeliveryContract,
    ): Boolean = persisted.copy(slots = emptyList()) == incoming.copy(slots = emptyList())

    private fun areNonRegistrationSlotFieldsEqual(
        persisted: MemberSlot,
        incoming: MemberSlot,
    ): Boolean {
        // A legacy client echo may omit the server-backfilled slot_id — tolerated.
        // An incoming slot carrying a *different* id is a structural change.
        if (incoming.slotId != null && incoming.slotId != persisted.slotId) return false
        return persisted.copy(registrations = emptyList(), currentRegistrations = 0, slotId = null) ==
            incoming.copy(registrations = emptyList(), currentRegistrations = 0, slotId = null)
    }
}

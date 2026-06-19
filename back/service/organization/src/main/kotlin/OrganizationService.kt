package organization

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.Id
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import notificationpublisher.NotificationContact
import notificationpublisher.NotificationPublisher
import notificationpublisher.resolveCopy
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationCopyOverride
import persistence.model.NotificationType
import persistence.model.Organization
import persistence.model.ProducerManagementMode
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import kotlin.time.Clock

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class OrganizationService(
    val organizationSyncDAO: OrganizationSyncDAO,
    val deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO,
    val producerAccountSyncDAO: ProducerAccountSyncDAO,
    val memberSyncDAO: MemberSyncDAO,
    val notificationPublisher: NotificationPublisher,
    private val contractSyncDAO: ContractSyncDAO,
) : EntityTypeService<OrganizationPayload>(EntityType.Organization) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: OrganizationPayload,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        if (payload.organization.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }

        val duplicateDay =
            payload.organization.deliveries
                .groupBy { it.scheduledDate.date }
                .entries
                .firstOrNull { (_, sameDay) -> sameDay.size > 1 }
                ?.key
        if (duplicateDay != null) {
            return rejected(
                mutation,
                MutationErrorCode.UNIQUE_VIOLATION,
                "duplicate delivery on $duplicateDay for this organization",
            )
        }

        val isPrivilegedCaller = auth.roles.any { it == Role.OWNER || it == Role.ADMIN || it == Role.COORDINATOR }
        val isVolunteerCaller = auth.roles.any { it == Role.VOLUNTEER }

        if (!isPrivilegedCaller && !isVolunteerCaller) {
            return rejected(
                mutation,
                MutationErrorCode.FORBIDDEN,
                "only OWNER, ADMIN, COORDINATOR, or VOLUNTEER may upsert an organization",
            )
        }

        val persistedOrg = organizationSyncDAO.getById(payload.organization.organizationId)

        var normalizedOrg = payload.organization
        var slotEvents = emptyList<SlotLifecycleNormalizer.SlotEvent>()

        if (!isPrivilegedCaller && isVolunteerCaller) {
            if (persistedOrg != null) {
                val templates = deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId())
                val validationOutcome =
                    VolunteerMutationValidator.validate(
                        auth = auth,
                        persisted = persistedOrg,
                        incoming = payload.organization,
                        templates = templates,
                        mutation = mutation,
                        service = this,
                    )
                if (validationOutcome != null) return validationOutcome
                // A volunteer write replaces the whole aggregate: keep the
                // server-allocated slot ids even when the client payload
                // (legacy echo) does not carry them.
                normalizedOrg = SlotLifecycleNormalizer.inheritSlotIds(persistedOrg, payload.organization)
            }
        }

        val productCheckOutcome =
            checkProductsModificationAllowed(
                organizationId = organizationId,
                persistedOrg = persistedOrg,
                incoming = payload.organization,
                mutation = mutation,
            )
        if (productCheckOutcome != null) return productCheckOutcome

        val missingCoordinatorOutcome = checkConfirmedDeliveriesHaveCoordinators(payload.organization, mutation)
        if (missingCoordinatorOutcome != null) return missingCoordinatorOutcome

        if (isPrivilegedCaller) {
            val endedLinksOutcome =
                checkNewDeliveryLinksNotEnded(organizationId, persistedOrg, payload.organization, mutation)
            if (endedLinksOutcome != null) return endedLinksOutcome

            when (val slotResult = SlotLifecycleNormalizer.process(persistedOrg, payload.organization, mutation, this)) {
                is SlotLifecycleNormalizer.Result.Rejected -> {
                    return slotResult.outcome
                }

                is SlotLifecycleNormalizer.Result.Normalized -> {
                    normalizedOrg = slotResult.organization
                    slotEvents = slotResult.events
                }
            }
        }

        val finalOrg = mergeNoAccountProducts(organizationId, persistedOrg, normalizedOrg)
        organizationSyncDAO.put(finalOrg, buildUpsertChange(organizationId, finalOrg))
        notifySlotEvents(organizationId, slotEvents, finalOrg.notificationOverrides, finalOrg.name)
        return applied(mutation, finalOrg.organizationId.id)
    }

    /**
     * Best-effort post-commit notifications for slot lifecycle events (cancellation /
     * reschedule). The member feed is keyed by the auth subject (`member:{sub}` with
     * `memberId == sub` by convention), so registrations whose member row no longer
     * exists in the organization are skipped.
     */
    private suspend fun notifySlotEvents(
        organizationId: String,
        events: List<SlotLifecycleNormalizer.SlotEvent>,
        notificationOverrides: Map<NotificationCategory, NotificationCopyOverride>,
        organizationName: String,
    ) {
        if (events.isEmpty()) return
        runCatching {
            val members = memberSyncDAO.getByOrganizationId(organizationId.toId())
            for (event in events) {
                val slot = event.slot
                val slotLabel = "${slot.startTime.date} (${slot.startTime.time}–${slot.endTime.time})"
                val (category, defaultTitle, defaultBody) =
                    when (event.kind) {
                        SlotLifecycleNormalizer.SlotEventKind.CANCELLED -> {
                            Triple(
                                NotificationCategory.SLOT_CANCELLED,
                                "Créneau annulé",
                                "Le créneau du $slotLabel a été annulé.",
                            )
                        }

                        SlotLifecycleNormalizer.SlotEventKind.RESCHEDULED -> {
                            Triple(
                                NotificationCategory.SLOT_RESCHEDULED,
                                "Horaire de créneau modifié",
                                "L'horaire de votre créneau a été modifié : $slotLabel.",
                            )
                        }
                    }
                val copy = notificationOverrides.resolveCopy(category, defaultTitle, defaultBody)
                for (memberId in event.affectedMemberIds) {
                    val member = members.find { it.memberId == memberId } ?: continue
                    notificationPublisher.publish(
                        recipientScope = SyncScope.Member(member.memberId.id).key,
                        type = NotificationType.ALERT,
                        category = category,
                        title = copy.title,
                        body = copy.body,
                        relatedEntityId = event.deliveryId.id,
                        contact = NotificationContact(email = member.email, organizationName = organizationName),
                        channels =
                            buildSet {
                                if (member.userPreferences.emailNotificationsEnabled) add(NotificationChannel.EMAIL)
                                if (member.userPreferences.pushNotificationsEnabled) add(NotificationChannel.PUSH)
                            },
                    )
                }
            }
        }.onFailure { logger.warn(it) { "failed to send slot lifecycle notifications" } }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        organizationSyncDAO.delete(op.entityId.toId(), buildDeleteChange(organizationId, op.entityId))
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<OrganizationPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return listOfNotNull(organizationSyncDAO.getById(organizationId.toId())).map { OrganizationPayload(it) }
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<OrganizationPayload> =
        when (scope) {
            is SyncScope.Organization -> snapshot(auth)
            SyncScope.InstanceOwner -> organizationSyncDAO.listAll().map { OrganizationPayload(it) }
            is SyncScope.ProducerAccount -> emptyList()
            is SyncScope.Member -> emptyList()
            is SyncScope.Owner -> emptyList()
        }

    /**
     * Ensures that every product that was added, removed, or modified in the incoming payload
     * belongs to a [ProducerManagementMode.NO_ACCOUNT] producer.
     * Products managed by [ProducerManagementMode.ACCOUNT_BACKED] producers are exclusively
     * managed by the producer themselves and must never be modified through the organization scope.
     *
     * Returns a rejected [MutationOutcome] if any touched product references an ACCOUNT_BACKED
     * producer, or null if all checks pass.
     */
    private suspend fun checkProductsModificationAllowed(
        organizationId: String,
        persistedOrg: Organization?,
        incoming: Organization,
        mutation: ClientMutation,
    ): MutationOutcome? {
        val persistedProducts = persistedOrg?.products ?: emptyList()
        val incomingProducts = incoming.products

        if (persistedProducts == incomingProducts) return null

        val persistedSet = persistedProducts.toSet()
        val incomingSet = incomingProducts.toSet()

        val touchedProducerIds =
            ((incomingSet - persistedSet) + (persistedSet - incomingSet))
                .map { it.producerAccountId }
                .toSet()

        if (touchedProducerIds.isEmpty()) return null

        val producerAccountsById =
            producerAccountSyncDAO
                .getByOrganizationId(organizationId.toId())
                .associateBy { it.producerAccountId }

        val accountBackedProducerId =
            touchedProducerIds.firstOrNull { producerId ->
                val producer = producerAccountsById[producerId]
                producer != null && producer.managementMode == ProducerManagementMode.ACCOUNT_BACKED
            }

        if (accountBackedProducerId != null) {
            return rejected(
                mutation,
                MutationErrorCode.FORBIDDEN,
                "products of ACCOUNT_BACKED producer ${accountBackedProducerId.id} cannot be modified through organization sync",
            )
        }

        return null
    }

    /**
     * Merges NO_ACCOUNT producer products into the incoming [Organization] before persisting.
     *
     * NO_ACCOUNT products are the authoritative source in [ProducerAccount.products] and are
     * derived/synced by [ProducerAccountService]. To prevent accidental overwrite when an admin
     * submits an org mutation that still carries stale NO_ACCOUNT products (or omits them), this
     * method:
     *  1. Identifies the NO_ACCOUNT producer ids for this org.
     *  2. Strips any NO_ACCOUNT products from the incoming payload (they may be stale).
     *  3. Appends the authoritative NO_ACCOUNT products preserved from the persisted org.
     *
     * Account-backed products are untouched — they are already guarded by [checkProductsModificationAllowed].
     */
    private suspend fun mergeNoAccountProducts(
        organizationId: String,
        persistedOrg: Organization?,
        incoming: Organization,
    ): Organization {
        val noAccountIds =
            producerAccountSyncDAO
                .getByOrganizationId(organizationId.toId())
                .filter { it.managementMode == ProducerManagementMode.NO_ACCOUNT }
                .map { it.producerAccountId }
                .toSet()

        if (noAccountIds.isEmpty()) return incoming

        val preservedNoAccountProducts =
            persistedOrg?.products?.filter { it.producerAccountId in noAccountIds } ?: emptyList()
        val accountBackedProducts = incoming.products.filter { it.producerAccountId !in noAccountIds }
        return incoming.copy(products = accountBackedProducts + preservedNoAccountProducts)
    }

    private fun buildUpsertChange(
        organizationId: String,
        org: Organization,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = org.organizationId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = OrganizationPayload(org),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        organizationId: String,
        entityId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = entityId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    private fun checkConfirmedDeliveriesHaveCoordinators(
        org: Organization,
        mutation: ClientMutation,
    ): MutationOutcome? {
        for (delivery in org.deliveries) {
            if (delivery.status != DeliveryStatus.CONFIRMED) continue
            val missing = delivery.contracts.filter { it.coordinators.isEmpty() }
            if (missing.isNotEmpty()) {
                val missingIds = missing.joinToString(",") { it.contractId.id }
                return rejected(
                    mutation,
                    MutationErrorCode.MISSING_COORDINATOR,
                    "delivery ${delivery.deliveryId.id} cannot be confirmed: contract(s) $missingIds missing coordinator",
                )
            }
        }
        return null
    }

    /**
     * Rejects an upsert if any newly-added delivery-contract links reference a [Contract] whose
     * [Contract.maxDeliveryDate] is in the past.
     *
     * Only links that are new in the incoming payload relative to the persisted org are checked
     * (a delivery absent from the persisted org has all its links as new). Existing links are
     * never re-validated. Unknown contract ids (not returned by the DAO) pass through.
     *
     * "today" is resolved from [persistedOrg]'s timezone, falling back to the incoming
     * payload's timezone, then [TimeZone.UTC].
     */
    private suspend fun checkNewDeliveryLinksNotEnded(
        organizationId: String,
        persistedOrg: Organization?,
        incoming: Organization,
        mutation: ClientMutation,
    ): MutationOutcome? {
        val today =
            Clock.System.todayIn(
                persistedOrg?.timezone ?: incoming.timezone,
            )

        var orgContracts: List<Contract>? = null

        for (incomingDelivery in incoming.deliveries) {
            val persistedDelivery =
                persistedOrg?.deliveries?.find { it.deliveryId == incomingDelivery.deliveryId }
            val persistedContractIds =
                persistedDelivery?.contracts?.map { it.contractId }?.toSet() ?: emptySet()
            val newContractIds =
                incomingDelivery.contracts.map { it.contractId }.toSet() - persistedContractIds
            if (newContractIds.isEmpty()) continue

            if (orgContracts == null) {
                orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
            }
            val endedIds =
                newContractIds.filter { contractId ->
                    orgContracts.find { it.contractId == contractId }?.isEffectivelyEnded(today) == true
                }
            if (endedIds.isNotEmpty()) {
                return rejected(
                    mutation,
                    MutationErrorCode.CONTRACT_ENDED,
                    "delivery ${incomingDelivery.deliveryId.id} links ended contract(s): ${endedIds.joinToString(",") { it.id }}",
                )
            }
        }
        return null
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

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
                val persistedContract = persistedDelivery?.contracts?.find { it.contractId == incomingContract.contractId }
                if (persistedContract == null) {
                    normalizedContracts += incomingContract.copy(slots = incomingContract.slots.map(::withBackfilledId))
                    continue
                }

                val matchedPersistedByIncomingIndex = matchSlots(persistedContract.slots, incomingContract.slots)

                val deletedSlotOutcome =
                    checkDeletedSlots(persistedContract.slots, matchedPersistedByIncomingIndex.values, mutation, service)
                if (deletedSlotOutcome != null) return Result.Rejected(deletedSlotOutcome)

                val normalizedSlots = mutableListOf<MemberSlot>()
                for ((incomingIndex, incomingSlot) in incomingContract.slots.withIndex()) {
                    val persistedSlot = matchedPersistedByIncomingIndex[incomingIndex]
                    if (persistedSlot == null) {
                        normalizedSlots += withBackfilledId(incomingSlot)
                        continue
                    }
                    if (persistedSlot.status == SlotStatus.CANCELLED && incomingSlot.status != SlotStatus.CANCELLED) {
                        return Result.Rejected(
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
                                registrations =
                                    incomingSlot.registrations.map {
                                        if (it.status ==
                                            RegistrationStatus.CANCELLED
                                        ) {
                                            it
                                        } else {
                                            it.copy(status = RegistrationStatus.CANCELLED)
                                        }
                                    },
                                currentRegistrations = 0,
                            )
                        normalizedSlots += cancelledSlot
                        if (activeMemberIds.isNotEmpty()) {
                            events += SlotEvent(SlotEventKind.CANCELLED, incomingDelivery.deliveryId, cancelledSlot, activeMemberIds)
                        }
                        continue
                    }
                    val rescheduled =
                        incomingSlot.startTime != persistedSlot.startTime || incomingSlot.endTime != persistedSlot.endTime
                    val normalizedSlot = withInheritedId(incomingSlot, persistedSlot)
                    normalizedSlots += normalizedSlot
                    if (rescheduled && activeMemberIds.isNotEmpty()) {
                        events += SlotEvent(SlotEventKind.RESCHEDULED, incomingDelivery.deliveryId, normalizedSlot, activeMemberIds)
                    }
                }
                normalizedContracts += incomingContract.copy(slots = normalizedSlots)
            }
            normalizedDeliveries += incomingDelivery.copy(contracts = normalizedContracts)
        }

        return Result.Normalized(incoming.copy(deliveries = normalizedDeliveries), events)
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

/**
 * Validates that a VOLUNTEER-only caller only mutates their own [MemberRegistration]s
 * within the [Organization] aggregate, and respects slot capacity and delivery status rules.
 *
 * Returns a rejected [MutationOutcome] on the first violation, or null if all checks pass.
 */
internal object VolunteerMutationValidator {
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
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
        }

        // Check each delivery delta
        val persistedDeliveriesById = persisted.deliveries.associateBy { it.deliveryId }
        val incomingDeliveriesById = incoming.deliveries.associateBy { it.deliveryId }

        // Volunteer cannot add or remove deliveries
        if (persistedDeliveriesById.keys != incomingDeliveriesById.keys) {
            return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
        }

        val templateById = templates.associateBy { it.deliveryTemplateId }

        for ((deliveryId, incomingDelivery) in incomingDeliveriesById) {
            val persistedDelivery = persistedDeliveriesById[deliveryId] ?: continue

            // Everything except slots[].registrations must be equal in each delivery
            if (!areNonRegistrationDeliveryFieldsEqual(persistedDelivery, incomingDelivery)) {
                return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
            }

            val persistedContractsById = persistedDelivery.contracts.associateBy { it.contractId }
            val incomingContractsById = incomingDelivery.contracts.associateBy { it.contractId }

            if (persistedContractsById.keys != incomingContractsById.keys) {
                return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
            }

            for ((contractId, incomingContract) in incomingContractsById) {
                val persistedContract = persistedContractsById[contractId] ?: continue

                if (!areNonRegistrationContractFieldsEqual(persistedContract, incomingContract)) {
                    return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
                }

                val persistedSlotsOrdered = persistedContract.slots
                val incomingSlotsOrdered = incomingContract.slots

                if (persistedSlotsOrdered.size != incomingSlotsOrdered.size) {
                    return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
                }

                for ((slotIndex, incomingSlot) in incomingSlotsOrdered.withIndex()) {
                    val persistedSlot = persistedSlotsOrdered[slotIndex]

                    if (!areNonRegistrationSlotFieldsEqual(persistedSlot, incomingSlot)) {
                        return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
                    }

                    val persistedRegistrations = persistedSlot.registrations.toSet()
                    val incomingRegistrations = incomingSlot.registrations.toSet()

                    if (persistedRegistrations == incomingRegistrations) continue

                    // Delta: added and removed registrations
                    val added = incomingRegistrations - persistedRegistrations
                    val removed = persistedRegistrations - incomingRegistrations
                    val delta = added + removed

                    // All delta entries must belong to the caller
                    if (delta.any { it.memberId != memberId }) {
                        return service.rejected(mutation, MutationErrorCode.FORBIDDEN, "volunteer may only modify own registrations")
                    }

                    // A cancelled slot accepts no registration change at all
                    if (persistedSlot.status == SlotStatus.CANCELLED) {
                        return service.rejected(
                            mutation,
                            MutationErrorCode.FORBIDDEN,
                            "cannot register or unregister on a cancelled slot",
                        )
                    }

                    // If adding registrations, delivery must be active
                    if (added.isNotEmpty() && !incomingDelivery.status.isActive()) {
                        return service.rejected(
                            mutation,
                            MutationErrorCode.FORBIDDEN,
                            "cannot register to a delivery that is no longer active",
                        )
                    }

                    // Capacity check for additions
                    if (added.isNotEmpty()) {
                        val capacityOutcome =
                            checkCapacity(
                                slot = incomingSlot,
                                delivery = incomingDelivery,
                                templateById = templateById,
                                mutation = mutation,
                                service = service,
                            )
                        if (capacityOutcome != null) return capacityOutcome
                    }
                }
            }
        }

        return null
    }

    private fun checkCapacity(
        slot: MemberSlot,
        delivery: Delivery,
        templateById: Map<Id<DeliveryTemplate>, DeliveryTemplate>,
        mutation: ClientMutation,
        service: EntityTypeService<OrganizationPayload>,
    ): MutationOutcome? {
        val activeCount = slot.registrations.count { it.status != RegistrationStatus.CANCELLED }
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

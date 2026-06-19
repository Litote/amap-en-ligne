package organization

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import notificationpublisher.NotificationContact
import notificationpublisher.NotificationContent
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
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationCopyOverride
import persistence.model.NotificationType
import persistence.model.Organization
import persistence.model.ProducerManagementMode
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

        checkUpsertPreconditions(auth, mutation, payload, organizationId)?.let { return it }

        val isPrivilegedCaller = auth.roles.any { it == Role.OWNER || it == Role.ADMIN || it == Role.COORDINATOR }
        val isVolunteerCaller = auth.roles.any { it == Role.VOLUNTEER }
        val persistedOrg = organizationSyncDAO.getById(payload.organization.organizationId)

        var normalizedOrg = payload.organization
        var slotEvents = emptyList<SlotLifecycleNormalizer.SlotEvent>()

        if (!isPrivilegedCaller && isVolunteerCaller && persistedOrg != null) {
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
            when (val step = normalizePrivilegedWrite(organizationId, persistedOrg, payload.organization, mutation)) {
                is SlotLifecycleNormalizer.Result.Rejected -> {
                    return step.outcome
                }

                is SlotLifecycleNormalizer.Result.Normalized -> {
                    normalizedOrg = step.organization
                    slotEvents = step.events
                }
            }
        }

        val finalOrg = mergeNoAccountProducts(organizationId, persistedOrg, normalizedOrg)
        organizationSyncDAO.put(finalOrg, buildUpsertChange(organizationId, finalOrg))
        notifySlotEvents(organizationId, slotEvents, finalOrg.notificationOverrides, finalOrg.name)
        return applied(mutation, finalOrg.organizationId.id)
    }

    /** Org-id match, duplicate-delivery-day, and caller-role authorization — checked before any DAO read. */
    private fun checkUpsertPreconditions(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: OrganizationPayload,
        organizationId: String,
    ): MutationOutcome? {
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
        return null
    }

    /** Privileged-caller delivery-link + slot-lifecycle normalization. */
    private suspend fun normalizePrivilegedWrite(
        organizationId: String,
        persistedOrg: Organization?,
        incoming: Organization,
        mutation: ClientMutation,
    ): SlotLifecycleNormalizer.Result {
        val endedLinksOutcome = checkNewDeliveryLinksNotEnded(organizationId, persistedOrg, incoming, mutation)
        if (endedLinksOutcome != null) {
            return SlotLifecycleNormalizer.Result.Rejected(endedLinksOutcome)
        }
        val coordinatorPoolOutcome = checkCoordinatorsInContractPool(organizationId, persistedOrg, incoming, mutation)
        if (coordinatorPoolOutcome != null) {
            return SlotLifecycleNormalizer.Result.Rejected(coordinatorPoolOutcome)
        }
        return SlotLifecycleNormalizer.process(persistedOrg, incoming, mutation, this)
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
                notifySlotEvent(event, members, notificationOverrides, organizationName)
            }
        }.onFailure { logger.warn(it) { "failed to send slot lifecycle notifications" } }
    }

    private suspend fun notifySlotEvent(
        event: SlotLifecycleNormalizer.SlotEvent,
        members: List<Member>,
        notificationOverrides: Map<NotificationCategory, NotificationCopyOverride>,
        organizationName: String,
    ) {
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
                content =
                    NotificationContent(
                        title = copy.title,
                        body = copy.body,
                        relatedEntityId = event.deliveryId.id,
                    ),
                contact = NotificationContact(email = member.email, organizationName = organizationName),
                channels = notificationChannelsFor(member),
            )
        }
    }

    private fun notificationChannelsFor(member: Member): Set<NotificationChannel> =
        buildSet {
            if (member.userPreferences.emailNotificationsEnabled) add(NotificationChannel.EMAIL)
            if (member.userPreferences.pushNotificationsEnabled) add(NotificationChannel.PUSH)
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

    /**
     * Rejects an upsert that assigns a delivery-contract coordinator who is not part of the linked
     * [Contract.coordinators] pool. A delivery-contract coordinator is the "effective" coordinator
     * present for that delivery and must be chosen among the contract's coordinators.
     *
     * Only coordinators newly added in the incoming payload (relative to the same persisted
     * delivery-contract) are validated, so legacy data and unrelated edits are never re-checked.
     * Unknown contract ids (not returned by the DAO) pass through.
     */
    private suspend fun checkCoordinatorsInContractPool(
        organizationId: String,
        persistedOrg: Organization?,
        incoming: Organization,
        mutation: ClientMutation,
    ): MutationOutcome? {
        var orgContracts: List<Contract>? = null

        for (incomingDelivery in incoming.deliveries) {
            val persistedDelivery =
                persistedOrg?.deliveries?.find { it.deliveryId == incomingDelivery.deliveryId }
            for (incomingContract in incomingDelivery.contracts) {
                val persistedCoordinators =
                    persistedDelivery
                        ?.contracts
                        ?.find { it.contractId == incomingContract.contractId }
                        ?.coordinators
                        ?.toSet() ?: emptySet()
                val newCoordinators = incomingContract.coordinators.toSet() - persistedCoordinators
                if (newCoordinators.isEmpty()) continue

                if (orgContracts == null) {
                    orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
                }
                val pool =
                    orgContracts.find { it.contractId == incomingContract.contractId }?.coordinators?.toSet()
                        ?: continue
                val outsiders = newCoordinators.filter { it !in pool }
                if (outsiders.isNotEmpty()) {
                    return rejected(
                        mutation,
                        MutationErrorCode.INVALID_PAYLOAD,
                        "delivery ${incomingDelivery.deliveryId.id} contract ${incomingContract.contractId.id} " +
                            "assigns coordinator(s) not in the contract pool: ${outsiders.joinToString(",") { it.id }}",
                    )
                }
            }
        }
        return null
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

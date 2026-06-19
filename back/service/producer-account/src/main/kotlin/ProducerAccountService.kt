package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.OwnersBroadcastEvent
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.EntityType
import persistence.model.LinkedProducerAccount
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.Product

private sealed class ProducerAccountUpsertNormalization {
    data class Success(
        val producerAccount: ProducerAccount,
    ) : ProducerAccountUpsertNormalization()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerAccountUpsertNormalization()
}

private sealed class ProducerAccountLinkResolution {
    data class Success(
        val linkedProducerAccount: LinkedProducerAccount?,
    ) : ProducerAccountLinkResolution()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerAccountLinkResolution()
}

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProducerAccountService(
    val producerAccountSyncDAO: ProducerAccountSyncDAO,
    val organizationSyncDAO: OrganizationSyncDAO,
    private val userProvisioningPort: UserProvisioningPort,
    private val accountLifecycleEmailPort: AccountLifecycleEmailPort,
    private val accountDeletionLogDAO: persistence.dao.AccountDeletionLogDAO,
) : EntityTypeService<ProducerAccountPayload>(EntityType.ProducerAccount) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerAccountPayload,
    ): MutationOutcome {
        // OWNER caller path: only `active_status` flips are accepted — the
        // rest of the producer profile is owned by the producer-scoped admin
        // flow. Routes through `suspend` / `reactivate`.
        if (auth.roles.any { it == Role.OWNER }) {
            return applyOwnerStatusChange(auth, mutation, payload)
        }
        // PRODUCER self-profile update: name, contactEmail, address, website.
        if (auth.roles.any { it == Role.PRODUCER }) {
            return applyProducerSelfProfileUpdate(auth, mutation, payload)
        }
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        val normalizedProducer =
            normalizeAdminUpsert(
                organizationId = organizationId,
                incoming = payload.producerAccount,
            )
        return when (normalizedProducer) {
            is ProducerAccountUpsertNormalization.Rejected -> {
                rejected(mutation, normalizedProducer.code, normalizedProducer.message)
            }

            is ProducerAccountUpsertNormalization.Success -> {
                producerAccountSyncDAO.put(
                    normalizedProducer.producerAccount,
                    organizationId.toId(),
                    buildUpsertChanges(organizationId, normalizedProducer.producerAccount),
                )
                if (normalizedProducer.producerAccount.managementMode == ProducerManagementMode.NO_ACCOUNT) {
                    deriveOrganizationProducts(organizationId, normalizedProducer.producerAccount)
                }
                applied(mutation, normalizedProducer.producerAccount.producerAccountId.id)
            }
        }
    }

    private suspend fun normalizeAdminUpsert(
        organizationId: String,
        incoming: ProducerAccount,
    ): ProducerAccountUpsertNormalization {
        val isTmpId = incoming.producerAccountId.id.startsWith(ClientMutation.TMP_ID_PREFIX)
        val existing =
            if (isTmpId) {
                null
            } else {
                producerAccountSyncDAO.findById(incoming.producerAccountId)
            }

        if (!isTmpId && existing == null) {
            return rejectUpsert(
                MutationErrorCode.NOT_FOUND,
                "producer account not found: ${incoming.producerAccountId.id}",
            )
        }

        if (existing != null && existing.managementMode != incoming.managementMode) {
            return rejectUpsert(MutationErrorCode.INVALID_PAYLOAD, "producer management_mode is immutable")
        }

        if (isTmpId && incoming.managementMode != ProducerManagementMode.NO_ACCOUNT) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "only no-account producers can be created through organization sync",
            )
        }

        val resolvedId =
            if (isTmpId) {
                generateId()
            } else {
                incoming.producerAccountId
            }

        val normalizedOrganizations =
            when (incoming.managementMode) {
                ProducerManagementMode.ACCOUNT_BACKED -> {
                    ensureOrganizationAssociation(
                        producer = incoming,
                        organizationId = organizationId,
                    )
                }

                ProducerManagementMode.NO_ACCOUNT -> {
                    val enforcedOrganization =
                        existing?.organizations?.singleOrNull()
                            ?: incoming.organizations.singleOrNull()
                            ?: ProducerOrganization(
                                organizationId = organizationId.toId(),
                                associationInstant = incoming.createdInstant,
                                status = OrganizationProducerStatus.ACTIVE,
                            )
                    if (enforcedOrganization.organizationId.id != organizationId) {
                        return rejectUpsert(
                            MutationErrorCode.INVALID_PAYLOAD,
                            "no-account producers must belong to the caller organization",
                        )
                    }
                    if (incoming.organizations.size > 1) {
                        return rejectUpsert(
                            MutationErrorCode.INVALID_PAYLOAD,
                            "no-account producers cannot be linked to multiple organizations",
                        )
                    }
                    listOf(enforcedOrganization)
                }
            }

        if (incoming.managementMode == ProducerManagementMode.NO_ACCOUNT && incoming.users.isNotEmpty()) {
            return rejectUpsert(MutationErrorCode.INVALID_PAYLOAD, "no-account producers cannot declare producer users")
        }

        if (incoming.managementMode == ProducerManagementMode.ACCOUNT_BACKED && incoming.linkedProducerAccount != null) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "account-backed producers cannot point to a linked producer account",
            )
        }

        val normalizedLinkedProducerAccount =
            if (incoming.managementMode == ProducerManagementMode.NO_ACCOUNT) {
                resolveLinkedProducerAccount(
                    organizationId = organizationId,
                    sourceProducerAccountId = resolvedId.id,
                    requestedLink = incoming.linkedProducerAccount,
                    existingLink = existing?.linkedProducerAccount,
                ).let { linkedProducerAccountOutcome ->
                    when (linkedProducerAccountOutcome) {
                        is ProducerAccountLinkResolution.Rejected -> {
                            return ProducerAccountUpsertNormalization.Rejected(
                                code = linkedProducerAccountOutcome.code,
                                message = linkedProducerAccountOutcome.message,
                            )
                        }

                        is ProducerAccountLinkResolution.Success -> {
                            linkedProducerAccountOutcome.linkedProducerAccount
                        }
                    }
                }
            } else {
                null
            }

        return ProducerAccountUpsertNormalization.Success(
            incoming.copy(
                producerAccountId = resolvedId,
                organizations = normalizedOrganizations,
                managementMode = incoming.managementMode,
                linkedProducerAccount = normalizedLinkedProducerAccount,
            ),
        )
    }

    private suspend fun resolveLinkedProducerAccount(
        organizationId: String,
        sourceProducerAccountId: String,
        requestedLink: LinkedProducerAccount?,
        existingLink: LinkedProducerAccount?,
    ): ProducerAccountLinkResolution {
        val targetProducerAccountId = requestedLink?.producerAccountId ?: existingLink?.producerAccountId
        if (targetProducerAccountId == null) {
            return ProducerAccountLinkResolution.Success(null)
        }
        if (targetProducerAccountId.id == sourceProducerAccountId) {
            return rejectLink(MutationErrorCode.INVALID_PAYLOAD, "a producer cannot link to itself")
        }

        val target =
            producerAccountSyncDAO.findById(targetProducerAccountId)
                ?: return rejectLink(
                    MutationErrorCode.NOT_FOUND,
                    "linked account-backed producer not found: ${targetProducerAccountId.id}",
                )
        if (target.managementMode != ProducerManagementMode.ACCOUNT_BACKED) {
            return rejectLink(MutationErrorCode.INVALID_PAYLOAD, "linked producer target must be account-backed")
        }

        val conflictingLink =
            producerAccountSyncDAO
                .getByOrganizationId(organizationId.toId())
                .firstOrNull {
                    it.producerAccountId.id != sourceProducerAccountId &&
                        it.managementMode == ProducerManagementMode.NO_ACCOUNT &&
                        it.linkedProducerAccount?.producerAccountId == targetProducerAccountId
                }
        if (conflictingLink != null) {
            return rejectLink(
                MutationErrorCode.CONFLICT,
                "linked account-backed producer already used by ${conflictingLink.producerAccountId.id}",
            )
        }
        return LinkedProducerAccount(
            producerAccountId = target.producerAccountId,
            name = target.name,
        ).let(ProducerAccountLinkResolution::Success)
    }

    private fun ensureOrganizationAssociation(
        producer: ProducerAccount,
        organizationId: String,
    ): List<ProducerOrganization> {
        val existingAssociation = producer.organizations.firstOrNull { it.organizationId.id == organizationId }
        return if (existingAssociation != null) {
            producer.organizations
        } else {
            producer.organizations +
                ProducerOrganization(
                    organizationId = organizationId.toId(),
                    associationInstant = producer.lastUpdatedInstant,
                    status = OrganizationProducerStatus.ACTIVE,
                )
        }
    }

    private fun rejectUpsert(
        code: MutationErrorCode,
        message: String,
    ) = ProducerAccountUpsertNormalization.Rejected(code, message)

    private fun rejectLink(
        code: MutationErrorCode,
        message: String,
    ) = ProducerAccountLinkResolution.Rejected(code, message)

    private suspend fun applyProducerSelfProfileUpdate(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerAccountPayload,
    ): MutationOutcome {
        val incoming = payload.producerAccount
        // sub == producerAccountId by invariant for PRODUCER callers
        if (incoming.producerAccountId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "PRODUCER may only update their own profile")
        }
        val outcome =
            updateProfile(
                producerAccountId = incoming.producerAccountId.id,
                update =
                    ProducerAccountProfileUpdate(
                        name = incoming.name,
                        contactEmail = incoming.contactEmail,
                        address = incoming.address,
                        website = incoming.website,
                    ),
            )
        return when (outcome) {
            is ProducerLifecycleOutcome.Success -> {
                applied(mutation, incoming.producerAccountId.id)
            }

            is ProducerLifecycleOutcome.NotFound -> {
                rejected(
                    mutation,
                    MutationErrorCode.NOT_FOUND,
                    "producer account not found: ${incoming.producerAccountId.id}",
                )
            }

            is ProducerLifecycleOutcome.Rejected -> {
                rejected(mutation, outcome.code, outcome.message)
            }
        }
    }

    private suspend fun applyOwnerStatusChange(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerAccountPayload,
    ): MutationOutcome {
        val target = payload.producerAccount
        val outcome =
            if (target.activeStatus) {
                reactivate(auth.memberId, target.producerAccountId.id)
            } else {
                suspend(auth.memberId, target.producerAccountId.id)
            }
        return when (outcome) {
            is ProducerLifecycleOutcome.Success -> {
                applied(mutation, target.producerAccountId.id)
            }

            is ProducerLifecycleOutcome.Rejected -> {
                rejected(mutation, outcome.code, outcome.message)
            }

            is ProducerLifecycleOutcome.NotFound -> {
                rejected(mutation, MutationErrorCode.NOT_FOUND, "producer account not found: ${target.producerAccountId.id}")
            }
        }
    }

    /**
     * Suspends a producer account at the request of an OWNER. Flips
     * `active_status = false` on every denormalised row, then propagates a
     * Change to each linked organization scope + the `instance-owner` scope
     * so all sync feeds reflect the new state.
     *
     * Side-effects (best-effort):
     *  - `AccountLifecycleEmailPort.notifyAccountSuspended` — addressed to the
     *    producer contact email. The PRODUCER auth users associated to this
     *    producer account are not banned individually yet (phase 2.5 — port
     *    extension required to enumerate them from the auth provider).
     *  - Owners broadcast — PII-free notification of the action.
     */
    suspend fun suspend(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome = transition(actorSub, producerAccountId, activeStatus = false)

    /** Reactivates a previously suspended producer account. Symmetric of [suspend]. */
    suspend fun reactivate(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome = transition(actorSub, producerAccountId, activeStatus = true)

    /**
     * Deletes a producer at the request of an OWNER (Phase 2.5).
     *
     * Per the spec ("l'Organization productrice est conservée") the producer
     * entity row is **kept** but flipped to `active_status = false`. The
     * destructive work happens at the auth-provider layer:
     *
     *  1. Enumerate auth users whose JWT `producer_account_id` matches.
     *  2. Delete each from the auth provider.
     *  3. Append one [AccountDeletionLog] entry per deleted sub
     *     (`deleted_role = PRODUCER`, SHA-256-hashed sub, actor preserved).
     *  4. Flip `active_status = false` and fan out Changes.
     *  5. Fire email notifications.
     *
     * If no auth user references this producer, the call still succeeds and
     * flips `active_status` — the producer account is left "unattached".
     */
    suspend fun delete(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound

        // SELF_ACTION_FORBIDDEN: irrelevant for producers (an OWNER cannot
        // hold the PRODUCER role per ADR-001 — RoleService is the trust
        // boundary).

        // 1. Enumerate auth users tied to this producer (best-effort — the
        // port returns empty if the auth provider is unreachable or no user
        // exists). On port failure we still proceed with the state flip.
        val authSubs =
            runCatching { userProvisioningPort.listAuthSubsByProducerAccount(producerAccountId) }
                .onFailure { e ->
                    logger.error(e) { "Failed to enumerate auth users for producer $producerAccountId" }
                }.getOrDefault(emptyList())

        // 2. Delete each auth user. Idempotent on the port side.
        authSubs.forEach { sub ->
            runCatching { userProvisioningPort.deleteUser(sub) }
                .onFailure { e -> logger.error(e) { "deleteUser($sub) failed during producer delete" } }
        }

        // 3. Audit-log one entry per deleted sub. If no sub was found, write
        // one entry hashed on the producer_account_id so the deletion event
        // is traceable.
        val now =
            kotlin.time.Clock.System
                .now()
        val subsForAudit = authSubs.ifEmpty { listOf("producer-account:$producerAccountId") }
        subsForAudit.forEach { sub ->
            runCatching {
                accountDeletionLogDAO.append(
                    persistence.model.AccountDeletionLog(
                        id = id.generateId(),
                        deletedSubHash = sha256(sub),
                        deletedRole = persistence.model.DeletedAccountRole.PRODUCER,
                        deletedAt = now,
                        actorOwnerId = actorSub.toId(),
                    ),
                )
            }.onFailure { e -> logger.error(e) { "audit log append failed for producer $producerAccountId" } }
        }

        // 4. Flip active_status (idempotent — only writes if changing).
        if (producer.activeStatus) {
            val updated = producer.copy(activeStatus = false)
            producerAccountSyncDAO.updateActiveStatus(
                producer.producerAccountId,
                activeStatus = false,
                changes = buildStatusChangeChanges(updated),
            )
        }

        // 5. Email side-effects.
        sideEffectsForDelete(producer)

        logger.info {
            "Producer $producerAccountId deleted by actor=$actorSub: " +
                "${authSubs.size} auth user(s) removed, producer entity kept inactive"
        }
        return ProducerLifecycleOutcome.Success
    }

    private suspend fun sideEffectsForDelete(producer: ProducerAccount) {
        val target =
            AccountLifecycleTarget(
                sub = producer.producerAccountId.id,
                email = producer.contactEmail ?: "(unknown)",
                firstName = producer.name,
                lastName = "",
                role = AccountLifecycleRole.PRODUCER,
            )
        runCatching { accountLifecycleEmailPort.notifyAccountDeleted(target) }
            .onFailure { e -> logger.error(e) { "Producer delete email failed for ${producer.producerAccountId.id}" } }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event = OwnersBroadcastEvent.ACCOUNT_DELETED,
                actorOwnerEmail = "(actor email unavailable)",
                impactedRole = AccountLifecycleRole.PRODUCER,
            )
        }.onFailure { e -> logger.error(e) { "Producer delete Owners broadcast failed" } }
    }

    private fun ProducerLifecycleOutcome.toMutationOutcome(
        mutation: ClientMutation,
        entityId: String,
    ): MutationOutcome =
        when (this) {
            is ProducerLifecycleOutcome.Success -> {
                applied(mutation, entityId)
            }

            is ProducerLifecycleOutcome.Rejected -> {
                rejected(mutation, code, message)
            }

            is ProducerLifecycleOutcome.NotFound -> {
                rejected(mutation, MutationErrorCode.NOT_FOUND, "producer account not found: $entityId")
            }
        }

    private suspend fun transition(
        actorSub: String,
        producerAccountId: String,
        activeStatus: Boolean,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound

        // SELF_ACTION_FORBIDDEN: deferred. ProducerUser does not yet carry
        // the auth sub (producer_id is an internal id), so the actor↔target
        // sub comparison is not implementable here. OWNER role is exclusive
        // (cf. ADR-001) so an OWNER cannot also be PRODUCER in practice —
        // the back-end RoleService is the trust boundary.

        if (producer.activeStatus == activeStatus) {
            // Idempotent — nothing to write, no side-effects to fire.
            return ProducerLifecycleOutcome.Success
        }

        val updatedProducer = producer.copy(activeStatus = activeStatus)
        val changes = buildStatusChangeChanges(updatedProducer)
        producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, activeStatus, changes)

        sideEffects(
            producer = updatedProducer,
            activeStatus = activeStatus,
        )
        return ProducerLifecycleOutcome.Success
    }

    /**
     * Updates the profile fields of the producer account identified by [producerAccountId].
     * Only name, contactEmail, address and website are updated; other fields are preserved.
     */
    suspend fun updateProfile(
        producerAccountId: String,
        update: ProducerAccountProfileUpdate,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound
        val updated =
            producer.copy(
                name = update.name,
                contactEmail = update.contactEmail,
                address = update.address,
                website = update.website,
                lastUpdatedInstant =
                    kotlin.time.Clock.System
                        .now(),
            )
        val changes = buildStatusChangeChanges(updated)
        producerAccountSyncDAO.updateProfile(updated, changes)
        return ProducerLifecycleOutcome.Success
    }

    /**
     * Derives [Organization.products] for a NO_ACCOUNT producer from its [ProducerAccount.products].
     *
     * Fetches the current org, replaces any products previously owned by this producer with the
     * new derived list (converting [ProducerProduct] → [Organization.Product]), then atomically
     * persists the updated org alongside an organization-scoped [Change] so the sync feed picks it
     * up.
     */
    private suspend fun deriveOrganizationProducts(
        organizationId: String,
        producerAccount: ProducerAccount,
    ) {
        val currentOrg = organizationSyncDAO.getById(organizationId.toId()) ?: return
        val derivedProducts =
            producerAccount.products.map { p ->
                Product(
                    name = p.name,
                    productTypeId = p.productTypeId,
                    producerAccountId = producerAccount.producerAccountId,
                    supportedBasketSizes = p.supportedBasketSizes,
                    description = p.description,
                )
            }
        val otherProducts =
            currentOrg.products.filter { it.producerAccountId != producerAccount.producerAccountId }
        val updatedOrg = currentOrg.copy(products = otherProducts + derivedProducts)
        val orgChange =
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Organization,
                entityId = updatedOrg.organizationId.id,
                scopeKey = SyncScope.Organization(organizationId).key,
                op = ChangeOp.UPSERT,
                payload = OrganizationPayload(updatedOrg),
                producedAt = System.currentTimeMillis(),
            )
        organizationSyncDAO.put(updatedOrg, orgChange)
    }

    private fun buildStatusChangeChanges(producer: ProducerAccount): List<Change> =
        buildList {
            producer.organizations
                .map { it.organizationId.id }
                .distinct()
                .forEach { organizationId ->
                    add(
                        Change(
                            cursor = Cursor.next(),
                            entityType = EntityType.ProducerAccount,
                            entityId = producer.producerAccountId.id,
                            scopeKey = SyncScope.Organization(organizationId).key,
                            op = ChangeOp.UPSERT,
                            payload = ProducerAccountPayload(producer),
                            producedAt = System.currentTimeMillis(),
                        ),
                    )
                }
            add(
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.ProducerAccount,
                    entityId = producer.producerAccountId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = ProducerAccountPayload(producer),
                    producedAt = System.currentTimeMillis(),
                ),
            )
        }

    private suspend fun sideEffects(
        producer: ProducerAccount,
        activeStatus: Boolean,
    ) {
        // TODO phase 2.5: enumerate auth users (sub) attached to this producer
        // account and call userProvisioningPort.banUser / unbanUser for each.
        // For now we only fire the email notification — the producer email
        // address is the producer-level contact, not the individual user's.
        val target =
            AccountLifecycleTarget(
                sub = producer.producerAccountId.id, // best-effort identity until producer→sub link exists
                email = producer.contactEmail ?: "(unknown)",
                firstName = producer.name,
                lastName = "",
                role = AccountLifecycleRole.PRODUCER,
            )
        runCatching {
            if (activeStatus) {
                accountLifecycleEmailPort.notifyAccountReactivated(target)
            } else {
                accountLifecycleEmailPort.notifyAccountSuspended(target)
            }
        }.onFailure { e ->
            logger.error(e) { "Producer lifecycle email failed for ${producer.producerAccountId.id}" }
        }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event =
                    if (activeStatus) {
                        OwnersBroadcastEvent.ACCOUNT_REACTIVATED
                    } else {
                        OwnersBroadcastEvent.ACCOUNT_SUSPENDED
                    },
                actorOwnerEmail = "(actor email unavailable)",
                impactedRole = AccountLifecycleRole.PRODUCER,
            )
        }.onFailure { e ->
            logger.error(e) { "Producer lifecycle Owners broadcast failed" }
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        // OWNER caller (Phase 2.5): full producer deletion — enumerate auth
        // users tied to this producer account, delete each, append audit log
        // entries, and mark the producer_account inactive (per spec, the
        // producer entity is preserved for future re-attachment).
        if (auth.roles.any { it == Role.OWNER }) {
            return delete(auth.memberId, op.entityId).toMutationOutcome(mutation, op.entityId)
        }
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        val existingProducer =
            producerAccountSyncDAO
                .getByOrganizationId(organizationId.toId())
                .find { it.producerAccountId.id == op.entityId }
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "producer account not found")
        val remainingOrganizations =
            existingProducer.organizations.filterNot { it.organizationId.id == organizationId }
        val remainingProducer = existingProducer.copy(organizations = remainingOrganizations)
        producerAccountSyncDAO.delete(
            op.entityId.toId(),
            organizationId.toId(),
            buildDeleteChanges(
                deletedOrganizationId = organizationId,
                existingProducer = remainingProducer,
            ),
        )
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ProducerAccountPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return producerAccountSyncDAO
            .getByOrganizationId(organizationId.toId())
            .map { ProducerAccountPayload(it) }
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<ProducerAccountPayload> =
        when (scope) {
            is SyncScope.ProducerAccount -> {
                emptyList()
            }

            is SyncScope.Organization -> {
                snapshot(auth)
            }

            SyncScope.InstanceOwner -> {
                producerAccountSyncDAO.listAll().map { ProducerAccountPayload(it) }
            }

            is SyncScope.Member,
            is SyncScope.Owner,
            -> {
                emptyList()
            }
        }

    private fun buildUpsertChanges(
        organizationId: String,
        producerAccount: ProducerAccount,
    ): List<Change> {
        val visibleOrganizationIds =
            (producerAccount.organizations.map { it.organizationId.id } + organizationId)
                .distinct()
        return buildList {
            visibleOrganizationIds.forEach { visibleOrganizationId ->
                add(
                    Change(
                        cursor = Cursor.next(),
                        entityType = EntityType.ProducerAccount,
                        entityId = producerAccount.producerAccountId.id,
                        scopeKey = SyncScope.Organization(visibleOrganizationId).key,
                        op = ChangeOp.UPSERT,
                        payload = ProducerAccountPayload(producerAccount),
                        producedAt = System.currentTimeMillis(),
                    ),
                )
            }
            // OWNER instance-wide feed.
            add(
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.ProducerAccount,
                    entityId = producerAccount.producerAccountId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = ProducerAccountPayload(producerAccount),
                    producedAt = System.currentTimeMillis(),
                ),
            )
        }
    }

    private fun buildDeleteChanges(
        deletedOrganizationId: String,
        existingProducer: ProducerAccount,
    ): List<Change> =
        buildList {
            add(
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.ProducerAccount,
                    entityId = existingProducer.producerAccountId.id,
                    scopeKey = SyncScope.Organization(deletedOrganizationId).key,
                    op = ChangeOp.DELETE,
                    payload = null,
                    producedAt = System.currentTimeMillis(),
                ),
            )
            existingProducer.organizations
                .map { it.organizationId.id }
                .distinct()
                .forEach { organizationId ->
                    add(
                        Change(
                            cursor = Cursor.next(),
                            entityType = EntityType.ProducerAccount,
                            entityId = existingProducer.producerAccountId.id,
                            scopeKey = SyncScope.Organization(organizationId).key,
                            op = ChangeOp.UPSERT,
                            payload = ProducerAccountPayload(existingProducer),
                            producedAt = System.currentTimeMillis(),
                        ),
                    )
                }
            // OWNER instance-wide feed: upsert the remaining producer state if
            // any organizations remain, delete tombstone otherwise.
            if (existingProducer.organizations.isEmpty()) {
                add(
                    Change(
                        cursor = Cursor.next(),
                        entityType = EntityType.ProducerAccount,
                        entityId = existingProducer.producerAccountId.id,
                        scopeKey = SyncScope.InstanceOwner.key,
                        op = ChangeOp.DELETE,
                        payload = null,
                        producedAt = System.currentTimeMillis(),
                    ),
                )
            } else {
                add(
                    Change(
                        cursor = Cursor.next(),
                        entityType = EntityType.ProducerAccount,
                        entityId = existingProducer.producerAccountId.id,
                        scopeKey = SyncScope.InstanceOwner.key,
                        op = ChangeOp.UPSERT,
                        payload = ProducerAccountPayload(existingProducer),
                        producedAt = System.currentTimeMillis(),
                    ),
                )
            }
        }

    private companion object {
        private val logger = KotlinLogging.logger {}

        private fun sha256(input: String): String =
            java.security.MessageDigest
                .getInstance("SHA-256")
                .digest(input.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it) }
    }
}

sealed class ProducerLifecycleOutcome {
    data object Success : ProducerLifecycleOutcome()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerLifecycleOutcome()

    data object NotFound : ProducerLifecycleOutcome()
}

data class ProducerAccountProfileUpdate(
    val name: String,
    val contactEmail: String?,
    val address: String?,
    val website: String?,
)

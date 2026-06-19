package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.toId
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
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.Product

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProducerAccountService(
    val producerAccountSyncDAO: ProducerAccountSyncDAO,
    val organizationSyncDAO: OrganizationSyncDAO,
    private val upsertNormalizer: ProducerAccountUpsertNormalizer,
    private val changeFactory: ProducerAccountChangeFactory,
    private val lifecycleService: ProducerAccountLifecycleService,
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
            upsertNormalizer.normalizeAdminUpsert(
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
                    changeFactory.buildUpsertChanges(organizationId, normalizedProducer.producerAccount),
                )
                if (normalizedProducer.producerAccount.managementMode == ProducerManagementMode.NO_ACCOUNT) {
                    deriveOrganizationProducts(organizationId, normalizedProducer.producerAccount)
                }
                applied(mutation, normalizedProducer.producerAccount.producerAccountId.id)
            }
        }
    }

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
            lifecycleService.updateProfile(
                producerAccountId = incoming.producerAccountId.id,
                update =
                    ProducerAccountProfileUpdate(
                        name = incoming.name,
                        contactEmail = incoming.contactEmail,
                        address = incoming.address,
                        website = incoming.website,
                        userPreferences = incoming.userPreferences,
                    ),
            )
        return outcome.toMutationOutcome(mutation, incoming.producerAccountId.id)
    }

    private suspend fun applyOwnerStatusChange(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerAccountPayload,
    ): MutationOutcome {
        val target = payload.producerAccount
        val outcome =
            if (target.activeStatus) {
                lifecycleService.reactivate(auth.memberId, target.producerAccountId.id)
            } else {
                lifecycleService.suspend(auth.memberId, target.producerAccountId.id)
            }
        return outcome.toMutationOutcome(mutation, target.producerAccountId.id)
    }

    /**
     * Derives [persistence.model.Organization.products] for a NO_ACCOUNT producer from its
     * [ProducerAccount.products].
     *
     * Fetches the current org, replaces any products previously owned by this producer with the
     * new derived list (converting [persistence.model.ProducerProduct] → [Product]), then
     * atomically persists the updated org alongside an organisation-scoped [Change] so the sync
     * feed picks it up.
     *
     * Note: [persistence.model.Organization]-side product merging (`mergeNoAccountProducts`) in
     * [organization.OrganizationService] addresses a similar concern. Unifying the two is deferred
     * — it requires cross-service design decisions beyond a mechanical split.
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
            return lifecycleService.delete(auth.memberId, op.entityId).toMutationOutcome(mutation, op.entityId)
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
            changeFactory.buildDeleteChanges(
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
}

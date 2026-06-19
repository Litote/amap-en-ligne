package contract

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.generateId
import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.Contract
import persistence.model.EntityType
import persistence.model.MemberContractStatus
import persistence.model.SharedBasket
import kotlin.time.Clock

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ContractService(
    val contractSyncDAO: ContractSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
) : EntityTypeService<ContractPayload>(EntityType.Contract) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ContractPayload,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        requireAnyRole(auth, ALLOWED_ROLES, mutation, "only OWNER, ADMIN, or COORDINATOR may manage contracts")
            ?.let { return it }
        if (payload.contract.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }
        validateSubscriptions(mutation, payload.contract)?.let { return it }
        validateSharedBaskets(mutation, payload.contract)?.let { return it }

        val existingContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
        val duplicate = existingContracts.find { it.name == payload.contract.name && it.contractId != payload.contract.contractId }
        if (duplicate != null) {
            return rejected(
                mutation,
                MutationErrorCode.UNIQUE_VIOLATION,
                "a contract named '${payload.contract.name}' already exists in this organization",
            )
        }

        val realId =
            if (payload.contract.contractId.id
                    .startsWith(ClientMutation.TMP_ID_PREFIX)
            ) {
                generateId<Contract>()
            } else {
                payload.contract.contractId
            }
        val contract =
            payload.contract.copy(
                contractId = realId,
                sharedBaskets = allocateSharedBasketIds(payload.contract.sharedBaskets),
            )

        val persisted = existingContracts.find { it.contractId == contract.contractId }

        if (persisted != null) {
            val newMemberIds =
                contract.members
                    .map { it.memberId }
                    .toSet() -
                    persisted.members.map { it.memberId }.toSet()
            if (newMemberIds.isNotEmpty()) {
                val today = resolveToday(organizationId)
                if (persisted.isEffectivelyEnded(today)) {
                    return rejected(
                        mutation,
                        MutationErrorCode.CONTRACT_ENDED,
                        "contract ${persisted.contractId.id} ended on ${persisted.maxDeliveryDate}: cannot add new member subscriptions",
                    )
                }
            }
        }

        contractSyncDAO.put(contract, buildUpsertChange(organizationId, contract))
        return applied(mutation, realId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        requireAnyRole(auth, ALLOWED_ROLES, mutation, "only OWNER, ADMIN, or COORDINATOR may manage contracts")
            ?.let { return it }
        val contract =
            contractSyncDAO
                .getByOrganizationId(organizationId.toId())
                .find { it.contractId.id == op.entityId }
        if (contract != null && contract.members.any { it.status != MemberContractStatus.CANCELLED }) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "contract has active members")
        }
        contractSyncDAO.delete(
            op.entityId.toId(),
            organizationId.toId(),
            buildDeleteChange(organizationId, op.entityId),
        )
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ContractPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return contractSyncDAO.getByOrganizationId(organizationId.toId()).map { ContractPayload(it) }
    }

    private suspend fun resolveToday(organizationId: String): LocalDate {
        val timezone = organizationSyncDAO.getById(organizationId.toId())?.timezone ?: TimeZone.UTC
        return Clock.System.todayIn(timezone)
    }

    private fun validateSubscriptions(
        mutation: ClientMutation,
        contract: Contract,
    ): MutationOutcome? {
        val offered = contract.productPrices.map { it.productTypeId to it.basketSize }.toSet()
        for (member in contract.members) {
            if (member.subscriptions.isEmpty()) {
                return rejected(
                    mutation,
                    MutationErrorCode.INVALID_SUBSCRIPTION,
                    "member ${member.memberId.id} has no subscription: at least one product subscription is required",
                )
            }
            for (sub in member.subscriptions) {
                if ((sub.productTypeId to sub.basketSize) !in offered) {
                    return rejected(
                        mutation,
                        MutationErrorCode.INVALID_SUBSCRIPTION,
                        "member ${member.memberId.id} subscription (product_type_id=${sub.productTypeId}, basket_size=${sub.basketSize?.name}) does not match any contract product price",
                    )
                }
            }
        }
        return null
    }

    /**
     * Validates the contract's shared baskets (overlay groups of members alternating on one
     * physical basket). Rejects with [MutationErrorCode.INVALID_SHARED_BASKET] when a group has
     * fewer than two members, references a member that is not a contract member, a member appears
     * in two groups, or the grouped members do not share an identical (non-empty) subscription.
     */
    private fun validateSharedBaskets(
        mutation: ClientMutation,
        contract: Contract,
    ): MutationOutcome? {
        if (contract.sharedBaskets.isEmpty()) return null
        val memberIds = contract.members.map { it.memberId }.toSet()
        val subscriptionsByMember = contract.members.associate { it.memberId to it.subscriptions.toSet() }
        val seen = mutableSetOf<String>()
        for (basket in contract.sharedBaskets) {
            if (basket.memberIds.size < 2) {
                return rejected(
                    mutation,
                    MutationErrorCode.INVALID_SHARED_BASKET,
                    "shared basket ${basket.sharedBasketId.id} must group at least two members",
                )
            }
            for (memberId in basket.memberIds) {
                if (memberId !in memberIds) {
                    return rejected(
                        mutation,
                        MutationErrorCode.INVALID_SHARED_BASKET,
                        "shared basket ${basket.sharedBasketId.id} references member ${memberId.id} which is not a contract member",
                    )
                }
                if (!seen.add(memberId.id)) {
                    return rejected(
                        mutation,
                        MutationErrorCode.INVALID_SHARED_BASKET,
                        "member ${memberId.id} appears in more than one shared basket",
                    )
                }
            }
            val subscriptions = basket.memberIds.map { subscriptionsByMember[it].orEmpty() }
            val reference = subscriptions.first()
            if (reference.isEmpty() || subscriptions.any { it != reference }) {
                return rejected(
                    mutation,
                    MutationErrorCode.INVALID_SHARED_BASKET,
                    "shared basket ${basket.sharedBasketId.id} members must share an identical subscription",
                )
            }
        }
        return null
    }

    /**
     * Allocates a real id for every shared basket created with a [ClientMutation.TMP_ID_PREFIX] id.
     * The allocated ids are NOT echoed via [MutationOutcome.serverEntityId] (reserved for the
     * aggregate root); the client recovers them by diffing the authoritative contract payload on
     * the next sync (BasketExchange nested-id convention).
     */
    private fun allocateSharedBasketIds(sharedBaskets: List<SharedBasket>): List<SharedBasket> =
        sharedBaskets.map { basket ->
            if (basket.sharedBasketId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
                basket.copy(sharedBasketId = generateId<SharedBasket>())
            } else {
                basket
            }
        }

    private companion object {
        private val ALLOWED_ROLES = setOf(Role.OWNER, Role.ADMIN, Role.COORDINATOR)
    }

    private fun buildUpsertChange(
        organizationId: String,
        contract: Contract,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Contract,
            entityId = contract.contractId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = ContractPayload(contract),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        organizationId: String,
        entityId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Contract,
            entityId = entityId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )
}

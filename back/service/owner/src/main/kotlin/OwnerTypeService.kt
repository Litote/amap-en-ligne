@file:OptIn(ExperimentalTime::class)

package owner

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import core.OwnerRoleProvisioningPort
import core.RoleService
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OwnerPayload
import persistence.changes.SyncScope
import persistence.dao.MemberSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.EntityType
import persistence.model.Owner
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

/**
 * Handles [EntityType.Owner] upserts and snapshots for OWNER-role callers.
 *
 * Supported mutation paths:
 *  - **Promote to OWNER** — upsert with a `tmp_*` owner id: validates OWNER_EXCLUSIVE and LAST_ADMIN,
 *    then atomically strips all Member rows for the target user and inserts the Owner row.
 *  - **Suspend** — upsert with `accountStatus = SUSPENDED`: delegates to [OwnerService.suspend]
 *    (rejects last-Owner and self-action).
 *  - **Reactivate** — upsert with `accountStatus = ACTIVE` on an existing owner: delegates to
 *    [OwnerService.reactivate] (rejects self-action).
 *  - **Delete** — delegates to [OwnerService.delete] (rejects last-Owner and self-action). The
 *    front uses the regular `Delete` sync mutation.
 *
 * Only callers with [Role.OWNER] may access this service.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class OwnerTypeService(
    private val ownerDAO: OwnerSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val roleService: RoleService,
    private val ownerService: OwnerService,
    private val roleProvisioningPort: OwnerRoleProvisioningPort?,
) : EntityTypeService<OwnerPayload>(EntityType.Owner) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: OwnerPayload,
    ): MutationOutcome {
        if (auth.roles.none { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only OWNER callers may mutate owners")
        }
        val incomingOwner = payload.owner
        // After sub/id unification: the front sends ownerId = <sub_of_target> for both
        // promotion (user does not yet have an Owner row) and status change (user already
        // has an Owner row). We distinguish by checking whether an Owner row already exists.
        val existingOwner = ownerDAO.findById(incomingOwner.ownerId)
        return if (existingOwner == null) {
            applyPromotion(auth, mutation, incomingOwner)
        } else {
            applyStatusChange(auth, mutation, incomingOwner)
        }
    }

    /**
     * Promote an existing member to OWNER.
     *
     * The incoming [Owner]'s [Owner.ownerId] contains the target member's id (= their auth
     * subject, since `memberId == sub` by convention). The OWNER row will be created with
     * this same id so that `ownerId == sub` holds for all owners too.
     */
    private suspend fun applyPromotion(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        incoming: Owner,
    ): MutationOutcome {
        val targetSub = incoming.ownerId.id

        // 1. Load all existing members for this sub to check OWNER_EXCLUSIVE and LAST_ADMIN.
        val existingMembers = memberSyncDAO.getMembersBySub(targetSub)

        // 2. Validate OWNER_EXCLUSIVE (already an owner).
        val ownerExclusiveError = roleService.validateGrantOwner(targetSub)
        if (ownerExclusiveError != null) {
            return rejected(mutation, ownerExclusiveError, "target user cannot be promoted to OWNER")
        }

        // 2b. Validate PRODUCER_EXCLUSIVE (already a producer — cannot also be OWNER)
        val producerExclusiveError = roleService.validateProducerExclusive(incoming.email)
        if (producerExclusiveError != null) {
            return rejected(mutation, producerExclusiveError, "a producer cannot be promoted to OWNER")
        }

        // 3. Validate LAST_ADMIN: for each org the user is admin of, ensure another admin remains
        for (member in existingMembers) {
            if (member.roles.contains(Role.ADMIN)) {
                val orgMembers = memberSyncDAO.getByOrganizationId(member.organizationId)
                val lastAdminError = roleService.validateLastAdmin(member.memberId.id, emptySet(), orgMembers)
                if (lastAdminError != null) {
                    return rejected(
                        mutation,
                        lastAdminError,
                        "promotion would leave organization ${member.organizationId.id} without an admin",
                    )
                }
            }
        }

        // 4. Build the real Owner. ownerId == sub (incoming.ownerId.id == targetSub).
        val now = Clock.System.now()
        val owner =
            incoming.copy(
                registeredAt = now,
                updatedAt = now,
                accountStatus = AccountStatus.ACTIVE,
            )
        val ownerChange = buildOwnerChange(owner, ChangeOp.UPSERT)

        // 5. Build member tombstone changes
        val memberChanges =
            existingMembers.flatMap { member ->
                listOf(
                    Change(
                        cursor = Cursor.next(),
                        entityType = EntityType.Member,
                        entityId = member.memberId.id,
                        scopeKey = SyncScope.Organization(member.organizationId.id).key,
                        op = ChangeOp.DELETE,
                        payload = null,
                        producedAt = System.currentTimeMillis(),
                    ),
                    Change(
                        cursor = Cursor.next(),
                        entityType = EntityType.Member,
                        entityId = member.memberId.id,
                        scopeKey = SyncScope.InstanceOwner.key,
                        op = ChangeOp.DELETE,
                        payload = null,
                        producedAt = System.currentTimeMillis(),
                    ),
                )
            }

        // 6. Atomically promote
        ownerDAO.promoteToOwner(
            owner = owner,
            ownerChange = ownerChange,
            membersToRevoke = existingMembers,
            memberChanges = memberChanges,
        )

        // 7. Sync the OWNER role to the auth provider (best-effort, non-blocking)
        try {
            roleProvisioningPort?.updateOwnerRole(targetSub)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to sync OWNER role to auth provider for $targetSub" }
        }

        logger.info { "User sub=$targetSub promoted to OWNER (${owner.ownerId.id}), stripped ${existingMembers.size} member row(s)" }
        return applied(mutation, owner.ownerId.id)
    }

    /**
     * Apply a status change (suspend or reactivate) to an existing owner, or update the
     * caller's own profile when the actor and the target owner are the same.
     */
    private suspend fun applyStatusChange(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        incoming: Owner,
    ): MutationOutcome {
        // Owner updating their own profile (firstName, lastName, email, phone).
        if (auth.memberId == incoming.ownerId.id) {
            val outcome =
                ownerService.updateProfile(
                    auth.memberId,
                    OwnerProfileUpdate(
                        firstName = incoming.firstName,
                        lastName = incoming.lastName,
                        email = incoming.email,
                        phone = incoming.phone,
                    ),
                )
            return outcome.toMutationOutcome(mutation, incoming.ownerId.id)
        }
        // Cross-owner lifecycle: suspend or reactivate another owner.
        val outcome =
            when (incoming.accountStatus) {
                AccountStatus.SUSPENDED -> ownerService.suspend(auth.memberId, incoming.ownerId.id)
                AccountStatus.ACTIVE -> ownerService.reactivate(auth.memberId, incoming.ownerId.id)
            }
        return outcome.toMutationOutcome(mutation, incoming.ownerId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        if (auth.roles.none { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only OWNER callers may delete owners")
        }
        return ownerService.delete(auth.memberId, op.entityId).toMutationOutcome(mutation, op.entityId)
    }

    private fun OwnerLifecycleOutcome.toMutationOutcome(
        mutation: ClientMutation,
        entityId: String,
    ): MutationOutcome =
        when (this) {
            is OwnerLifecycleOutcome.Success -> applied(mutation, entityId)
            is OwnerLifecycleOutcome.Rejected -> rejected(mutation, code, message)
            is OwnerLifecycleOutcome.NotFound -> rejected(mutation, MutationErrorCode.NOT_FOUND, "owner not found: $entityId")
        }

    /**
     * Returns all owners. Only accessible to OWNER callers.
     * ADMIN / COORDINATOR / VOLUNTEER callers receive an empty list via the routing layer
     * (this service is only in [ownerEntityTypes], which is only served to OWNER/ADMIN paths).
     * An additional role check here ensures we never leak owner rows to non-OWNER callers.
     */
    override suspend fun snapshot(auth: AuthenticatedInfo): List<OwnerPayload> {
        if (auth.roles.none { it == Role.OWNER }) return emptyList()
        return ownerDAO.listAll().map { OwnerPayload(it) }
    }

    private fun buildOwnerChange(
        owner: Owner,
        op: ChangeOp,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Owner,
            entityId = owner.ownerId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = op,
            payload = if (op == ChangeOp.UPSERT) OwnerPayload(owner) else null,
            producedAt = System.currentTimeMillis(),
        )

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

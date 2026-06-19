package core

import authentication.Role
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.MutationErrorCode
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.Member

/**
 * Pure validation service for role-related invariants.
 * Stateless — all checks are delegated to the DAO layer.
 */
@Single(createdAtStart = true)
class RoleService(
    private val ownerDAO: OwnerSyncDAO,
    private val userProvisioningPort: UserProvisioningPort,
) {
    /**
     * Validates that granting [Role.OWNER] to the user identified by [sub] is permitted.
     *
     * Returns [MutationErrorCode.OWNER_EXCLUSIVE] if the target user is already an OWNER.
     *
     * Note: existing [Member] rows are NOT a blocking condition — they are atomically stripped
     * by [OwnerTypeService.applyPromotion] as part of the promotion transaction.
     * LAST_ADMIN validation for those rows is performed separately in the caller.
     */
    suspend fun validateGrantOwner(sub: String): MutationErrorCode? {
        val alreadyOwner = ownerDAO.existsBySub(sub)
        return if (alreadyOwner) MutationErrorCode.OWNER_EXCLUSIVE else null
    }

    /**
     * Validates that removing [Role.ADMIN] from [targetMemberId] in [existingMembers]
     * still leaves at least one admin.
     *
     * Returns [MutationErrorCode.LAST_ADMIN] if no other admin would remain.
     */
    fun validateLastAdmin(
        targetMemberId: String,
        newRoles: Set<Role>,
        existingMembers: List<Member>,
    ): MutationErrorCode? {
        val targetHadAdmin = existingMembers.find { it.memberId.id == targetMemberId }?.roles?.contains(Role.ADMIN) == true
        val targetStillAdmin = newRoles.contains(Role.ADMIN)
        if (!targetHadAdmin || targetStillAdmin) return null

        val adminCount = existingMembers.count { it.roles.contains(Role.ADMIN) }
        return if (adminCount <= 1) MutationErrorCode.LAST_ADMIN else null
    }

    /**
     * Validates that revoking (suspending) an owner leaves at least one active owner.
     *
     * Returns [MutationErrorCode.LAST_OWNER] if [targetOwnerId] is the only active owner.
     */
    suspend fun validateLastOwner(targetOwnerId: String): MutationErrorCode? {
        val activeOwners = ownerDAO.listAll().filter { it.accountStatus == AccountStatus.ACTIVE }
        return if (activeOwners.size <= 1 && activeOwners.any { it.ownerId.id == targetOwnerId }) {
            MutationErrorCode.LAST_OWNER
        } else {
            null
        }
    }

    /**
     * Validates that granting an AMAP role (Member) to the user with [sub] / [email] does not
     * violate role exclusivity.
     *
     * Returns [MutationErrorCode.MIXED_ROLES] if the user is already OWNER (by [sub], when
     * non-null) or already PRODUCER (by [email], resolved from the auth provider).
     * Both [sub] and [email] are optional: when [sub] is null (new member, sub not known yet)
     * only the producer side is checked; when [email] is null only the owner side is checked.
     */
    suspend fun validateMixedRoles(
        sub: String? = null,
        email: String? = null,
    ): MutationErrorCode? {
        if (sub != null && ownerDAO.existsBySub(sub)) return MutationErrorCode.MIXED_ROLES
        if (email != null && isProducer(email)) return MutationErrorCode.MIXED_ROLES
        return null
    }

    /**
     * Validates that granting a non-producer role (e.g. promoting to OWNER) to the user with
     * [email] does not collide with an existing PRODUCER identity.
     *
     * Returns [MutationErrorCode.PRODUCER_EXCLUSIVE] if [email] already belongs to a producer in
     * the auth provider, otherwise null.
     */
    suspend fun validateProducerExclusive(email: String): MutationErrorCode? =
        if (isProducer(email)) MutationErrorCode.PRODUCER_EXCLUSIVE else null

    /**
     * Resolves whether [email] already belongs to a producer in the auth provider.
     *
     * Fails open: if the auth-provider lookup errors, returns false so the exclusivity guard
     * never blocks a legitimate mutation because the auth provider is momentarily unreachable.
     */
    private suspend fun isProducer(email: String): Boolean =
        runCatching { userProvisioningPort.findProducerAccountIdByEmail(email) != null }
            .getOrElse { error ->
                logger.warn(error) { "findProducerAccountIdByEmail failed during exclusivity check; allowing" }
                false
            }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

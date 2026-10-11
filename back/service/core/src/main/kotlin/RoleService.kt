package core

import authentication.Role
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.MutationErrorCode
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitationStatus

/**
 * Pure validation service for role-related invariants.
 * Stateless — all checks are delegated to the DAO layer.
 */
@Single(createdAtStart = true)
class RoleService(
    private val ownerDAO: OwnerSyncDAO,
    private val userProvisioningPort: UserProvisioningPort,
    private val memberInvitationSyncDAO: MemberInvitationSyncDAO,
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
     * Validates that removing [Role.ADMIN] from [targetMemberId] in [existingMembers] (the
     * members of one organization) still leaves at least one admin who can log in.
     *
     * Only effective admins count: ADMIN role, ACTIVE account, and activated — no
     * PENDING_ACTIVATION invitation for their email in the organization (an imported member
     * waits on one until activation). A deleted account (suspended, roles kept) or an
     * imported admin who never activated is not an admin anyone can act as, so removing
     * such a target is always allowed.
     *
     * Returns [MutationErrorCode.LAST_ADMIN] if no other effective admin would remain.
     */
    suspend fun validateLastAdmin(
        targetMemberId: String,
        newRoles: Set<Role>,
        existingMembers: List<Member>,
    ): MutationErrorCode? {
        val target = existingMembers.find { it.memberId.id == targetMemberId } ?: return null
        if (Role.ADMIN !in target.roles || Role.ADMIN in newRoles) return null

        val pendingEmails =
            memberInvitationSyncDAO
                .listByOrganizationId(target.organizationId)
                .filter { it.status == MemberInvitationStatus.PENDING_ACTIVATION }
                .map { it.email.lowercase() }
                .toSet()
        val effectiveAdmins = existingMembers.filter { it.isEffectiveAdmin(pendingEmails) }
        if (effectiveAdmins.none { it.memberId == target.memberId }) return null
        return if (effectiveAdmins.none { it.memberId != target.memberId }) MutationErrorCode.LAST_ADMIN else null
    }

    private fun Member.isEffectiveAdmin(pendingInvitationEmails: Set<String>): Boolean =
        Role.ADMIN in roles &&
            accountStatus == MemberAccountStatus.ACTIVE &&
            email?.lowercase() !in pendingInvitationEmails

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

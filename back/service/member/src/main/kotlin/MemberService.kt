package member

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import core.MemberRoleProvisioningPort
import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MemberPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class MemberService(
    val memberSyncDAO: MemberSyncDAO,
    private val roleService: RoleService,
    private val roleProvisioningPort: MemberRoleProvisioningPort?,
    private val userProvisioningPort: UserProvisioningPort,
    private val accountLifecycleEmailPort: AccountLifecycleEmailPort,
    private val accountDeletionLogDAO: AccountDeletionLogDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
) : EntityTypeService<MemberPayload>(EntityType.Member) {
    private val contractSubscriptionGuard = MemberContractSubscriptionGuard(contractSyncDAO, organizationSyncDAO)
    private val lifecycleSideEffects =
        MemberLifecycleSideEffects(userProvisioningPort, accountLifecycleEmailPort, accountDeletionLogDAO)

    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberPayload,
    ): MutationOutcome {
        val isOwnerCaller = auth.roles.any { it == Role.OWNER }

        val organizationId: String =
            if (isOwnerCaller) {
                payload.member.organizationId.id
            } else {
                auth.organizationId
                    ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
            }

        if (!isOwnerCaller && payload.member.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }

        val existingMembers = memberSyncDAO.getByOrganizationId(organizationId.toId())
        val existingMember = existingMembers.find { it.memberId.id == payload.member.memberId.id }
        val isTmpId =
            payload.member.memberId.id
                .startsWith(ClientMutation.TMP_ID_PREFIX)

        validateUpsertAuthorization(auth, mutation, payload, isOwnerCaller, isTmpId)
            ?.let { return it }

        val statusTransition = detectStatusTransition(existingMember, payload.member)
        if (statusTransition != null && isOwnerCaller && existingMember != null) {
            // Since memberId == sub for account-backed members, use memberId.id as the sub.
            return applyOwnerStatusTransition(
                auth = auth,
                mutation = mutation,
                targetSub = existingMember.memberId.id,
                targetStatus = statusTransition,
                resolvedMemberId = payload.member.memberId.id,
            )
        }

        validateUpsertContractAndRoleGuards(auth, mutation, payload, organizationId, existingMembers, existingMember)
            ?.let { return it }

        return persistMemberUpsert(mutation, payload, organizationId, existingMember, isTmpId)
    }

    /** Authorization guards independent of contract/role state: MIXED_ROLES on create, self-edit. */
    private suspend fun validateUpsertAuthorization(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberPayload,
        isOwnerCaller: Boolean,
        isTmpId: Boolean,
    ): MutationOutcome? {
        if (isOwnerCaller && isTmpId) {
            // For new member creation, the memberId is a tmp_* placeholder; use the email
            // to check MIXED_ROLES instead (sub is not yet known at create time).
            val mixedRolesError = validateMixedRoles(null, payload.member.email, mutation)
            if (mixedRolesError != null) return mixedRolesError
        }
        val isAdminCaller = auth.roles.any { it == Role.ADMIN }
        if (!isOwnerCaller && !isAdminCaller && payload.member.memberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "non-privileged callers may only edit their own member profile")
        }
        return null
    }

    /** Contract-lifecycle and role-change guards applied to a normal (non-lifecycle) upsert. */
    private suspend fun validateUpsertContractAndRoleGuards(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberPayload,
        organizationId: String,
        existingMembers: List<Member>,
        existingMember: Member?,
    ): MutationOutcome? {
        val roleChangeError = validateRoleChange(auth, mutation, payload, existingMembers, existingMember)
        if (roleChangeError != null) return roleChangeError

        val endedIds = contractSubscriptionGuard.endedContractIds(organizationId, existingMember, payload.member)
        if (endedIds.isNotEmpty()) {
            return rejected(
                mutation,
                MutationErrorCode.CONTRACT_ENDED,
                "cannot add member subscription to ended contract(s): ${endedIds.joinToString(",") { it.id }}",
            )
        }

        val isPrivilegedCaller = auth.roles.any { it == Role.OWNER || it == Role.ADMIN || it == Role.COORDINATOR }
        if (!isPrivilegedCaller) {
            val inPreparationIds =
                contractSubscriptionGuard.inPreparationContractIds(organizationId, existingMember, payload.member)
            if (inPreparationIds.isNotEmpty()) {
                return rejected(
                    mutation,
                    MutationErrorCode.FORBIDDEN,
                    "contract not open for subscription: ${inPreparationIds.joinToString(",") { it.id }}",
                )
            }
        }
        return null
    }

    private suspend fun persistMemberUpsert(
        mutation: ClientMutation,
        payload: MemberPayload,
        organizationId: String,
        existingMember: Member?,
        isTmpId: Boolean,
    ): MutationOutcome {
        val resolvedMember =
            if (isTmpId) {
                payload.member.copy(memberId = generateId())
            } else {
                payload.member
            }
        memberSyncDAO.put(resolvedMember, buildUpsertChanges(organizationId, resolvedMember))
        val rolesChanged = existingMember == null || existingMember.roles != resolvedMember.roles
        if (rolesChanged) {
            roleProvisioningPort?.updateRoles(
                memberId = resolvedMember.memberId.id,
                oldRoles = existingMember?.roles ?: emptySet(),
                newRoles = resolvedMember.roles,
            )
        }
        return applied(mutation, resolvedMember.memberId.id)
    }

    private fun detectStatusTransition(
        existing: Member?,
        updated: Member,
    ): MemberAccountStatus? {
        if (existing == null) return null
        val payloadStatus = updated.accountStatus
        val previousStatus = existing.accountStatus
        return if (payloadStatus != previousStatus) payloadStatus else null
    }

    private suspend fun applyOwnerStatusTransition(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        targetSub: String,
        targetStatus: MemberAccountStatus,
        resolvedMemberId: String,
    ): MutationOutcome {
        if (targetStatus != MemberAccountStatus.ACTIVE && targetStatus != MemberAccountStatus.SUSPENDED) {
            error("applyOwnerStatusTransition called with non-lifecycle status $targetStatus")
        }
        if (auth.memberId == targetSub) {
            return rejected(
                mutation,
                MutationErrorCode.SELF_ACTION_FORBIDDEN,
                "an OWNER cannot suspend or reactivate their own account via the AMAP path",
            )
        }

        val members = memberSyncDAO.getMembersBySub(targetSub)
        if (members.isEmpty()) return rejected(mutation, MutationErrorCode.NOT_FOUND, MEMBER_NOT_FOUND)
        if (targetStatus == MemberAccountStatus.SUSPENDED) {
            val lastAdminFor = checkLastAdminOrgs(members)
            if (lastAdminFor.isNotEmpty()) {
                return rejected(
                    mutation,
                    MutationErrorCode.LAST_ADMIN,
                    "cannot suspend the last admin of org(s): ${lastAdminFor.joinToString(",")}",
                )
            }
        }

        val updatedMembers =
            members.map {
                it.copy(
                    accountStatus = targetStatus,
                )
            }
        memberSyncDAO.setAccountStatusBySub(targetSub, targetStatus, buildLifecycleChanges(updatedMembers))

        lifecycleSideEffects.onStatusChanged(updatedMembers, auth, targetSub, targetStatus)
        return applied(mutation, resolvedMemberId)
    }

    private suspend fun validateMixedRoles(
        sub: String?,
        email: String?,
        mutation: ClientMutation,
    ): MutationOutcome? {
        val error = roleService.validateMixedRoles(sub, email)
        return if (error != null) {
            rejected(mutation, error, "user already holds an exclusive role — cannot grant AMAP roles")
        } else {
            null
        }
    }

    private fun validateRoleChange(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberPayload,
        existingMembers: List<Member>,
        existingMember: Member?,
    ): MutationOutcome? {
        val rolesChanged = existingMember == null || existingMember.roles != payload.member.roles
        if (!rolesChanged) return null

        if (auth.roles.none { it == Role.ADMIN || it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only admins can change roles")
        }

        val lastAdminError =
            roleService.validateLastAdmin(
                targetMemberId = payload.member.memberId.id,
                newRoles = payload.member.roles,
                existingMembers = existingMembers,
            )
        if (lastAdminError != null) {
            return rejected(mutation, lastAdminError, "cannot remove the last admin")
        }

        return null
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val isOwnerCaller = auth.roles.any { it == Role.OWNER }

        if (isOwnerCaller) {
            val member =
                findMemberById(op.entityId)
                    ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, MEMBER_NOT_FOUND)
            // Since memberId == sub for account-backed members, use memberId.id as the sub.
            // A member with a real (non-tmp) id is always account-backed at delete time.
            if (!op.entityId.startsWith(ClientMutation.TMP_ID_PREFIX)) {
                return applyOwnerDelete(auth, mutation, member.memberId.id, op.entityId)
            }
            return hardDelete(mutation, op, member.organizationId.id)
        }

        val organizationId: String =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        return hardDelete(mutation, op, organizationId)
    }

    private suspend fun hardDelete(
        mutation: ClientMutation,
        op: Delete,
        organizationId: String,
    ): MutationOutcome {
        val existingMembers = memberSyncDAO.getByOrganizationId(organizationId.toId())
        val lastAdminError = roleService.validateLastAdmin(op.entityId, emptySet(), existingMembers)
        if (lastAdminError != null) {
            return rejected(mutation, lastAdminError, "cannot remove the last admin")
        }
        memberSyncDAO.delete(
            op.entityId.toId(),
            organizationId.toId(),
            buildDeleteChanges(organizationId, op.entityId),
        )
        return applied(mutation, op.entityId)
    }

    private suspend fun applyOwnerDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        targetSub: String,
        memberId: String,
    ): MutationOutcome {
        if (auth.memberId == targetSub) {
            return rejected(
                mutation,
                MutationErrorCode.SELF_ACTION_FORBIDDEN,
                "an OWNER cannot delete their own account via the AMAP path",
            )
        }

        val members = memberSyncDAO.getMembersBySub(targetSub)
        if (members.isEmpty()) return rejected(mutation, MutationErrorCode.NOT_FOUND, MEMBER_NOT_FOUND)
        val lastAdminFor = checkLastAdminOrgs(members)
        if (lastAdminFor.isNotEmpty()) {
            return rejected(
                mutation,
                MutationErrorCode.LAST_ADMIN,
                "cannot delete the last admin of org(s): ${lastAdminFor.joinToString(",")}",
            )
        }

        val anonymisedMembers =
            members.map {
                it.copy(
                    firstName = null,
                    lastName = null,
                    email = null,
                    phone = null,
                    accountStatus = MemberAccountStatus.SUSPENDED,
                )
            }
        memberSyncDAO.anonymiseBySub(targetSub, buildLifecycleChanges(anonymisedMembers))

        lifecycleSideEffects.onDeleted(members, auth, targetSub)
        return applied(mutation, memberId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<MemberPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return memberSyncDAO.getByOrganizationId(organizationId.toId()).map { MemberPayload(it) }
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<MemberPayload> =
        when (scope) {
            is SyncScope.Organization -> memberSyncDAO.getByOrganizationId(scope.organizationId.toId()).map { MemberPayload(it) }
            SyncScope.InstanceOwner -> memberSyncDAO.listAll().map { MemberPayload(it) }
            is SyncScope.ProducerAccount -> emptyList()
            is SyncScope.Member -> emptyList()
            is SyncScope.Owner -> emptyList()
        }

    private suspend fun checkLastAdminOrgs(members: List<Member>): List<String> {
        val candidateOrganizations =
            members
                .filter { it.roles.contains(Role.ADMIN) }
                .map { it.organizationId.id }
                .distinct()
        val targetMemberIds = members.map { it.memberId }.toSet()
        return candidateOrganizations.filter { organizationId ->
            memberSyncDAO
                .getByOrganizationId(organizationId.toId())
                .none { row -> row.roles.contains(Role.ADMIN) && row.memberId !in targetMemberIds }
        }
    }

    private suspend fun findMemberById(memberId: String): Member? = memberSyncDAO.listAll().find { it.memberId.id == memberId }

    private companion object {
        private const val MEMBER_NOT_FOUND = "member not found"
    }
}

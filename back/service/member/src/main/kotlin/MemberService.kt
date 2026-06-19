package member

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import core.MemberRoleProvisioningPort
import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.OwnersBroadcastEvent
import id.Id
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MemberPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.AccountDeletionLog
import persistence.model.ContractStatus
import persistence.model.DeletedAccountRole
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import java.security.MessageDigest
import kotlin.time.Clock

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
        val isTmpId =
            payload.member.memberId.id
                .startsWith(ClientMutation.TMP_ID_PREFIX)

        if (isOwnerCaller && isTmpId) {
            // For new member creation, the memberId is a tmp_* placeholder; use the email
            // to check MIXED_ROLES instead (sub is not yet known at create time).
            val mixedRolesError = validateMixedRoles(null, payload.member.email, mutation)
            if (mixedRolesError != null) return mixedRolesError
        }

        val existingMember = existingMembers.find { it.memberId.id == payload.member.memberId.id }

        val isAdminCaller = auth.roles.any { it == Role.ADMIN }
        if (!isOwnerCaller && !isAdminCaller && payload.member.memberId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "non-privileged callers may only edit their own member profile")
        }

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

        val roleChangeError = validateRoleChange(auth, mutation, payload, existingMembers, existingMember)
        if (roleChangeError != null) return roleChangeError

        val contractEndedError = checkNoNewEndedContractSubscriptions(organizationId, existingMember, payload.member, mutation)
        if (contractEndedError != null) return contractEndedError

        val isCoordinatorCaller = auth.roles.any { it == Role.COORDINATOR }
        val isPrivilegedCaller = isOwnerCaller || isAdminCaller || isCoordinatorCaller
        if (!isPrivilegedCaller) {
            val inPreparationError =
                checkNoNewInPreparationContractSubscriptions(organizationId, existingMember, payload.member, mutation)
            if (inPreparationError != null) return inPreparationError
        }

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
        val payloadStatus = updated.accountStatus ?: return null
        if (payloadStatus != MemberAccountStatus.ACTIVE && payloadStatus != MemberAccountStatus.SUSPENDED) {
            return null
        }
        val previousStatus =
            existing.accountStatus
                ?: if (existing.activeStatus) MemberAccountStatus.ACTIVE else MemberAccountStatus.SUSPENDED
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
        if (members.isEmpty()) return rejected(mutation, MutationErrorCode.NOT_FOUND, "member not found")
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

        val activeStatus = targetStatus == MemberAccountStatus.ACTIVE
        val updatedMembers =
            members.map {
                it.copy(
                    activeStatus = activeStatus,
                    accountStatus = targetStatus,
                )
            }
        memberSyncDAO.setActiveStatusBySub(targetSub, activeStatus, buildLifecycleChanges(updatedMembers))

        runCatching {
            if (activeStatus) {
                userProvisioningPort.unbanUser(targetSub)
            } else {
                userProvisioningPort.banUser(targetSub)
            }
        }.onFailure { error ->
            logger.error(error) { "Auth provider ${if (activeStatus) "unban" else "ban"} failed for $targetSub" }
        }
        notifyMemberLifecycle(
            members = updatedMembers,
            auth = auth,
            targetSub = targetSub,
            ownersEvent =
                if (activeStatus) {
                    OwnersBroadcastEvent.ACCOUNT_REACTIVATED
                } else {
                    OwnersBroadcastEvent.ACCOUNT_SUSPENDED
                },
            notifyTarget = { target ->
                if (activeStatus) {
                    accountLifecycleEmailPort.notifyAccountReactivated(target)
                } else {
                    accountLifecycleEmailPort.notifyAccountSuspended(target)
                }
            },
        )
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
                    ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "member not found")
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
        if (members.isEmpty()) return rejected(mutation, MutationErrorCode.NOT_FOUND, "member not found")
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
                    activeStatus = false,
                    firstName = null,
                    lastName = null,
                    email = null,
                    phone = null,
                    accountStatus = MemberAccountStatus.SUSPENDED,
                )
            }
        memberSyncDAO.anonymiseBySub(targetSub, buildLifecycleChanges(anonymisedMembers))

        runCatching { userProvisioningPort.deleteUser(targetSub) }
            .onFailure { error -> logger.error(error) { "deleteUser($targetSub) failed in auth provider" } }

        val deletedSubHash = sha256(targetSub)
        members.forEach {
            runCatching {
                accountDeletionLogDAO.append(
                    AccountDeletionLog(
                        id = generateId(),
                        deletedSubHash = deletedSubHash,
                        deletedRole = DeletedAccountRole.AMAP_MEMBER,
                        deletedAt = Clock.System.now(),
                        actorOwnerId = Id(auth.memberId),
                    ),
                )
            }.onFailure { error ->
                logger.error(error) { "audit log append failed for $targetSub" }
            }
        }
        notifyMemberLifecycle(
            members = members,
            auth = auth,
            targetSub = targetSub,
            ownersEvent = OwnersBroadcastEvent.ACCOUNT_DELETED,
            notifyTarget = { target -> accountLifecycleEmailPort.notifyAccountDeleted(target) },
        )
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

    private suspend fun notifyMemberLifecycle(
        members: List<Member>,
        auth: AuthenticatedInfo,
        targetSub: String,
        ownersEvent: OwnersBroadcastEvent,
        notifyTarget: suspend (AccountLifecycleTarget) -> Unit,
    ) {
        val firstMember = members.firstOrNull() ?: return
        runCatching { notifyTarget(firstMember.toLifecycleTarget(targetSub)) }
            .onFailure { error -> logger.error(error) { "Member lifecycle email failed for $targetSub" } }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event = ownersEvent,
                actorOwnerEmail = auth.email,
                impactedRole = AccountLifecycleRole.AMAP_MEMBER,
            )
        }.onFailure { error ->
            logger.error(error) { "Members lifecycle Owners broadcast failed" }
        }
    }

    private fun Member.toLifecycleTarget(targetSub: String): AccountLifecycleTarget =
        AccountLifecycleTarget(
            sub = targetSub,
            email = email ?: "(member email unavailable)",
            firstName = firstName.orEmpty(),
            lastName = lastName.orEmpty(),
            role = AccountLifecycleRole.AMAP_MEMBER,
        )

    private suspend fun findMemberById(memberId: String): Member? = memberSyncDAO.listAll().find { it.memberId.id == memberId }

    private fun buildUpsertChanges(
        organizationId: String,
        member: Member,
    ): List<Change> =
        listOf(
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Member,
                entityId = member.memberId.id,
                scopeKey = SyncScope.Organization(organizationId).key,
                op = ChangeOp.UPSERT,
                payload = MemberPayload(member),
                producedAt = System.currentTimeMillis(),
            ),
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Member,
                entityId = member.memberId.id,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.UPSERT,
                payload = MemberPayload(member),
                producedAt = System.currentTimeMillis(),
            ),
        )

    private fun buildLifecycleChanges(members: List<Member>): List<Change> =
        buildList {
            members.forEach { member ->
                addAll(buildUpsertChanges(member.organizationId.id, member))
            }
        }

    private fun buildDeleteChanges(
        organizationId: String,
        entityId: String,
    ): List<Change> =
        listOf(
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Member,
                entityId = entityId,
                scopeKey = SyncScope.Organization(organizationId).key,
                op = ChangeOp.DELETE,
                payload = null,
                producedAt = System.currentTimeMillis(),
            ),
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Member,
                entityId = entityId,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.DELETE,
                payload = null,
                producedAt = System.currentTimeMillis(),
            ),
        )

    /**
     * Rejects the upsert if any newly-added [Member.contracts] entry references a contract whose
     * [persistence.model.Contract.maxDeliveryDate] is in the past.
     *
     * Only new contract ids (present in [updated] but absent in [existing]) are checked.
     * A null [existing] means a new member row — all its contract ids are considered new.
     * Unknown contract ids (not returned by the DAO) pass through without error.
     */
    private suspend fun checkNoNewEndedContractSubscriptions(
        organizationId: String,
        existing: Member?,
        updated: Member,
        mutation: ClientMutation,
    ): MutationOutcome? {
        val existingContractIds = existing?.contracts?.map { it.contractId }?.toSet() ?: emptySet()
        val newContractIds = updated.contracts.map { it.contractId }.toSet() - existingContractIds
        if (newContractIds.isEmpty()) return null

        val today = resolveToday(organizationId)
        val orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
        val endedIds =
            newContractIds.filter { contractId ->
                orgContracts.find { it.contractId == contractId }?.isEffectivelyEnded(today) == true
            }
        if (endedIds.isEmpty()) return null
        return rejected(
            mutation,
            MutationErrorCode.CONTRACT_ENDED,
            "cannot add member subscription to ended contract(s): ${endedIds.joinToString(",") { it.id }}",
        )
    }

    /**
     * Rejects a non-privileged self-subscription attempt when any newly added contract entry
     * points to a contract that is still [ContractStatus.IN_PREPARATION].
     *
     * Privileged callers (OWNER / ADMIN / COORDINATOR) may pre-subscribe members to contracts
     * that are not yet open. Unknown contract ids pass through without error.
     */
    private suspend fun checkNoNewInPreparationContractSubscriptions(
        organizationId: String,
        existing: Member?,
        updated: Member,
        mutation: ClientMutation,
    ): MutationOutcome? {
        val existingContractIds = existing?.contracts?.map { it.contractId }?.toSet() ?: emptySet()
        val newContractIds = updated.contracts.map { it.contractId }.toSet() - existingContractIds
        if (newContractIds.isEmpty()) return null

        val orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
        val inPreparationIds =
            newContractIds.filter { contractId ->
                orgContracts.find { it.contractId == contractId }?.status == ContractStatus.IN_PREPARATION
            }
        if (inPreparationIds.isEmpty()) return null
        return rejected(
            mutation,
            MutationErrorCode.FORBIDDEN,
            "contract not open for subscription: ${inPreparationIds.joinToString(",") { it.id }}",
        )
    }

    private suspend fun resolveToday(organizationId: String): kotlinx.datetime.LocalDate {
        val timezone = organizationSyncDAO.getById(organizationId.toId())?.timezone ?: TimeZone.UTC
        return Clock.System.todayIn(timezone)
    }

    private companion object {
        private val logger = KotlinLogging.logger {}

        private fun sha256(input: String): String =
            MessageDigest
                .getInstance("SHA-256")
                .digest(input.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it) }
    }
}

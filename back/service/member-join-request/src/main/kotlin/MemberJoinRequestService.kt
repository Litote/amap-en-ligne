@file:OptIn(ExperimentalTime::class)

package memberjoinrequest

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.MemberInvitationEmailPort
import email.MemberJoinRequestRejectionEmailPort
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MemberInvitationPayload
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class MemberJoinRequestService(
    private val memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO,
    private val memberJoinRequestDAO: MemberJoinRequestDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val memberInvitationDAO: MemberInvitationSyncDAO,
    private val activationTokenDAO: ActivationTokenDAO,
    private val memberInvitationEmailPort: MemberInvitationEmailPort,
    private val rejectionEmailPort: MemberJoinRequestRejectionEmailPort,
    private val organizationSyncDAO: OrganizationSyncDAO,
) : EntityTypeService<MemberJoinRequestPayload>(EntityType.MemberJoinRequest) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberJoinRequestPayload,
    ): MutationOutcome {
        val requestedOrganizationId =
            resolveOrganizationId(auth, payload.memberJoinRequest.organizationId.id)
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        val incoming = payload.memberJoinRequest
        val existing =
            memberJoinRequestDAO.findById(incoming.requestId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "member join request not found")
        if (existing.organizationId.id != requestedOrganizationId || incoming.organizationId != existing.organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }
        if (existing.status != MemberJoinRequestStatus.PENDING) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "request is already processed")
        }
        val nextStatus = incoming.status
        if (nextStatus != MemberJoinRequestStatus.APPROVED && nextStatus != MemberJoinRequestStatus.REJECTED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invalid state transition")
        }
        return when (nextStatus) {
            MemberJoinRequestStatus.APPROVED -> approve(existing, incoming, mutation)
            MemberJoinRequestStatus.REJECTED -> reject(existing, incoming, mutation)
            MemberJoinRequestStatus.PENDING -> error("validated above")
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "delete not allowed for member join requests")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<MemberJoinRequestPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        if (auth.roles.none { it == Role.ADMIN || it == Role.OWNER }) return emptyList()
        return memberJoinRequestSyncDAO.listByOrganizationId(organizationId.toId()).map(::MemberJoinRequestPayload)
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<MemberJoinRequestPayload> =
        when (scope) {
            is SyncScope.Organization -> {
                if (resolveOrganizationId(auth, scope.organizationId) == null) {
                    emptyList()
                } else {
                    memberJoinRequestSyncDAO.listByOrganizationId(scope.organizationId.toId()).map(::MemberJoinRequestPayload)
                }
            }

            SyncScope.InstanceOwner,
            is SyncScope.ProducerAccount,
            is SyncScope.Member,
            is SyncScope.Owner,
            -> {
                emptyList()
            }
        }

    private suspend fun approve(
        existing: MemberJoinRequest,
        incoming: MemberJoinRequest,
        mutation: ClientMutation,
    ): MutationOutcome {
        val now = Clock.System.now()
        val membersForOrganization = memberSyncDAO.getByOrganizationId(existing.organizationId)
        val conflictingMember = membersForOrganization.firstOrNull { it.email.equals(existing.email, ignoreCase = true) }
        if (conflictingMember != null) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, "email already exists in organization")
        }

        val invitationsForOrganization = memberInvitationDAO.listByOrganizationId(existing.organizationId)
        val matchingInvitations = invitationsForOrganization.filter { it.email.equals(existing.email, ignoreCase = true) }
        if (matchingInvitations.any { it.status == MemberInvitationStatus.ACTIVATED }) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, "email already exists in organization")
        }
        val pendingInvitations = matchingInvitations.filter { it.status == MemberInvitationStatus.PENDING_ACTIVATION }
        if (pendingInvitations.size > 1) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "multiple invitations already match this email")
        }
        val pendingInvitation = pendingInvitations.singleOrNull()

        val invitation =
            if (pendingInvitation == null) {
                MemberInvitation(
                    invitationId = generateId<MemberInvitation>().id,
                    organizationId = existing.organizationId,
                    email = existing.email,
                    firstName = existing.firstName,
                    lastName = existing.lastName,
                    roles = DEFAULT_MEMBER_ROLES,
                    status = MemberInvitationStatus.PENDING_ACTIVATION,
                    createdAt = now,
                    expiresAt = now + 168.hours,
                )
            } else {
                pendingInvitation.copy(
                    firstName = existing.firstName,
                    lastName = existing.lastName,
                    roles = DEFAULT_MEMBER_ROLES,
                    expiresAt = now + 168.hours,
                    resendRequestedAt = now,
                )
            }
        memberInvitationDAO.put(invitation, buildMemberInvitationChange(invitation))
        activationTokenDAO.invalidateByMemberInvitationId(invitation.invitationId.toId(), now)
        val token = buildActivationToken(invitation, now)
        activationTokenDAO.create(token)
        memberInvitationEmailPort.sendInvitationEmail(
            invitation,
            token,
            organizationSyncDAO.getById(invitation.organizationId)?.name,
        )

        val updatedRequest =
            existing.copy(
                status = MemberJoinRequestStatus.APPROVED,
                reviewedAt = now,
                reviewComment = incoming.reviewComment,
            )
        memberJoinRequestSyncDAO.put(updatedRequest, buildChange(updatedRequest))
        return applied(mutation, updatedRequest.requestId.id)
    }

    private suspend fun reject(
        existing: MemberJoinRequest,
        incoming: MemberJoinRequest,
        mutation: ClientMutation,
    ): MutationOutcome {
        val updatedRequest =
            existing.copy(
                status = MemberJoinRequestStatus.REJECTED,
                reviewedAt = Clock.System.now(),
                reviewComment = incoming.reviewComment,
            )
        memberJoinRequestSyncDAO.put(updatedRequest, buildChange(updatedRequest))
        rejectionEmailPort.sendRejectionEmail(
            updatedRequest,
            organizationSyncDAO.getById(updatedRequest.organizationId)?.name,
        )
        return applied(mutation, updatedRequest.requestId.id)
    }

    private fun resolveOrganizationId(
        auth: AuthenticatedInfo,
        payloadOrganizationId: String,
    ): String? {
        if (auth.roles.none { it == Role.ADMIN || it == Role.OWNER }) return null
        if (auth.roles.any { it == Role.OWNER }) return payloadOrganizationId
        val organizationId = auth.organizationId ?: return null
        return organizationId.takeIf { it == payloadOrganizationId }
    }

    private fun buildActivationToken(
        invitation: MemberInvitation,
        now: Instant,
    ): ActivationToken =
        ActivationToken(
            token = UUID.randomUUID().toString(),
            kind = ActivationKind.MEMBER,
            memberInvitationId = invitation.invitationId.toId(),
            adminEmail = invitation.email,
            createdAt = now,
            expiresAt = now + 168.hours,
        )

    private fun buildChange(request: MemberJoinRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberJoinRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.Organization(request.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = MemberJoinRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildMemberInvitationChange(invitation: MemberInvitation): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberInvitation,
            entityId = invitation.invitationId,
            scopeKey = SyncScope.Organization(invitation.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = MemberInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
        )

    private companion object {
        private val DEFAULT_MEMBER_ROLES = setOf(Role.VOLUNTEER)
    }
}

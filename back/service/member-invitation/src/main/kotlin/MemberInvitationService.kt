@file:OptIn(ExperimentalTime::class)

package memberinvitation

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.MemberInvitationEmailPort
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MemberInvitationPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.DuplicatePendingInvitationException
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class MemberInvitationService(
    private val memberInvitationDAO: MemberInvitationSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val activationTokenDAO: ActivationTokenDAO,
    private val memberInvitationEmailPort: MemberInvitationEmailPort,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val ownerSyncDAO: OwnerSyncDAO,
) : EntityTypeService<MemberInvitationPayload>(EntityType.MemberInvitation) {
    private companion object {
        private const val ORGANIZATION_ID_MISMATCH = "organization_id mismatch"
        private const val EMAIL_ALREADY_PENDING = "email already has a pending invitation"
        private const val EMAIL_BELONGS_TO_OWNER = "email already belongs to an owner"
    }

    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: MemberInvitationPayload,
    ): MutationOutcome {
        val organizationId =
            resolveOrganizationId(auth, payload.memberInvitation.organizationId.id)
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, ORGANIZATION_ID_MISMATCH)
        val invitation = payload.memberInvitation
        return if (invitation.invitationId.startsWith(ClientMutation.TMP_ID_PREFIX)) {
            createInvitation(mutation, organizationId, invitation)
        } else {
            resendInvitation(mutation, organizationId, invitation)
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val existing =
            memberInvitationDAO.findById(op.entityId) ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "invitation not found")
        resolveOrganizationId(auth, existing.organizationId.id) ?: return rejected(
            mutation,
            MutationErrorCode.FORBIDDEN,
            ORGANIZATION_ID_MISMATCH,
        )
        if (existing.status == MemberInvitationStatus.ACTIVATED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "activated invitation cannot be cancelled")
        }
        if (existing.status == MemberInvitationStatus.CANCELLED) {
            return applied(mutation, existing.invitationId)
        }
        val now = Clock.System.now()
        val cancelled = existing.copy(status = MemberInvitationStatus.CANCELLED)
        memberInvitationDAO.put(cancelled, buildChange(cancelled))
        activationTokenDAO.invalidateByMemberInvitationId(cancelled.invitationId.toId(), now)
        return applied(mutation, cancelled.invitationId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<MemberInvitationPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return memberInvitationDAO.listByOrganizationId(organizationId.toId()).map(::MemberInvitationPayload)
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<MemberInvitationPayload> =
        when (scope) {
            is SyncScope.Organization -> {
                memberInvitationDAO
                    .listByOrganizationId(
                        scope.organizationId.toId(),
                    ).map(::MemberInvitationPayload)
            }

            SyncScope.InstanceOwner,
            is SyncScope.ProducerAccount,
            is SyncScope.Member,
            is SyncScope.Owner,
            -> {
                emptyList()
            }
        }

    private suspend fun createInvitation(
        mutation: ClientMutation,
        organizationId: String,
        incoming: MemberInvitation,
    ): MutationOutcome {
        val resolvedOrganizationId = organizationId.toId<Organization>()
        // OWNER role is exclusive: an email already belonging to an instance owner may not be invited
        // as a member, which would otherwise collide with the owner's auth identity at activation.
        if (ownerSyncDAO.existsByEmail(incoming.email)) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, EMAIL_BELONGS_TO_OWNER)
        }
        val memberExists =
            memberSyncDAO
                .getByOrganizationId(resolvedOrganizationId)
                .any { it.email.equals(incoming.email, ignoreCase = true) }
        if (memberExists) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, EMAIL_ALREADY_PENDING)
        }

        val now = Clock.System.now()
        val pendingInvitation = memberInvitationDAO.findPendingByEmail(incoming.email)
        if (pendingInvitation != null) {
            if (pendingInvitation.expiresAt > now) {
                return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, EMAIL_ALREADY_PENDING)
            }
            // Expired pending invitation: cancel it to release the constraint before creating a new one.
            val cancelled = pendingInvitation.copy(status = MemberInvitationStatus.CANCELLED)
            memberInvitationDAO.put(cancelled, buildChange(cancelled))
            activationTokenDAO.invalidateByMemberInvitationId(cancelled.invitationId.toId(), now)
        }

        val invitation =
            incoming.copy(
                invitationId = generateId<MemberInvitation>().id,
                organizationId = resolvedOrganizationId,
                status = MemberInvitationStatus.PENDING_ACTIVATION,
                createdAt = now,
                expiresAt = now + 168.hours,
                resendRequestedAt = null,
                activatedAt = null,
            )
        return try {
            memberInvitationDAO.put(invitation, buildChange(invitation))
            val token = buildActivationToken(invitation, now)
            activationTokenDAO.create(token)
            memberInvitationEmailPort.sendInvitationEmail(
                invitation,
                token,
                organizationSyncDAO.getById(resolvedOrganizationId)?.name,
            )
            applied(mutation, invitation.invitationId)
        } catch (e: DuplicatePendingInvitationException) {
            rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, EMAIL_ALREADY_PENDING)
        }
    }

    private suspend fun resendInvitation(
        mutation: ClientMutation,
        organizationId: String,
        incoming: MemberInvitation,
    ): MutationOutcome {
        val existing =
            memberInvitationDAO.findById(incoming.invitationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "invitation not found")
        if (existing.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, ORGANIZATION_ID_MISMATCH)
        }
        if (!matchesResendContract(existing, incoming)) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "only resend_requested_at may change for invitations")
        }
        if (existing.status == MemberInvitationStatus.ACTIVATED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invitation already activated")
        }
        if (existing.status == MemberInvitationStatus.CANCELLED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invitation already cancelled")
        }
        val resendRequestedAt =
            incoming.resendRequestedAt
                ?: return rejected(mutation, MutationErrorCode.CONFLICT, "resend_requested_at is required")
        val persistedResendRequestedAt = existing.resendRequestedAt
        if (persistedResendRequestedAt != null && resendRequestedAt < persistedResendRequestedAt) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "resend_requested_at must move forward")
        }
        if (persistedResendRequestedAt == resendRequestedAt) {
            return applied(mutation, existing.invitationId)
        }

        val now = Clock.System.now()
        val updated =
            existing.copy(
                resendRequestedAt = resendRequestedAt,
                expiresAt = now + 168.hours,
                customEmailSubject = incoming.customEmailSubject,
                customEmailBody = incoming.customEmailBody,
            )
        memberInvitationDAO.put(updated, buildChange(updated))
        activationTokenDAO.invalidateByMemberInvitationId(updated.invitationId.toId(), now)
        val token = buildActivationToken(updated, now)
        activationTokenDAO.create(token)
        memberInvitationEmailPort.sendInvitationEmail(
            updated,
            token,
            organizationSyncDAO.getById(updated.organizationId)?.name,
        )
        return applied(mutation, updated.invitationId)
    }

    private fun resolveOrganizationId(
        auth: AuthenticatedInfo,
        payloadOrganizationId: String,
    ): String? {
        if (auth.roles.none { it == Role.ADMIN || it == Role.OWNER }) return null
        if (auth.roles.any { it == Role.OWNER }) return payloadOrganizationId
        val organizationId =
            auth.organizationId
                ?: return null
        return if (organizationId == payloadOrganizationId) {
            organizationId
        } else {
            null
        }
    }

    private fun matchesResendContract(
        existing: MemberInvitation,
        incoming: MemberInvitation,
    ): Boolean =
        existing.organizationId == incoming.organizationId &&
            existing.email == incoming.email &&
            existing.firstName == incoming.firstName &&
            existing.lastName == incoming.lastName &&
            existing.roles == incoming.roles

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

    private fun buildChange(invitation: MemberInvitation): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberInvitation,
            entityId = invitation.invitationId,
            scopeKey = SyncScope.Organization(invitation.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = MemberInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
        )
}

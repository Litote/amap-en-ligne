@file:OptIn(ExperimentalTime::class)

package owner

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.OwnerActivationEmailPort
import id.Id
import id.generateId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OwnerInvitationPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class OwnerInvitationService(
    private val ownerInvitationDAO: OwnerInvitationSyncDAO,
    private val ownerDAO: OwnerSyncDAO,
    private val activationTokenDAO: ActivationTokenDAO,
    private val ownerActivationEmailPort: OwnerActivationEmailPort,
) : EntityTypeService<OwnerInvitationPayload>(EntityType.OwnerInvitation) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: OwnerInvitationPayload,
    ): MutationOutcome {
        if (auth.roles.none { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only OWNER callers may mutate owner invitations")
        }
        val invitation = payload.ownerInvitation
        return if (invitation.invitationId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
            createInvitation(mutation, invitation)
        } else {
            resendInvitation(mutation, invitation)
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        if (auth.roles.none { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only OWNER callers may cancel owner invitations")
        }
        val invitation =
            ownerInvitationDAO.findById(Id(op.entityId)) ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "invitation not found")
        if (invitation.status == OwnerInvitationStatus.ACTIVATED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "activated invitation cannot be cancelled")
        }
        if (invitation.status == OwnerInvitationStatus.CANCELLED) {
            return applied(mutation, invitation.invitationId.id)
        }
        val now = Clock.System.now()
        val cancelled = invitation.copy(status = OwnerInvitationStatus.CANCELLED)
        ownerInvitationDAO.put(cancelled, buildChange(cancelled))
        activationTokenDAO.invalidateByOwnerInvitationId(cancelled.invitationId, now)
        return applied(mutation, cancelled.invitationId.id)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<OwnerInvitationPayload> {
        if (auth.roles.none { it == Role.OWNER }) return emptyList()
        return ownerInvitationDAO.listAll().map(::OwnerInvitationPayload)
    }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<OwnerInvitationPayload> =
        when (scope) {
            SyncScope.InstanceOwner -> snapshot(auth)

            is SyncScope.Organization,
            is SyncScope.ProducerAccount,
            is SyncScope.Member,
            is SyncScope.Owner,
            -> emptyList()
        }

    private suspend fun createInvitation(
        mutation: ClientMutation,
        incoming: OwnerInvitation,
    ): MutationOutcome {
        if (ownerDAO.existsByEmail(incoming.email) || ownerInvitationDAO.existsPendingByEmail(incoming.email)) {
            return rejected(mutation, MutationErrorCode.UNIQUE_VIOLATION, "email already invited")
        }
        val now = Clock.System.now()
        val invitation =
            incoming.copy(
                invitationId = generateId(),
                status = OwnerInvitationStatus.PENDING_ACTIVATION,
                submittedAt = now,
                resendRequestedAt = null,
                activatedAt = null,
            )
        ownerInvitationDAO.put(invitation, buildChange(invitation))
        val token = buildActivationToken(invitation, now)
        activationTokenDAO.create(token)
        ownerActivationEmailPort.sendOwnerActivationEmail(invitation, token)
        return applied(mutation, invitation.invitationId.id)
    }

    private suspend fun resendInvitation(
        mutation: ClientMutation,
        incoming: OwnerInvitation,
    ): MutationOutcome {
        val existing =
            ownerInvitationDAO.findById(incoming.invitationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "invitation not found")
        if (!matchesResendContract(existing, incoming)) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "only resend_requested_at may change for invitations")
        }
        if (existing.status == OwnerInvitationStatus.ACTIVATED) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invitation already activated")
        }
        if (existing.status == OwnerInvitationStatus.CANCELLED) {
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
            return applied(mutation, existing.invitationId.id)
        }
        val now = Clock.System.now()
        val updated = existing.copy(resendRequestedAt = resendRequestedAt)
        ownerInvitationDAO.put(updated, buildChange(updated))
        activationTokenDAO.invalidateByOwnerInvitationId(updated.invitationId, now)
        val token = buildActivationToken(updated, now)
        activationTokenDAO.create(token)
        ownerActivationEmailPort.sendOwnerActivationEmail(updated, token)
        return applied(mutation, updated.invitationId.id)
    }

    private fun matchesResendContract(
        existing: OwnerInvitation,
        incoming: OwnerInvitation,
    ): Boolean =
        existing.email == incoming.email &&
            existing.firstName == incoming.firstName &&
            existing.lastName == incoming.lastName

    private fun buildActivationToken(
        invitation: OwnerInvitation,
        now: Instant,
    ): ActivationToken =
        ActivationToken(
            token = UUID.randomUUID().toString(),
            kind = ActivationKind.OWNER,
            ownerInvitationId = invitation.invitationId,
            adminEmail = invitation.email,
            createdAt = now,
            expiresAt = now + 168.hours,
        )

    private fun buildChange(invitation: OwnerInvitation): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.OwnerInvitation,
            entityId = invitation.invitationId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OwnerInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
        )
}

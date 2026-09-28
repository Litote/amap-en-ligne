package core

import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberInvitationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.MemberInvitation

/**
 * UPSERT [Change]s for a [MemberInvitation] write: one on its `organization:{id}` scope plus the
 * `instance-owner` fan-out, so an OWNER lists pending invitations alongside members. Shared by
 * every writer (invitation, join-request approval, activation, organization import).
 */
fun memberInvitationChanges(invitation: MemberInvitation): List<Change> =
    listOf(
        SyncScope.Organization(invitation.organizationId.id).key,
        SyncScope.InstanceOwner.key,
    ).map { scopeKey ->
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberInvitation,
            entityId = invitation.invitationId,
            scopeKey = scopeKey,
            op = ChangeOp.UPSERT,
            payload = MemberInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
        )
    }

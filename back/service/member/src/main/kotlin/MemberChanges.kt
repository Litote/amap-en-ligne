package member

import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.Member

/**
 * UPSERT [Change]s for a [Member] write: one on `organization:{id}` plus the `instance-owner`
 * fan-out so an OWNER receives member updates incrementally.
 */
internal fun buildUpsertChanges(
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

/** UPSERT [Change]s for every membership row touched by an OWNER lifecycle action. */
internal fun buildLifecycleChanges(members: List<Member>): List<Change> =
    buildList {
        members.forEach { member ->
            addAll(buildUpsertChanges(member.organizationId.id, member))
        }
    }

/** DELETE tombstones for a [Member] row, on `organization:{id}` and `instance-owner`. */
internal fun buildDeleteChanges(
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

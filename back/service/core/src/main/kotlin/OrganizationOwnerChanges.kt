package core

import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.Organization

/**
 * `instance-owner` fan-out for an [Organization] write that changes what an OWNER lists
 * (name, contact, status, locale): an OWNER does not sync `organization:{id}`, so without it
 * the owner keeps showing the previous identity until its next full bootstrap.
 *
 * Returns an empty list when [before] and [after] share the same identity (e.g. volunteer
 * registrations), to avoid shipping the whole aggregate to every owner on each edit.
 */
fun organizationInstanceOwnerChanges(
    before: Organization?,
    after: Organization,
): List<Change> {
    if (before != null && before.identity() == after.identity()) return emptyList()
    return listOf(
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = after.organizationId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OrganizationPayload(after),
            producedAt = System.currentTimeMillis(),
        ),
    )
}

private fun Organization.identity() = listOf(name, contactEmail, activeStatus, website, timezone, defaultLanguage)

@file:OptIn(ExperimentalTime::class)

package core

import authentication.Role
import id.toId
import persistence.changes.ChangeOp
import persistence.changes.MemberInvitationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime

class MemberInvitationChangesTest {
    private val now = Clock.System.now()
    private val invitation =
        MemberInvitation(
            invitationId = "inv-1",
            organizationId = "org-1".toId(),
            email = "alice@example.com",
            firstName = "Alice",
            lastName = "Martin",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = now,
            expiresAt = now + 168.hours,
        )

    @Test
    fun `GIVEN an invitation WHEN building its changes THEN it is published on its organization and on instance-owner`() {
        val changes = memberInvitationChanges(invitation)

        assertEquals(
            listOf(SyncScope.Organization("org-1").key, SyncScope.InstanceOwner.key),
            changes.map { it.scopeKey },
        )
        changes.forEach { change ->
            assertEquals(EntityType.MemberInvitation, change.entityType)
            assertEquals("inv-1", change.entityId)
            assertEquals(ChangeOp.UPSERT, change.op)
            assertEquals(MemberInvitationPayload(invitation), change.payload)
        }
        assertEquals(2, changes.map { it.cursor }.toSet().size)
    }
}

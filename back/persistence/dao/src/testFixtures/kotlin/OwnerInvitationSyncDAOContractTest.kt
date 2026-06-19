@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.generateId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OwnerInvitationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

abstract class OwnerInvitationSyncDAOContractTest {
    protected abstract val dao: OwnerInvitationSyncDAO

    private fun buildInvitation(email: String = "owner-${java.util.UUID.randomUUID()}@example.com"): OwnerInvitation {
        val now = Clock.System.now()
        return OwnerInvitation(
            invitationId = generateId(),
            firstName = "Alice",
            lastName = "Dupont",
            email = email,
            status = OwnerInvitationStatus.PENDING_ACTIVATION,
            submittedAt = now,
        )
    }

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

    @Test
    fun `GIVEN invitation WHEN put then findById THEN returns it`() =
        runTest {
            val invitation = buildInvitation()

            dao.put(invitation, buildChange(invitation))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertEquals(invitation.invitationId, found.invitationId)
            assertEquals(invitation.email, found.email)
            assertEquals(invitation.firstName, found.firstName)
            assertEquals(invitation.lastName, found.lastName)
            assertEquals(invitation.status, found.status)
        }

    @Test
    fun `GIVEN no invitation WHEN findById THEN returns null`() =
        runTest {
            val result = dao.findById(generateId())

            assertNull(result)
        }

    @Test
    fun `GIVEN pending invitation WHEN existsPendingByEmail THEN returns true`() =
        runTest {
            val email = "pending-${java.util.UUID.randomUUID()}@example.com"
            val invitation = buildInvitation(email = email)
            dao.put(invitation, buildChange(invitation))

            assertTrue(dao.existsPendingByEmail(email))
        }

    @Test
    fun `GIVEN no invitation WHEN existsPendingByEmail THEN returns false`() =
        runTest {
            assertFalse(dao.existsPendingByEmail("absent@example.com"))
        }

    @Test
    fun `GIVEN pending invitation WHEN put ACTIVATED invitation THEN status is updated`() =
        runTest {
            val invitation = buildInvitation()
            dao.put(invitation, buildChange(invitation))
            val activatedAt = Clock.System.now()

            val activated = invitation.copy(status = OwnerInvitationStatus.ACTIVATED, activatedAt = activatedAt)
            dao.put(activated, buildChange(activated))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertEquals(OwnerInvitationStatus.ACTIVATED, found.status)
            assertNotNull(found.activatedAt)
            assertEquals(
                activatedAt.toEpochMilliseconds(),
                found.activatedAt!!.toEpochMilliseconds(),
            )
        }

    @Test
    fun `GIVEN activated invitation WHEN existsPendingByEmail THEN returns false`() =
        runTest {
            val email = "activated-${java.util.UUID.randomUUID()}@example.com"
            val invitation = buildInvitation(email = email)
            dao.put(invitation, buildChange(invitation))
            val activated = invitation.copy(status = OwnerInvitationStatus.ACTIVATED, activatedAt = Clock.System.now())
            dao.put(activated, buildChange(activated))

            assertFalse(dao.existsPendingByEmail(email))
        }

    @Test
    fun `GIVEN invitation WHEN put THEN activatedAt is null initially`() =
        runTest {
            val invitation = buildInvitation()
            dao.put(invitation, buildChange(invitation))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertNull(found.activatedAt)
        }

    @Test
    fun `GIVEN invitation WHEN put THEN submittedAt is preserved`() =
        runTest {
            val invitation = buildInvitation()
            dao.put(invitation, buildChange(invitation))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertEquals(
                invitation.submittedAt.toEpochMilliseconds(),
                found.submittedAt.toEpochMilliseconds(),
            )
        }

    @Test
    fun `GIVEN invitations WHEN listAll THEN returns all`() =
        runTest {
            val invitationA = buildInvitation()
            val invitationB = buildInvitation()
            dao.put(invitationA, buildChange(invitationA))
            dao.put(invitationB, buildChange(invitationB))

            val results = dao.listAll()

            assertTrue(results.any { it.invitationId == invitationA.invitationId })
            assertTrue(results.any { it.invitationId == invitationB.invitationId })
        }
}

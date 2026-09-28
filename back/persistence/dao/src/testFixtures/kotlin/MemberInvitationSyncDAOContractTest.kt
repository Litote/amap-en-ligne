@file:OptIn(ExperimentalTime::class)

package persistence.dao

import authentication.Role
import id.generateId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberInvitationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import kotlin.test.assertEquals
import kotlin.test.assertFails
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime

abstract class MemberInvitationSyncDAOContractTest {
    protected abstract val dao: MemberInvitationSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected abstract fun insertOrganization(organizationId: String)

    private fun buildInvitation(organizationId: String = generateId<Organization>().id): MemberInvitation {
        val now = Clock.System.now()
        return MemberInvitation(
            invitationId =
                java.util.UUID
                    .randomUUID()
                    .toString(),
            organizationId = id.Id(organizationId),
            email = "member-${java.util.UUID.randomUUID()}@example.com",
            firstName = "Alice",
            lastName = "Martin",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = now,
            expiresAt = now + 168.hours,
        )
    }

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

    @Test
    fun `GIVEN invitation WHEN create then findById THEN returns it`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertEquals(invitation.invitationId, found.invitationId)
            assertEquals(invitation.organizationId, found.organizationId)
            assertEquals(invitation.email, found.email)
            assertEquals(invitation.firstName, found.firstName)
            assertEquals(invitation.lastName, found.lastName)
            assertEquals(invitation.roles, found.roles)
        }

    @Test
    fun `GIVEN invitation with custom email subject and body WHEN create then findById THEN round-trips them`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation =
                buildInvitation(orgId).copy(
                    customEmailSubject = "Rejoins-nous",
                    customEmailBody = "Connecte-toi pour finaliser.",
                )

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertEquals("Rejoins-nous", found.customEmailSubject)
            assertEquals("Connecte-toi pour finaliser.", found.customEmailBody)
        }

    @Test
    fun `GIVEN invitation without custom email copy WHEN create then findById THEN custom fields are null`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertNull(found.customEmailSubject)
            assertNull(found.customEmailBody)
        }

    @Test
    fun `GIVEN no invitation WHEN findById THEN returns null`() =
        runTest {
            val found = dao.findById("nonexistent-invitation-id")

            assertNull(found)
        }

    @Test
    fun `GIVEN invitation WHEN findById THEN activatedAt is null initially`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertNull(found.activatedAt)
        }

    @Test
    fun `GIVEN invitations for two orgs WHEN listByOrganizationId THEN returns only matching org invitations`() =
        runTest {
            val orgId1 = generateId<Organization>().id
            val orgId2 = generateId<Organization>().id
            insertOrganization(orgId1)
            insertOrganization(orgId2)
            val inv1 = buildInvitation(orgId1)
            val inv2 = buildInvitation(orgId2)

            dao.put(inv1, listOf(buildChange(inv1)))
            dao.put(inv2, listOf(buildChange(inv2)))

            val result = dao.listByOrganizationId(id.Id(orgId1))
            assertEquals(1, result.size)
            assertEquals(inv1.invitationId, result.first().invitationId)
        }

    @Test
    fun `GIVEN multiple invitations for same org WHEN listByOrganizationId THEN returns all`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val inv1 = buildInvitation(orgId)
            val inv2 = buildInvitation(orgId)

            dao.put(inv1, listOf(buildChange(inv1)))
            dao.put(inv2, listOf(buildChange(inv2)))

            val result = dao.listByOrganizationId(id.Id(orgId))
            assertEquals(2, result.size)
            assertTrue(result.any { it.invitationId == inv1.invitationId })
            assertTrue(result.any { it.invitationId == inv2.invitationId })
        }

    @Test
    fun `GIVEN existing invitation WHEN put activated invitation THEN activatedAt is set`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)
            dao.put(invitation, listOf(buildChange(invitation)))

            val activatedAt = Clock.System.now()
            val activated = invitation.copy(status = MemberInvitationStatus.ACTIVATED, activatedAt = activatedAt)
            dao.put(activated, listOf(buildChange(activated)))

            val found = dao.findById(invitation.invitationId)
            assertNotNull(found)
            assertNotNull(found.activatedAt)
            assertEquals(activatedAt.toEpochMilliseconds(), found.activatedAt!!.toEpochMilliseconds())
        }

    @Test
    fun `GIVEN pending invitation WHEN findPendingByEmail THEN returns it`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findPendingByEmail(invitation.email)
            assertNotNull(found)
            assertEquals(invitation.invitationId, found.invitationId)
        }

    @Test
    fun `GIVEN pending invitation in org A WHEN findPendingByEmail THEN returns it globally`() =
        runTest {
            val orgIdA = generateId<Organization>().id
            val orgIdB = generateId<Organization>().id
            insertOrganization(orgIdA)
            insertOrganization(orgIdB)
            val invitation = buildInvitation(orgIdA)

            dao.put(invitation, listOf(buildChange(invitation)))

            // Global check: same email, different org → still found
            val found = dao.findPendingByEmail(invitation.email)
            assertNotNull(found)
            assertEquals(invitation.invitationId, found.invitationId)
        }

    @Test
    fun `GIVEN pending invitation WHEN findPendingByEmail with another letter case THEN returns it`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId).let { it.copy(email = it.email.replaceFirstChar(Char::uppercaseChar)) }

            dao.put(invitation, listOf(buildChange(invitation)))

            val found = dao.findPendingByEmail(invitation.email.lowercase())
            assertNotNull(found)
            assertEquals(invitation.invitationId, found.invitationId)
        }

    @Test
    fun `GIVEN pending invitation WHEN putting another pending one differing only by letter case THEN it is refused`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val first = buildInvitation(orgId)
            dao.put(first, listOf(buildChange(first)))
            val second =
                buildInvitation(orgId).copy(email = first.email.uppercase())

            assertFails { dao.put(second, listOf(buildChange(second))) }
            assertEquals(first.invitationId, dao.findPendingByEmail(first.email)?.invitationId)
        }

    @Test
    fun `GIVEN no pending invitation WHEN findPendingByEmail THEN returns null`() =
        runTest {
            val found = dao.findPendingByEmail("unknown@example.com")
            assertNull(found)
        }

    @Test
    fun `GIVEN changes on two scopes WHEN put THEN both are recorded`() =
        runTest {
            val orgId = generateId<Organization>().id
            insertOrganization(orgId)
            val invitation = buildInvitation(orgId)
            val orgChange = buildChange(invitation)
            val ownerChange = orgChange.copy(cursor = Cursor.next(), scopeKey = SyncScope.InstanceOwner.key)

            dao.put(invitation, listOf(orgChange, ownerChange))

            assertNotNull(
                changeDAO.since(SyncScope.Organization(orgId).key, null).find { it.entityId == invitation.invitationId },
            )
            assertNotNull(changeDAO.since(SyncScope.InstanceOwner.key, null).find { it.entityId == invitation.invitationId })
        }

    @Test
    fun `GIVEN pending and settled invitations in two orgs WHEN listPending THEN returns only pending ones`() =
        runTest {
            val orgA = generateId<Organization>().id
            val orgB = generateId<Organization>().id
            insertOrganization(orgA)
            insertOrganization(orgB)
            val pendingA = buildInvitation(orgA)
            val pendingB = buildInvitation(orgB)
            val activated = buildInvitation(orgA).copy(status = MemberInvitationStatus.ACTIVATED)
            val cancelled = buildInvitation(orgB).copy(status = MemberInvitationStatus.CANCELLED)
            listOf(pendingA, pendingB, activated, cancelled).forEach { dao.put(it, listOf(buildChange(it))) }

            val ids = dao.listPending().map { it.invitationId }

            assertTrue(pendingA.invitationId in ids)
            assertTrue(pendingB.invitationId in ids)
            assertTrue(activated.invitationId !in ids)
            assertTrue(cancelled.invitationId !in ids)
        }
}

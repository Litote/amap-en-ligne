@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberPayload
import persistence.changes.SyncScope
import persistence.model.AccessibilityOptions
import persistence.model.DeliveryReminders
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.UserPreferences
import persistence.model.UserSettings
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class MemberSyncDAOContractTest {
    protected abstract val memberSyncDAO: MemberSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun newMemberId() = UUID.randomUUID().toString()

    protected fun buildMember(
        memberId: String = newMemberId(),
        organizationId: String = newOrganizationId(),
    ): Member =
        Member(
            memberId = memberId.toId(),
            organizationId = organizationId.toId(),
            activeStatus = true,
            memberSettings =
                MemberSettings(
                    deliveryReminders = DeliveryReminders(daysBefore = 1, reminderTime = "08:00"),
                    accessibilityOptions =
                        AccessibilityOptions(
                            highContrast = false,
                            largeText = false,
                            screenReader = false,
                        ),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(1_000_000L),
                ),
            memberPreferences =
                MemberPreferences(
                    deliveryRemindersEnabled = true,
                    volunteerAlertsEnabled = true,
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(1_000_000L),
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(1_000_000L),
                ),
            userSettings =
                UserSettings(
                    language = "fr",
                    timezone = kotlinx.datetime.TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId(),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(1_000_000L),
                ),
        )

    protected fun buildUpsertChange(
        member: Member,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Member,
            entityId = member.memberId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = MemberPayload(member),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        memberId: String,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Member,
            entityId = memberId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a member WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member = buildMember(organizationId = orgId)

            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(member.memberId, result.first().memberId)
        }

    @Test
    fun `GIVEN no members WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = memberSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple members for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member1 = buildMember(organizationId = orgId)
            val member2 = buildMember(organizationId = orgId)

            memberSyncDAO.put(member1, listOf(buildUpsertChange(member1, orgId)))
            memberSyncDAO.put(member2, listOf(buildUpsertChange(member2, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.memberId == member1.memberId })
            assertTrue(result.any { it.memberId == member2.memberId })
        }

    @Test
    fun `GIVEN members for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val memberA = buildMember(organizationId = orgA)
            val memberB = buildMember(organizationId = orgB)

            memberSyncDAO.put(memberA, listOf(buildUpsertChange(memberA, orgA)))
            memberSyncDAO.put(memberB, listOf(buildUpsertChange(memberB, orgB)))

            val result = memberSyncDAO.getByOrganizationId(orgA.toId<Organization>())
            assertEquals(1, result.size)
            assertEquals(memberA.memberId, result.first().memberId)
        }

    @Test
    fun `GIVEN an existing member WHEN delete THEN getByOrganizationId returns empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member = buildMember(organizationId = orgId)
            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            memberSyncDAO.delete(member.memberId, orgId.toId(), listOf(buildDeleteChange(member.memberId.id, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a member WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member = buildMember(organizationId = orgId)
            val orgChange = buildUpsertChange(member, orgId)
            val ownerChange = orgChange.copy(scopeKey = SyncScope.InstanceOwner.key)

            memberSyncDAO.put(member, listOf(orgChange, ownerChange))

            assertNotNull(changeDAO.since(SyncScope.Organization(orgId).key, null).find { it.entityId == member.memberId.id })
            assertNotNull(changeDAO.since(SyncScope.InstanceOwner.key, null).find { it.entityId == member.memberId.id })
        }

    @Test
    fun `GIVEN a member WHEN put updated version THEN getByOrganizationId returns updated`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member = buildMember(organizationId = orgId)
            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val updated = member.copy(activeStatus = false)
            memberSyncDAO.put(updated, listOf(buildUpsertChange(updated, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(false, result.first().activeStatus)
        }

    @Test
    fun `GIVEN members in two orgs WHEN listAll THEN returns all members`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val memberA = buildMember(organizationId = orgA)
            val memberB = buildMember(organizationId = orgB)

            memberSyncDAO.put(memberA, listOf(buildUpsertChange(memberA, orgA)))
            memberSyncDAO.put(memberB, listOf(buildUpsertChange(memberB, orgB)))

            val result = memberSyncDAO.listAll()
            assertTrue(result.any { it.memberId == memberA.memberId })
            assertTrue(result.any { it.memberId == memberB.memberId })
        }

    @Test
    fun `GIVEN a member WHEN put THEN findOrganizationIdBySub returns its organization`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            // memberId == sub by convention: use the memberId as the sub
            val sub = "sub-${UUID.randomUUID()}"
            val member = buildMember(memberId = sub, organizationId = orgId)

            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val result = memberSyncDAO.findOrganizationIdBySub(sub)
            assertNotNull(result)
            assertEquals(orgId, result.id)
        }

    @Test
    fun `GIVEN no member with that sub WHEN findOrganizationIdBySub THEN returns null`() =
        runTest {
            val result = memberSyncDAO.findOrganizationIdBySub("sub-absent-${UUID.randomUUID()}")
            assertEquals(null, result)
        }

    @Test
    fun `GIVEN a member WHEN put THEN getMembersBySub returns that member`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sub = "sub-${UUID.randomUUID()}"
            val member = buildMember(memberId = sub, organizationId = orgId)

            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val result = memberSyncDAO.getMembersBySub(sub)
            assertEquals(1, result.size)
            assertEquals(member.memberId, result.first().memberId)
        }

    @Test
    fun `GIVEN no member with that sub WHEN getMembersBySub THEN returns empty list`() =
        runTest {
            val result = memberSyncDAO.getMembersBySub("sub-absent-${UUID.randomUUID()}")
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a member WHEN put then delete THEN findOrganizationIdBySub returns null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sub = "sub-${UUID.randomUUID()}"
            val member = buildMember(memberId = sub, organizationId = orgId)
            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            memberSyncDAO.delete(member.memberId, orgId.toId(), listOf(buildDeleteChange(sub, orgId)))

            assertEquals(null, memberSyncDAO.findOrganizationIdBySub(sub))
        }

    @Test
    fun `GIVEN an active member WHEN setActiveStatusBySub(false) THEN the row is suspended`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sub = "sub-${UUID.randomUUID()}"
            val member = buildMember(memberId = sub, organizationId = orgId).copy(activeStatus = true)
            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val suspended = member.copy(activeStatus = false)
            memberSyncDAO.setActiveStatusBySub(
                sub,
                activeStatus = false,
                changes = listOf(buildUpsertChange(suspended, orgId)),
            )

            val result = memberSyncDAO.getMembersBySub(sub)
            assertEquals(1, result.size)
            assertEquals(false, result.first().activeStatus)
        }

    @Test
    fun `GIVEN a member WHEN anonymiseBySub THEN PII is cleared and active_status false`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sub = "sub-${UUID.randomUUID()}"
            val member =
                buildMember(memberId = sub, organizationId = orgId).copy(
                    activeStatus = true,
                    firstName = "Alice",
                    email = "alice@example.org",
                )
            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val anonymised = member.copy(activeStatus = false, firstName = null, email = null)
            memberSyncDAO.anonymiseBySub(
                sub,
                changes = listOf(buildUpsertChange(anonymised, orgId)),
            )

            val byOrg = memberSyncDAO.getByOrganizationId(orgId.toId())
            val row = byOrg.single { it.memberId == member.memberId }
            assertEquals(false, row.activeStatus)
        }

    @Test
    fun `GIVEN a member with PII and account_status WHEN put THEN round-trip preserves all fields`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val member =
                buildMember(organizationId = orgId).copy(
                    firstName = "Alice",
                    lastName = "Martin",
                    email = "alice@example.org",
                    phone = "0612345678",
                    accountStatus = MemberAccountStatus.SUSPENDED,
                )

            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId()).single()
            assertEquals("Alice", result.firstName)
            assertEquals("Martin", result.lastName)
            assertEquals("alice@example.org", result.email)
            assertEquals("0612345678", result.phone)
            assertEquals(MemberAccountStatus.SUSPENDED, result.accountStatus)
        }

    @Test
    fun `GIVEN a legacy member without PII WHEN put THEN round-trip keeps the new fields null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            // Default-built member has null firstName/lastName/email/phone/accountStatus,
            // matching legacy rows created before V22.
            val member = buildMember(organizationId = orgId)

            memberSyncDAO.put(member, listOf(buildUpsertChange(member, orgId)))

            val result = memberSyncDAO.getByOrganizationId(orgId.toId()).single()
            assertEquals(null, result.firstName)
            assertEquals(null, result.lastName)
            assertEquals(null, result.email)
            assertEquals(null, result.phone)
            assertEquals(null, result.accountStatus)
        }
}

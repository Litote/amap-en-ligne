@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.generateId
import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.SyncScope
import persistence.model.AccessibilityOptions
import persistence.model.AccountStatus
import persistence.model.DeliveryReminders
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Owner
import persistence.model.UserPreferences
import persistence.model.UserSettings
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class OwnerSyncDAOContractTest {
    protected abstract val ownerDAO: OwnerSyncDAO
    protected abstract val memberSyncDAO: MemberSyncDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOwnerId() = UUID.randomUUID().toString()

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun buildMember(
        memberId: String = UUID.randomUUID().toString(),
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

    protected fun buildMemberUpsertChange(member: Member): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Member,
            entityId = member.memberId.id,
            scopeKey = SyncScope.Organization(member.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildMemberTombstone(member: Member): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Member,
            entityId = member.memberId.id,
            scopeKey = SyncScope.Organization(member.organizationId.id).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildOwner(
        ownerId: String = newOwnerId(),
        email: String = "${UUID.randomUUID()}@example.com",
        accountStatus: AccountStatus = AccountStatus.ACTIVE,
    ): Owner =
        Owner(
            ownerId = ownerId.toId(),
            firstName = "Alice",
            lastName = "Dupont",
            email = email,
            phone = null,
            accountStatus = accountStatus,
            registeredAt = Instant.fromEpochMilliseconds(1_000_000L),
            updatedAt = Instant.fromEpochMilliseconds(1_000_000L),
        )

    protected abstract fun buildChange(owner: Owner): persistence.changes.Change

    @Test
    fun `GIVEN an owner WHEN put then listAll THEN returns it`() =
        runTest {
            val owner = buildOwner()
            ownerDAO.put(owner, buildChange(owner))

            val result = ownerDAO.listAll()
            assertTrue(result.any { it.ownerId == owner.ownerId })
        }

    @Test
    fun `GIVEN an owner WHEN findById THEN returns it`() =
        runTest {
            val owner = buildOwner()
            ownerDAO.put(owner, buildChange(owner))

            val result = ownerDAO.findById(owner.ownerId)
            assertNotNull(result)
            assertEquals(owner.ownerId, result.ownerId)
            assertEquals(owner.email, result.email)
        }

    @Test
    fun `GIVEN no owner WHEN findById THEN returns null`() =
        runTest {
            val result = ownerDAO.findById(generateId())
            assertNull(result)
        }

    @Test
    fun `GIVEN an owner WHEN updateStatus then findById THEN returns updated status`() =
        runTest {
            val owner = buildOwner(accountStatus = AccountStatus.ACTIVE)
            ownerDAO.put(owner, buildChange(owner))

            ownerDAO.updateStatus(owner.ownerId, AccountStatus.SUSPENDED, buildChange(owner))

            val result = ownerDAO.findById(owner.ownerId)
            assertNotNull(result)
            assertEquals(AccountStatus.SUSPENDED, result.accountStatus)
        }

    @Test
    fun `GIVEN an owner WHEN existsByEmail with same email THEN returns true`() =
        runTest {
            val owner = buildOwner(email = "unique@example.com")
            ownerDAO.put(owner, buildChange(owner))

            assertTrue(ownerDAO.existsByEmail("unique@example.com"))
        }

    @Test
    fun `GIVEN no owner WHEN existsByEmail THEN returns false`() =
        runTest {
            assertFalse(ownerDAO.existsByEmail("absent@example.com"))
        }

    @Test
    fun `GIVEN an owner WHEN existsBySub with ownerId THEN returns true`() =
        runTest {
            // Since ownerId == sub, existsBySub with the owner's id must return true.
            val ownerId = UUID.randomUUID().toString()
            val owner = buildOwner(ownerId = ownerId)
            ownerDAO.put(owner, buildChange(owner))

            assertTrue(ownerDAO.existsBySub(ownerId))
        }

    @Test
    fun `GIVEN no owner WHEN existsBySub THEN returns false`() =
        runTest {
            assertFalse(ownerDAO.existsBySub("absent-sub"))
        }

    @Test
    fun `GIVEN member rows WHEN promoteToOwner THEN owner row created and member rows deleted`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sub = UUID.randomUUID().toString()
            // Since memberId == sub by convention, use sub as the member id.
            val member1 = buildMember(memberId = sub, organizationId = orgId)
            val member2 = buildMember(memberId = "$sub-2", organizationId = orgId)
            memberSyncDAO.put(member1, listOf(buildMemberUpsertChange(member1)))
            memberSyncDAO.put(member2, listOf(buildMemberUpsertChange(member2)))

            val owner = buildOwner(ownerId = sub)
            val ownerChange =
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.Owner,
                    entityId = owner.ownerId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = null,
                    producedAt = System.currentTimeMillis(),
                )
            val memberChanges =
                listOf(
                    buildMemberTombstone(member1),
                    buildMemberTombstone(member1).copy(scopeKey = SyncScope.InstanceOwner.key),
                    buildMemberTombstone(member2),
                    buildMemberTombstone(member2).copy(scopeKey = SyncScope.InstanceOwner.key),
                )

            ownerDAO.promoteToOwner(
                owner = owner,
                ownerChange = ownerChange,
                membersToRevoke = listOf(member1, member2),
                memberChanges = memberChanges,
            )

            // Owner row was created
            val foundOwner = ownerDAO.findById(owner.ownerId)
            assertNotNull(foundOwner)
            assertEquals(owner.ownerId, foundOwner.ownerId)

            // Member rows were deleted
            val remaining = memberSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(remaining.isEmpty(), "Expected all member rows to be deleted after promotion")
        }

    @Test
    fun `GIVEN no member rows WHEN promoteToOwner THEN owner row created`() =
        runTest {
            val owner = buildOwner()
            val ownerChange =
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.Owner,
                    entityId = owner.ownerId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = null,
                    producedAt = System.currentTimeMillis(),
                )

            ownerDAO.promoteToOwner(
                owner = owner,
                ownerChange = ownerChange,
                membersToRevoke = emptyList(),
                memberChanges = emptyList(),
            )

            val foundOwner = ownerDAO.findById(owner.ownerId)
            assertNotNull(foundOwner)
            assertEquals(owner.ownerId, foundOwner.ownerId)
        }

    @Test
    fun `GIVEN an owner WHEN findBySub with ownerId as sub THEN returns it`() =
        runTest {
            // Since ownerId == sub by convention, findBySub(ownerId.id) must return the owner.
            val owner = buildOwner()
            ownerDAO.put(owner, buildChange(owner))

            val found = ownerDAO.findBySub(owner.ownerId.id)
            assertNotNull(found)
            assertEquals(owner.ownerId, found.ownerId)
        }

    @Test
    fun `GIVEN no owner with this id WHEN findBySub THEN returns null`() =
        runTest {
            val result = ownerDAO.findBySub("nonexistent-${UUID.randomUUID()}")
            assertNull(result)
        }

    @Test
    fun `GIVEN an owner WHEN delete THEN findById returns null`() =
        runTest {
            val owner = buildOwner()
            ownerDAO.put(owner, buildChange(owner))

            val tombstone =
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.Owner,
                    entityId = owner.ownerId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.DELETE,
                    payload = null,
                    producedAt = System.currentTimeMillis(),
                )
            ownerDAO.delete(owner.ownerId, tombstone)

            assertNull(ownerDAO.findById(owner.ownerId))
        }
}

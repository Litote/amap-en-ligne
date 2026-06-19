@file:OptIn(ExperimentalTime::class)

package owner

import authentication.AuthenticatedInfo
import authentication.Role
import core.OwnerRoleProvisioningPort
import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.OwnerPayload
import persistence.changes.Upsert
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.AccountStatus
import persistence.model.DeliveryReminders
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Owner
import persistence.model.Server
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.collections.get
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
internal class OwnerTypeServiceTest {
    private val ownerDAO = mockk<OwnerSyncDAO>()
    private val memberSyncDAO = mockk<MemberSyncDAO>()
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val roleService = RoleService(ownerDAO, userProvisioningPort)
    private val accountLifecycleEmailPort = mockk<AccountLifecycleEmailPort>(relaxed = true)
    private val accountDeletionLogDAO = mockk<AccountDeletionLogDAO>(relaxed = true)
    private val roleProvisioningPort = mockk<OwnerRoleProvisioningPort>(relaxed = true)
    private val ownerService =
        OwnerService(
            ownerDAO = ownerDAO,
            roleService = roleService,
            userProvisioningPort = userProvisioningPort,
            accountLifecycleEmailPort = accountLifecycleEmailPort,
            accountDeletionLogDAO = accountDeletionLogDAO,
        )
    private val service = OwnerTypeService(ownerDAO, memberSyncDAO, roleService, ownerService, roleProvisioningPort)

    init {
        // By default no email maps to a producer; specific tests override this.
        coEvery { userProvisioningPort.findProducerAccountIdByEmail(any()) } returns null
    }

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "caller-1",
            firstName = "Alice",
            lastName = "Owner",
            email = "alice@example.com",
            producerAccountId = null,
            organizationId = null,
            roles = listOf(Role.OWNER),
        )
    private val adminAuth =
        AuthenticatedInfo(
            memberId = "caller-2",
            firstName = "Bob",
            lastName = "Admin",
            email = "bob@example.com",
            producerAccountId = null,
            organizationId = "org-1",
            roles = listOf(Role.ADMIN),
        )

    private fun buildOwner(
        ownerId: String = "owner-1",
        accountStatus: AccountStatus = AccountStatus.ACTIVE,
    ): Owner =
        Owner(
            ownerId = ownerId.toId(),
            firstName = "Alice",
            lastName = "Dupont",
            email = "$ownerId@example.com",
            accountStatus = accountStatus,
            registeredAt = Instant.fromEpochMilliseconds(1_000_000L),
            updatedAt = Instant.fromEpochMilliseconds(1_000_000L),
        )

    private fun buildMember(
        id: String = "member-1",
        orgId: String = "org-1",
        roles: Set<Role> = setOf(Role.VOLUNTEER),
    ): Member =
        Member(
            memberId = id.toId(),
            organizationId = orgId.toId(),
            roles = roles,
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
                    timezone = TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId<Server>(),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(1_000_000L),
                ),
        )

    private fun buildUpsertMutation(owner: Owner): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(OwnerPayload(owner)),
        )

    // ── snapshot ─────────────────────────────────────────────────────────────

    @Test
    fun `GIVEN OWNER caller WHEN snapshot THEN returns all owners wrapped in OwnerPayload`() =
        runTest {
            val owner1 = buildOwner("owner-1")
            val owner2 = buildOwner("owner-2")
            coEvery { ownerDAO.listAll() } returns listOf(owner1, owner2)

            val result = service.snapshot(ownerAuth)

            assertEquals(2, result.size)
            assertEquals(owner1, result[0].owner)
            assertEquals(owner2, result[1].owner)
        }

    @Test
    fun `GIVEN non-OWNER caller WHEN snapshot THEN returns empty list`() =
        runTest {
            val result = service.snapshot(adminAuth)

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { ownerDAO.listAll() }
        }

    // ── applyUpsert — promote (no existing owner row) ────────────────────────
    // After sub/id unification: the incoming ownerId == target's sub (memberId).
    // Promotion is triggered when ownerDAO.findById returns null for that id.

    @Test
    fun `GIVEN new owner id and target user with no existing memberships WHEN promote THEN APPLIED`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-target")
            coEvery { ownerDAO.findById("sub-target".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns emptyList()
            coEvery { ownerDAO.existsBySub("sub-target") } returns false
            coEvery { ownerDAO.promoteToOwner(any(), any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotNull(outcome.serverEntityId)
            assertEquals("sub-target", outcome.serverEntityId)
        }

    @Test
    fun `GIVEN new owner id and target user already is OWNER WHEN promote THEN REJECTED OWNER_EXCLUSIVE`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-already-owner")
            coEvery { ownerDAO.findById("sub-already-owner".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-already-owner") } returns emptyList()
            coEvery { ownerDAO.existsBySub("sub-already-owner") } returns true

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.OWNER_EXCLUSIVE, outcome.error?.code)
            coVerify(exactly = 0) { ownerDAO.promoteToOwner(any(), any(), any(), any()) }
        }

    @Test
    fun `GIVEN new owner id and target email already a producer WHEN promote THEN REJECTED PRODUCER_EXCLUSIVE`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-producer")
            coEvery { ownerDAO.findById("sub-producer".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-producer") } returns emptyList()
            coEvery { ownerDAO.existsBySub("sub-producer") } returns false
            coEvery { userProvisioningPort.findProducerAccountIdByEmail(incoming.email) } returns "pa-1"

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.PRODUCER_EXCLUSIVE, outcome.error?.code)
            coVerify(exactly = 0) { ownerDAO.promoteToOwner(any(), any(), any(), any()) }
        }

    @Test
    fun `GIVEN new owner id and user has member rows but is not yet OWNER WHEN promote THEN APPLIED and rows stripped`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-member")
            val existingMember = buildMember(id = "sub-member", roles = setOf(Role.VOLUNTEER))
            coEvery { ownerDAO.findById("sub-member".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-member") } returns listOf(existingMember)
            coEvery { ownerDAO.existsBySub("sub-member") } returns false
            // VOLUNTEER — no LAST_ADMIN concern, org members list not queried
            coEvery { ownerDAO.promoteToOwner(any(), any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotNull(outcome.serverEntityId)
            coVerify(exactly = 1) { ownerDAO.promoteToOwner(any(), any(), match { it.size == 1 }, any()) }
        }

    @Test
    fun `GIVEN new owner id and target user is last admin of an org WHEN promote THEN REJECTED LAST_ADMIN`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-admin")
            val adminMember = buildMember(id = "sub-admin", orgId = "org-1", roles = setOf(Role.ADMIN))
            coEvery { ownerDAO.findById("sub-admin".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-admin") } returns listOf(adminMember)
            coEvery { ownerDAO.existsBySub("sub-admin") } returns false
            // Only one admin in that org — LAST_ADMIN
            coEvery { memberSyncDAO.getByOrganizationId("org-1".toId()) } returns listOf(adminMember)

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.LAST_ADMIN, outcome.error?.code)
            coVerify(exactly = 0) { ownerDAO.promoteToOwner(any(), any(), any(), any()) }
        }

    @Test
    fun `GIVEN new owner id and target user is admin but other admins exist WHEN promote THEN APPLIED`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-admin")
            val adminMember = buildMember(id = "sub-admin", orgId = "org-1", roles = setOf(Role.ADMIN))
            val otherAdmin = buildMember(id = "m-2", orgId = "org-1", roles = setOf(Role.ADMIN))
            coEvery { ownerDAO.findById("sub-admin".toId()) } returns null
            coEvery { memberSyncDAO.getMembersBySub("sub-admin") } returns listOf(adminMember)
            coEvery { ownerDAO.existsBySub("sub-admin") } returns false
            coEvery { memberSyncDAO.getByOrganizationId("org-1".toId()) } returns listOf(adminMember, otherAdmin)
            coEvery { ownerDAO.promoteToOwner(any(), any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals("sub-admin", outcome.serverEntityId)
        }

    // ── applyUpsert — revoke (SUSPENDED) ─────────────────────────────────────

    @Test
    fun `GIVEN existing owner id with SUSPENDED status WHEN upsert THEN delegates to ownerService_revoke`() =
        runTest {
            val owner1 = buildOwner(ownerId = "owner-1")
            val owner2 = buildOwner(ownerId = "owner-2")
            val incoming = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.SUSPENDED)
            coEvery { ownerDAO.findById("owner-1".toId()) } returns owner1
            coEvery { ownerDAO.listAll() } returns listOf(owner1, owner2)
            coEvery { ownerDAO.updateStatus(any(), any(), any()) } returns Unit
            coEvery { ownerDAO.findBySub(any()) } returns null

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { ownerDAO.updateStatus("owner-1".toId(), AccountStatus.SUSPENDED, any()) }
        }

    @Test
    fun `GIVEN last owner with SUSPENDED status WHEN upsert THEN REJECTED LAST_OWNER`() =
        runTest {
            val owner1 = buildOwner(ownerId = "owner-1")
            val incoming = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.SUSPENDED)
            coEvery { ownerDAO.findById("owner-1".toId()) } returns owner1
            coEvery { ownerDAO.listAll() } returns listOf(owner1)

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.LAST_OWNER, outcome.error?.code)
        }

    // ── applyUpsert — self profile update ──────────────────────────────────────

    @Test
    fun `GIVEN OWNER caller upserts own owner row with changed profile fields WHEN applyUpsert THEN profile is updated and APPLIED`() =
        runTest {
            val selfOwnerAuth =
                AuthenticatedInfo(
                    memberId = "owner-1",
                    firstName = "Alice",
                    lastName = "Owner",
                    email = "owner-1@example.com",
                    producerAccountId = null,
                    organizationId = null,
                    roles = listOf(Role.OWNER),
                )
            val existingOwner = buildOwner(ownerId = "owner-1")
            val incoming = buildOwner(ownerId = "owner-1").copy(firstName = "NewName")
            coEvery { ownerDAO.findById("owner-1".toId()) } returns existingOwner
            coEvery { ownerDAO.findBySub("owner-1") } returns existingOwner
            coEvery { ownerDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(selfOwnerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { ownerDAO.put(any(), any()) }
        }

    // ── applyUpsert — reactivate (ACTIVE) ────────────────────────────────────

    @Test
    fun `GIVEN existing owner with ACTIVE status WHEN upsert THEN reactivated`() =
        runTest {
            val suspended = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.SUSPENDED)
            val incoming = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.ACTIVE)
            coEvery { ownerDAO.findById("owner-1".toId()) } returns suspended
            coEvery { ownerDAO.updateStatus(any(), any(), any()) } returns Unit
            coEvery { ownerDAO.findBySub(any()) } returns null

            val outcome = service.applyUpsert(ownerAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { ownerDAO.updateStatus("owner-1".toId(), AccountStatus.ACTIVE, any()) }
        }

    // ── applyUpsert — auth guard ──────────────────────────────────────────────

    @Test
    fun `GIVEN non-OWNER caller WHEN applyUpsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val incoming = buildOwner(ownerId = "sub-target")

            val outcome = service.applyUpsert(adminAuth, buildUpsertMutation(incoming), OwnerPayload(incoming))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    // ── applyDelete ───────────────────────────────────────────────────────────

    @Test
    fun `WHEN applyDelete called by non-OWNER THEN REJECTED FORBIDDEN`() =
        runTest {
            val op = Delete(entityType = EntityType.Owner, entityId = "owner-1")
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(adminAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `WHEN applyDelete called by OWNER THEN delegates to ownerService_delete`() =
        runTest {
            val owner1 = buildOwner(ownerId = "owner-1")
            val owner2 = buildOwner(ownerId = "owner-2")
            coEvery { ownerDAO.findById("owner-1".toId()) } returns owner1
            coEvery { ownerDAO.listAll() } returns listOf(owner1, owner2)
            coEvery { ownerDAO.findBySub(any()) } returns null
            coEvery { ownerDAO.delete(any(), any()) } returns Unit

            val op = Delete(entityType = EntityType.Owner, entityId = "owner-1")
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(ownerAuth, mutation, op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { ownerDAO.delete("owner-1".toId(), any()) }
        }
}

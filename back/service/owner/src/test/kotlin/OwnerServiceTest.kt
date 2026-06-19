@file:OptIn(ExperimentalTime::class)

package owner

import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.OwnersBroadcastEvent
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import persistence.changes.MutationErrorCode
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountDeletionLog
import persistence.model.AccountStatus
import persistence.model.DeletedAccountRole
import persistence.model.Owner
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class OwnerServiceTest {
    private val ownerDAO = mockk<OwnerSyncDAO>()
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val roleService = RoleService(ownerDAO, userProvisioningPort)
    private val accountLifecycleEmailPort = mockk<AccountLifecycleEmailPort>(relaxed = true)
    private val accountDeletionLogDAO = mockk<AccountDeletionLogDAO>(relaxed = true)
    private val ownerService =
        OwnerService(
            ownerDAO = ownerDAO,
            roleService = roleService,
            userProvisioningPort = userProvisioningPort,
            accountLifecycleEmailPort = accountLifecycleEmailPort,
            accountDeletionLogDAO = accountDeletionLogDAO,
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

    // After sub/id unification: ownerId == sub. The actor sub is "owner-actor".
    private val actorOwner = buildOwner(ownerId = "owner-actor")

    // -------------------------------------------------------------------------
    // suspend
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN owner not found WHEN suspend THEN NotFound`() =
        runTest {
            coEvery { ownerDAO.findById(any()) } returns null

            val result = ownerService.suspend(actorSub = "sub-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { ownerDAO.updateStatus(any(), any(), any()) }
        }

    @Test
    fun `GIVEN actor targets self WHEN suspend THEN Rejected SELF_ACTION_FORBIDDEN`() =
        runTest {
            // After unification: ownerId == sub, so use actorSub as the ownerId to trigger self-action.
            val target = buildOwner(ownerId = "sub-actor")
            coEvery { ownerDAO.findById(any()) } returns target

            val result = ownerService.suspend(actorSub = "sub-actor", ownerId = "sub-actor")

            assertIs<OwnerLifecycleOutcome.Rejected>(result)
            assertEquals(MutationErrorCode.SELF_ACTION_FORBIDDEN, result.code)
            coVerify(exactly = 0) { ownerDAO.updateStatus(any(), any(), any()) }
        }

    @Test
    fun `GIVEN only one active owner WHEN suspend THEN Rejected LAST_OWNER`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1")
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.listAll() } returns listOf(target)

            val result = ownerService.suspend(actorSub = "sub-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Rejected>(result)
            assertEquals(MutationErrorCode.LAST_OWNER, result.code)
        }

    @Test
    fun `GIVEN two active owners WHEN suspend THEN Success and ports fired`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1")
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.listAll() } returns listOf(target, actorOwner)
            coEvery { ownerDAO.findBySub("owner-actor") } returns actorOwner
            coEvery { ownerDAO.updateStatus(any(), any(), any()) } returns Unit

            val result = ownerService.suspend(actorSub = "owner-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { ownerDAO.updateStatus(target.ownerId, AccountStatus.SUSPENDED, any()) }
            coVerify(exactly = 1) { userProvisioningPort.banUser("owner-1") }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountSuspended(any()) }
            coVerify(exactly = 1) {
                accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                    event = OwnersBroadcastEvent.ACCOUNT_SUSPENDED,
                    actorOwnerEmail = actorOwner.email,
                    impactedRole = AccountLifecycleRole.OWNER,
                )
            }
        }

    @Test
    fun `GIVEN provider throws WHEN suspend THEN Success is still returned`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1")
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.listAll() } returns listOf(target, actorOwner)
            coEvery { ownerDAO.findBySub("owner-actor") } returns actorOwner
            coEvery { ownerDAO.updateStatus(any(), any(), any()) } returns Unit
            coEvery { userProvisioningPort.banUser(any()) } throws RuntimeException("auth provider down")

            val result = ownerService.suspend(actorSub = "owner-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountSuspended(any()) }
        }

    // -------------------------------------------------------------------------
    // reactivate
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN suspended owner WHEN reactivate THEN flips to ACTIVE and unbans`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.SUSPENDED)
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.findBySub("owner-actor") } returns actorOwner
            coEvery { ownerDAO.updateStatus(any(), any(), any()) } returns Unit

            val result = ownerService.reactivate(actorSub = "owner-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { ownerDAO.updateStatus(target.ownerId, AccountStatus.ACTIVE, any()) }
            coVerify(exactly = 1) { userProvisioningPort.unbanUser("owner-1") }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountReactivated(any()) }
        }

    @Test
    fun `GIVEN actor targets self WHEN reactivate THEN Rejected SELF_ACTION_FORBIDDEN`() =
        runTest {
            val target = buildOwner(ownerId = "owner-actor", accountStatus = AccountStatus.SUSPENDED)
            coEvery { ownerDAO.findById(any()) } returns target

            val result = ownerService.reactivate(actorSub = "owner-actor", ownerId = "owner-actor")

            assertIs<OwnerLifecycleOutcome.Rejected>(result)
            assertEquals(MutationErrorCode.SELF_ACTION_FORBIDDEN, result.code)
        }

    // -------------------------------------------------------------------------
    // delete
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN owner not found WHEN delete THEN NotFound`() =
        runTest {
            coEvery { ownerDAO.findById(any()) } returns null

            val result = ownerService.delete(actorSub = "sub-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { ownerDAO.delete(any(), any()) }
        }

    @Test
    fun `GIVEN actor targets self WHEN delete THEN Rejected SELF_ACTION_FORBIDDEN`() =
        runTest {
            val target = buildOwner(ownerId = "owner-actor")
            coEvery { ownerDAO.findById(any()) } returns target

            val result = ownerService.delete(actorSub = "owner-actor", ownerId = "owner-actor")

            assertIs<OwnerLifecycleOutcome.Rejected>(result)
            assertEquals(MutationErrorCode.SELF_ACTION_FORBIDDEN, result.code)
            coVerify(exactly = 0) { ownerDAO.delete(any(), any()) }
        }

    @Test
    fun `GIVEN only one active owner WHEN delete THEN Rejected LAST_OWNER`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1")
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.listAll() } returns listOf(target)

            val result = ownerService.delete(actorSub = "owner-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Rejected>(result)
            assertEquals(MutationErrorCode.LAST_OWNER, result.code)
        }

    @Test
    fun `GIVEN two active owners WHEN delete THEN Success, provider call, audit append`() =
        runTest {
            val target = buildOwner(ownerId = "owner-1")
            coEvery { ownerDAO.findById(any()) } returns target
            coEvery { ownerDAO.listAll() } returns listOf(target, actorOwner)
            coEvery { ownerDAO.findBySub("owner-actor") } returns actorOwner
            coEvery { ownerDAO.delete(any(), any()) } returns Unit

            val auditSlot = slot<AccountDeletionLog>()
            coEvery { accountDeletionLogDAO.append(capture(auditSlot)) } returns Unit

            val result = ownerService.delete(actorSub = "owner-actor", ownerId = "owner-1")

            assertIs<OwnerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { ownerDAO.delete(target.ownerId, any()) }
            coVerify(exactly = 1) { userProvisioningPort.deleteUser("owner-1") }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountDeleted(any()) }
            assertEquals(DeletedAccountRole.OWNER, auditSlot.captured.deletedRole)
            assertEquals(actorOwner.ownerId, auditSlot.captured.actorOwnerId)
            // hash must not equal the cleartext ownerId (= sub after unification)
            assert(auditSlot.captured.deletedSubHash != "owner-1")
            // SHA-256 hash is 64 hex chars — verify we hash, not store cleartext
            assertEquals(64, auditSlot.captured.deletedSubHash.length)
        }

    // -------------------------------------------------------------------------
    // updateProfile
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN owner not found WHEN updateProfile THEN NotFound`() =
        runTest {
            coEvery { ownerDAO.findBySub(any()) } returns null

            val result =
                ownerService.updateProfile(
                    actorSub = "sub-1",
                    update = OwnerProfileUpdate("Alice", "Dupont", "alice@example.com", null),
                )

            assertIs<OwnerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { ownerDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN owner exists WHEN updateProfile THEN Success and owner row updated`() =
        runTest {
            // After unification: ownerId == sub, so use the same value.
            val owner = buildOwner(ownerId = "owner-sub-1")
            val putSlot = slot<Owner>()
            coEvery { ownerDAO.findBySub("owner-sub-1") } returns owner
            coEvery { ownerDAO.put(capture(putSlot), any()) } returns Unit

            val result =
                ownerService.updateProfile(
                    actorSub = "owner-sub-1",
                    update = OwnerProfileUpdate("Bob", "Martin", "bob@example.com", "+33600000000"),
                )

            assertIs<OwnerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { ownerDAO.put(any(), any()) }
            assertEquals("Bob", putSlot.captured.firstName)
            assertEquals("Martin", putSlot.captured.lastName)
            assertEquals("bob@example.com", putSlot.captured.email)
            assertEquals("+33600000000", putSlot.captured.phone)
            // updatedAt must be bumped
            assert(putSlot.captured.updatedAt > owner.updatedAt)
        }

    @Test
    fun `GIVEN owner exists WHEN updateProfile with null phone THEN phone cleared`() =
        runTest {
            val owner = buildOwner(ownerId = "owner-sub-1")
            val putSlot = slot<Owner>()
            coEvery { ownerDAO.findBySub("owner-sub-1") } returns owner
            coEvery { ownerDAO.put(capture(putSlot), any()) } returns Unit

            ownerService.updateProfile(
                actorSub = "owner-sub-1",
                update = OwnerProfileUpdate("Alice", "Dupont", "alice@example.com", null),
            )

            assertEquals(null, putSlot.captured.phone)
        }
}

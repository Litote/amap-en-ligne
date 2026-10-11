package core

import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.MutationErrorCode
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountStatus
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.Owner
import persistence.model.Server
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
internal class RoleServiceTest {
    private val ownerDAO = mockk<OwnerSyncDAO>()
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val memberInvitationSyncDAO = mockk<MemberInvitationSyncDAO>(relaxed = true)
    private val roleService = RoleService(ownerDAO, userProvisioningPort, memberInvitationSyncDAO)

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
        email: String? = "$id@example.org",
        accountStatus: MemberAccountStatus = MemberAccountStatus.ACTIVE,
    ): Member =
        Member(
            memberId = id.toId(),
            organizationId = orgId.toId(),
            roles = roles,
            email = email,
            accountStatus = accountStatus,
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

    // --- validateGrantOwner ---

    @Test
    fun `GIVEN user is already owner WHEN validateGrantOwner THEN OWNER_EXCLUSIVE`() =
        runTest {
            coEvery { ownerDAO.existsBySub("sub-1") } returns true

            val error = roleService.validateGrantOwner("sub-1")

            assertEquals(MutationErrorCode.OWNER_EXCLUSIVE, error)
        }

    @Test
    fun `GIVEN user has existing member rows but is not already owner WHEN validateGrantOwner THEN null`() =
        runTest {
            // Member rows are NOT a blocking condition: they are stripped atomically on promotion.
            coEvery { ownerDAO.existsBySub("sub-1") } returns false

            val error = roleService.validateGrantOwner("sub-1")

            assertNull(error)
        }

    @Test
    fun `GIVEN user has no existing row WHEN validateGrantOwner THEN null`() =
        runTest {
            coEvery { ownerDAO.existsBySub("sub-1") } returns false

            val error = roleService.validateGrantOwner("sub-1")

            assertNull(error)
        }

    // --- validateLastAdmin ---

    @Test
    fun `GIVEN target is the last admin WHEN validateLastAdmin removing admin THEN LAST_ADMIN`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val newRoles = setOf(Role.VOLUNTEER)

            val error = roleService.validateLastAdmin("member-1", newRoles, listOf(target))

            assertEquals(MutationErrorCode.LAST_ADMIN, error)
        }

    @Test
    fun `GIVEN target is admin but other admins exist WHEN validateLastAdmin removing admin THEN null`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val other = buildMember(id = "member-2", roles = setOf(Role.ADMIN))
            val newRoles = setOf(Role.VOLUNTEER)

            val error = roleService.validateLastAdmin("member-1", newRoles, listOf(target, other))

            assertNull(error)
        }

    @Test
    fun `GIVEN target keeps admin role WHEN validateLastAdmin THEN null`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val newRoles = setOf(Role.ADMIN, Role.COORDINATOR)

            val error = roleService.validateLastAdmin("member-1", newRoles, listOf(target))

            assertNull(error)
        }

    @Test
    fun `GIVEN target was not admin WHEN validateLastAdmin THEN null`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.VOLUNTEER))
            val newRoles = setOf(Role.COORDINATOR)

            val error = roleService.validateLastAdmin("member-1", newRoles, listOf(target))

            assertNull(error)
        }

    @Test
    fun `GIVEN the only other admin is a deleted account WHEN validateLastAdmin removing admin THEN LAST_ADMIN`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            // What an account deletion leaves: suspended, PII nulled, roles kept.
            val deleted =
                buildMember(id = "member-2", roles = setOf(Role.ADMIN), email = null, accountStatus = MemberAccountStatus.SUSPENDED)

            val error = roleService.validateLastAdmin("member-1", emptySet(), listOf(target, deleted))

            assertEquals(MutationErrorCode.LAST_ADMIN, error)
        }

    @Test
    fun `GIVEN the only other admin never activated their account WHEN validateLastAdmin removing admin THEN LAST_ADMIN`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            // Imported member: its account waits on a pending invitation (email case ignored).
            val imported = buildMember(id = "member-2", roles = setOf(Role.ADMIN), email = "Imported@Example.org")
            coEvery { memberInvitationSyncDAO.listByOrganizationId("org-1".toId()) } returns
                listOf(invitation("imported@example.org", MemberInvitationStatus.PENDING_ACTIVATION))

            val error = roleService.validateLastAdmin("member-1", emptySet(), listOf(target, imported))

            assertEquals(MutationErrorCode.LAST_ADMIN, error)
        }

    @Test
    fun `GIVEN the other admin activated their invitation WHEN validateLastAdmin removing admin THEN null`() =
        runTest {
            val target = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val other = buildMember(id = "member-2", roles = setOf(Role.ADMIN))
            coEvery { memberInvitationSyncDAO.listByOrganizationId("org-1".toId()) } returns
                listOf(invitation("member-2@example.org", MemberInvitationStatus.ACTIVATED))

            val error = roleService.validateLastAdmin("member-1", emptySet(), listOf(target, other))

            assertNull(error)
        }

    @Test
    fun `GIVEN the target is a never-activated admin WHEN validateLastAdmin removing admin THEN null`() =
        runTest {
            // Removing an admin who cannot log in leaves the AMAP's real admins unchanged.
            val imported = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            coEvery { memberInvitationSyncDAO.listByOrganizationId("org-1".toId()) } returns
                listOf(invitation("member-1@example.org", MemberInvitationStatus.PENDING_ACTIVATION))

            val error = roleService.validateLastAdmin("member-1", emptySet(), listOf(imported))

            assertNull(error)
        }

    private fun invitation(
        email: String,
        status: MemberInvitationStatus,
    ) = MemberInvitation(
        invitationId = "inv-$email",
        organizationId = "org-1".toId(),
        email = email,
        firstName = "Ada",
        lastName = "Lovelace",
        roles = setOf(Role.ADMIN),
        status = status,
        createdAt = Instant.fromEpochMilliseconds(1_000_000L),
        expiresAt = Instant.fromEpochMilliseconds(2_000_000L),
    )

    // --- validateLastOwner ---

    @Test
    fun `GIVEN only one active owner WHEN validateLastOwner for that owner THEN LAST_OWNER`() =
        runTest {
            val owner = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.ACTIVE)
            coEvery { ownerDAO.listAll() } returns listOf(owner)

            val error = roleService.validateLastOwner("owner-1")

            assertEquals(MutationErrorCode.LAST_OWNER, error)
        }

    @Test
    fun `GIVEN two active owners WHEN validateLastOwner for one THEN null`() =
        runTest {
            val owner1 = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.ACTIVE)
            val owner2 = buildOwner(ownerId = "owner-2", accountStatus = AccountStatus.ACTIVE)
            coEvery { ownerDAO.listAll() } returns listOf(owner1, owner2)

            val error = roleService.validateLastOwner("owner-1")

            assertNull(error)
        }

    @Test
    fun `GIVEN one active and one suspended owner WHEN validateLastOwner for active owner THEN LAST_OWNER`() =
        runTest {
            val active = buildOwner(ownerId = "owner-1", accountStatus = AccountStatus.ACTIVE)
            val suspended = buildOwner(ownerId = "owner-2", accountStatus = AccountStatus.SUSPENDED)
            coEvery { ownerDAO.listAll() } returns listOf(active, suspended)

            val error = roleService.validateLastOwner("owner-1")

            assertEquals(MutationErrorCode.LAST_OWNER, error)
        }

    // --- validateProducerExclusive ---

    @Test
    fun `GIVEN email already belongs to a producer WHEN validateProducerExclusive THEN PRODUCER_EXCLUSIVE`() =
        runTest {
            coEvery { userProvisioningPort.findProducerAccountIdByEmail("p@example.com") } returns "pa-1"

            val error = roleService.validateProducerExclusive("p@example.com")

            assertEquals(MutationErrorCode.PRODUCER_EXCLUSIVE, error)
        }

    @Test
    fun `GIVEN email is not a producer WHEN validateProducerExclusive THEN null`() =
        runTest {
            coEvery { userProvisioningPort.findProducerAccountIdByEmail("x@example.com") } returns null

            val error = roleService.validateProducerExclusive("x@example.com")

            assertNull(error)
        }

    // --- validateMixedRoles ---

    @Test
    fun `GIVEN user is already owner WHEN validateMixedRoles THEN MIXED_ROLES`() =
        runTest {
            coEvery { ownerDAO.existsBySub("sub-1") } returns true

            val error = roleService.validateMixedRoles("sub-1", "a@example.com")

            assertEquals(MutationErrorCode.MIXED_ROLES, error)
        }

    @Test
    fun `GIVEN email already belongs to a producer WHEN validateMixedRoles THEN MIXED_ROLES`() =
        runTest {
            coEvery { ownerDAO.existsBySub("sub-1") } returns false
            coEvery { userProvisioningPort.findProducerAccountIdByEmail("p@example.com") } returns "pa-1"

            val error = roleService.validateMixedRoles("sub-1", "p@example.com")

            assertEquals(MutationErrorCode.MIXED_ROLES, error)
        }

    @Test
    fun `GIVEN user is neither owner nor producer WHEN validateMixedRoles THEN null`() =
        runTest {
            coEvery { ownerDAO.existsBySub("sub-1") } returns false
            coEvery { userProvisioningPort.findProducerAccountIdByEmail("x@example.com") } returns null

            val error = roleService.validateMixedRoles("sub-1", "x@example.com")

            assertNull(error)
        }
}

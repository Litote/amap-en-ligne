@file:OptIn(ExperimentalTime::class)

package member

import authentication.AuthenticatedInfo
import authentication.Role
import core.MemberRoleProvisioningPort
import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.todayIn
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MemberPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.DeliveryReminders
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContract
import persistence.model.MemberContractStatus
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Server
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class MemberServiceTest {
    private val organizationId = "org-1"
    private val memberId = "member-1"
    private val adminAuth =
        AuthenticatedInfo(
            memberId = "caller-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = organizationId,
            roles = listOf(Role.ADMIN),
        )
    private val nonAdminAuth =
        AuthenticatedInfo(
            memberId = "caller-2",
            firstName = "Regular",
            lastName = "User",
            email = "regular@example.com",
            organizationId = organizationId,
            roles = emptyList(),
        )
    private val noOrgAuth =
        AuthenticatedInfo(
            memberId = "caller-3",
            firstName = "No",
            lastName = "Org",
            email = "noorg@example.com",
            organizationId = null,
            roles = listOf(Role.ADMIN),
        )
    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "caller-4",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            organizationId = null,
            roles = listOf(Role.OWNER),
        )
    private val volunteerAuth =
        AuthenticatedInfo(
            memberId = "volunteer-sub",
            firstName = "Volunteer",
            lastName = "User",
            email = "volunteer@example.com",
            organizationId = organizationId,
            roles = listOf(Role.VOLUNTEER),
        )

    private val ownerDAO = mockk<OwnerSyncDAO>()
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val roleService = RoleService(ownerDAO, userProvisioningPort)
    private val accountLifecycleEmailPort = mockk<AccountLifecycleEmailPort>(relaxed = true)
    private val accountDeletionLogDAO = mockk<AccountDeletionLogDAO>(relaxed = true)

    private fun buildMember(
        id: String = memberId,
        orgId: String = organizationId,
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

    private fun buildMutation(member: Member): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(MemberPayload(member)),
        )

    private val contractSyncDAO = mockk<ContractSyncDAO>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)

    private fun buildService(
        memberSyncDAO: MemberSyncDAO,
        roleProvisioningPort: MemberRoleProvisioningPort? = null,
        contractDAO: ContractSyncDAO = contractSyncDAO,
        orgDAO: OrganizationSyncDAO = organizationSyncDAO,
    ): MemberService =
        MemberService(
            memberSyncDAO = memberSyncDAO,
            roleService = roleService,
            roleProvisioningPort = roleProvisioningPort,
            userProvisioningPort = userProvisioningPort,
            accountLifecycleEmailPort = accountLifecycleEmailPort,
            accountDeletionLogDAO = accountDeletionLogDAO,
            contractSyncDAO = contractDAO,
            organizationSyncDAO = orgDAO,
        )

    private fun buildDeleteMutation(memberId: String): ClientMutation =
        ClientMutation(
            clientOpId = "op-del-1",
            op = Delete(EntityType.Member, memberId),
        )

    @Test
    fun `GIVEN caller without organization id WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val member = buildMember()

            val outcome = service.applyUpsert(noOrgAuth, buildMutation(member), MemberPayload(member))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.getByOrganizationId(any()) }
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN organization id mismatch WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val member = buildMember(orgId = "other-org")

            val outcome = service.applyUpsert(adminAuth, buildMutation(member), MemberPayload(member))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.getByOrganizationId(any()) }
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN non-admin caller changing roles WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)

            val outcome = service.applyUpsert(nonAdminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller adding ADMIN role WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller removing ADMIN role with other admins remaining WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val targetMember = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val otherAdmin = buildMember(id = "member-2", roles = setOf(Role.ADMIN))
            val updatedTarget = targetMember.copy(roles = setOf(Role.VOLUNTEER))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(targetMember, otherAdmin)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedTarget), MemberPayload(updatedTarget))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller removing ADMIN role as the last admin WHEN upsert THEN REJECTED LAST_ADMIN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val targetMember = buildMember(id = "member-1", roles = setOf(Role.ADMIN))
            val updatedTarget = targetMember.copy(roles = setOf(Role.VOLUNTEER))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(targetMember)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedTarget), MemberPayload(updatedTarget))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.LAST_ADMIN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN non-admin caller editing their own member without changing roles WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // nonAdminAuth.memberId = "caller-2"; use same id as the member so it is a self-edit
            val existing = buildMember(id = "caller-2", roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(activeStatus = false)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(nonAdminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller changing roles WHEN upsert THEN roleProvisioningPort updateRoles is called with correct args`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val roleProvisioningPort = mockk<MemberRoleProvisioningPort>()
            val service = buildService(memberSyncDAO, roleProvisioningPort)
            val existing = buildMember(roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit
            coEvery { roleProvisioningPort.updateRoles(any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                roleProvisioningPort.updateRoles(
                    memberId = existing.memberId.id,
                    oldRoles = setOf(Role.VOLUNTEER),
                    newRoles = setOf(Role.ADMIN),
                )
            }
        }

    @Test
    fun `GIVEN OWNER caller adding member to any org WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val member = buildMember(orgId = "any-org", roles = setOf(Role.VOLUNTEER))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(member), MemberPayload(member))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER caller adding member whose email is already a producer WHEN upsert THEN REJECTED MIXED_ROLES`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // After sub/id unification, MIXED_ROLES for new members is checked by email only.
            val member =
                buildMember(id = "tmp_new", orgId = "any-org", roles = setOf(Role.VOLUNTEER))
                    .copy(email = "prod@example.com")
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { userProvisioningPort.findProducerAccountIdByEmail("prod@example.com") } returns "pa-1"

            val outcome = service.applyUpsert(ownerAuth, buildMutation(member), MemberPayload(member))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.MIXED_ROLES, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER upserting ACTIVE-to-SUSPENDED on existing member WHEN member exists THEN delegates to suspend`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // memberId == sub by convention: use "sub-target" as the memberId
            val existing = buildMember(id = "sub-target")
            val updated = existing.copy(accountStatus = MemberAccountStatus.SUSPENDED)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)
            coEvery { memberSyncDAO.setActiveStatusBySub(any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.setActiveStatusBySub("sub-target", false, any()) }
            coVerify(exactly = 1) { userProvisioningPort.banUser("sub-target") }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountSuspended(any()) }
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER upserting SUSPENDED-to-ACTIVE on existing member WHEN member exists THEN delegates to reactivate`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing =
                buildMember(id = "sub-target")
                    .copy(activeStatus = false, accountStatus = MemberAccountStatus.SUSPENDED)
            val updated = existing.copy(accountStatus = MemberAccountStatus.ACTIVE)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)
            coEvery { memberSyncDAO.setActiveStatusBySub(any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.setActiveStatusBySub("sub-target", true, any()) }
            coVerify(exactly = 1) { userProvisioningPort.unbanUser("sub-target") }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountReactivated(any()) }
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER suspend transition WHEN target is last admin THEN MutationOutcome carries LAST_ADMIN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(id = "sub-target", roles = setOf(Role.ADMIN))
            val updated = existing.copy(accountStatus = MemberAccountStatus.SUSPENDED)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.LAST_ADMIN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER suspend transition WHEN target memberId equals OWNER sub THEN MutationOutcome carries SELF_ACTION_FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // ownerAuth.memberId == "caller-4"; set existing.memberId to same value
            val existing = buildMember(id = "caller-4")
            val updated = existing.copy(accountStatus = MemberAccountStatus.SUSPENDED)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.SELF_ACTION_FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN OWNER upserting existing member WHEN no status transition THEN does not delegate`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(id = "sub-target")
            val updated = existing.copy(accountStatus = MemberAccountStatus.ACTIVE)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { memberSyncDAO.getMembersBySub(any()) }
            coVerify(exactly = 0) { memberSyncDAO.setActiveStatusBySub(any(), any(), any()) }
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN OWNER deletes member WHEN service wired THEN anonymises memberships and deletes auth user`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // memberId == sub by convention
            val existing = buildMember(id = "sub-target")
            coEvery { memberSyncDAO.listAll() } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit

            val outcome = service.applyDelete(ownerAuth, buildDeleteMutation("sub-target"), Delete(EntityType.Member, "sub-target"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.anonymiseBySub("sub-target", any()) }
            coVerify(exactly = 1) { userProvisioningPort.deleteUser("sub-target") }
            coVerify(exactly = 1) { accountDeletionLogDAO.append(any()) }
            coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN OWNER delete WHEN target is last admin THEN MutationOutcome carries LAST_ADMIN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(id = "sub-target", roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.listAll() } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)

            val outcome = service.applyDelete(ownerAuth, buildDeleteMutation("sub-target"), Delete(EntityType.Member, "sub-target"))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.LAST_ADMIN, outcome.error?.code)
        }

    @Test
    fun `GIVEN volunteer caller upserts another member WHEN memberId differs from caller sub THEN REJECTED FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // volunteerAuth.memberId = "volunteer-sub"; target member has a different id
            val otherMember = buildMember(id = "other-member-sub", roles = setOf(Role.VOLUNTEER))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(otherMember)

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(otherMember), MemberPayload(otherMember))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller upserts their own member WHEN memberId equals caller sub THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // volunteerAuth.memberId = "volunteer-sub"; own member uses same id
            val ownMember = buildMember(id = "volunteer-sub", roles = setOf(Role.VOLUNTEER))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(ownMember)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(ownMember), MemberPayload(ownMember))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    // ---- Contract ended guard via Member.contracts (CONTRACT_ENDED) ----

    @Test
    fun `GIVEN member upsert adding contract entry for ended contract THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            val existing = buildMember()
            val endedContract =
                Contract(
                    contractId = "contract-ended".toId(),
                    name = "Test contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = kotlinx.datetime.LocalDate(2024, 1, 1),
                    maxDeliveryDate = pastDate,
                    deliveryCount = 10,
                    seasonYear = 2024,
                )
            val updated =
                existing.copy(
                    contracts =
                        listOf(
                            MemberContract(
                                contractId = "contract-ended".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                            ),
                        ),
                )
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { contractDAO.getByOrganizationId(any()) } returns listOf(endedContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN member upsert flipping existing entry to CANCELLED on ended contract THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            val existingContract =
                MemberContract(
                    contractId = "contract-ended".toId(),
                    subscriptionInstant = Instant.fromEpochMilliseconds(0),
                    status = MemberContractStatus.ACTIVE,
                )
            val existing = buildMember().copy(contracts = listOf(existingContract))
            val updated = existing.copy(contracts = listOf(existingContract.copy(status = MemberContractStatus.CANCELLED)))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit
            // contractDAO is not called because no new contract ids are added

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { contractDAO.getByOrganizationId(any()) }
        }

    @Test
    fun `GIVEN member upsert without contract changes THEN no contract DAO call`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val service = buildService(memberSyncDAO, contractDAO = contractDAO)
            val existing = buildMember()
            val updated = existing.copy(firstName = "Updated")
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { contractDAO.getByOrganizationId(any()) }
        }

    // ---- IN_PREPARATION guard ----

    @Test
    fun `GIVEN contract IN_PREPARATION WHEN non-privileged member self-subscribes THEN REJECTED FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            // volunteerAuth.memberId = "volunteer-sub"; own member uses same id
            val existing = buildMember(id = "volunteer-sub", roles = setOf(Role.VOLUNTEER))
            val inPreparationContract =
                Contract(
                    contractId = "contract-prep".toId(),
                    name = "Future contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = kotlinx.datetime.LocalDate(2099, 1, 1),
                    maxDeliveryDate = kotlinx.datetime.LocalDate(2099, 12, 31),
                    deliveryCount = 10,
                    seasonYear = 2099,
                    status = ContractStatus.IN_PREPARATION,
                )
            val updated =
                existing.copy(
                    contracts =
                        listOf(
                            MemberContract(
                                contractId = "contract-prep".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                            ),
                        ),
                )
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { contractDAO.getByOrganizationId(any()) } returns listOf(inPreparationContract)

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract IN_PREPARATION WHEN coordinator self-subscribes THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val coordinatorAuth =
                AuthenticatedInfo(
                    memberId = "coordinator-sub",
                    firstName = "Coordinator",
                    lastName = "User",
                    email = "coord@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.COORDINATOR),
                )
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            // coordinator edits their own member profile (memberId matches auth.memberId)
            val coordinatorMember = buildMember(id = "coordinator-sub", roles = setOf(Role.COORDINATOR))
            val inPreparationContract =
                Contract(
                    contractId = "contract-prep".toId(),
                    name = "Future contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = kotlinx.datetime.LocalDate(2099, 1, 1),
                    maxDeliveryDate = kotlinx.datetime.LocalDate(2099, 12, 31),
                    deliveryCount = 10,
                    seasonYear = 2099,
                    status = ContractStatus.IN_PREPARATION,
                )
            val updated =
                coordinatorMember.copy(
                    contracts =
                        listOf(
                            MemberContract(
                                contractId = "contract-prep".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                            ),
                        ),
                )
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(coordinatorMember)
            coEvery { contractDAO.getByOrganizationId(any()) } returns listOf(inPreparationContract)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract ENDED manual WHEN non-privileged member self-subscribes THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val contractDAO = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            // volunteerAuth.memberId = "volunteer-sub"
            val existing = buildMember(id = "volunteer-sub", roles = setOf(Role.VOLUNTEER))
            val manuallyEndedContract =
                Contract(
                    contractId = "contract-ended-manual".toId(),
                    name = "Ended contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = kotlinx.datetime.LocalDate(2099, 1, 1),
                    maxDeliveryDate = kotlinx.datetime.LocalDate(2099, 12, 31),
                    deliveryCount = 10,
                    seasonYear = 2099,
                    status = ContractStatus.ENDED,
                )
            val updated =
                existing.copy(
                    contracts =
                        listOf(
                            MemberContract(
                                contractId = "contract-ended-manual".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                            ),
                        ),
                )
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { contractDAO.getByOrganizationId(any()) } returns listOf(manuallyEndedContract)

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }
}

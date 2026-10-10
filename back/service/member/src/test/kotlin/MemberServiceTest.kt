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
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.todayIn
import persistence.changes.Change
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MemberPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.ActivationTokenDAO
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.DeletionActorRole
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContract
import persistence.model.MemberContractStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.Organization
import persistence.model.Server
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
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
    private val memberInvitationSyncDAO = mockk<MemberInvitationSyncDAO>(relaxed = true)
    private val basketExchangeSyncDAO = mockk<BasketExchangeSyncDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)

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
            memberInvitationSyncDAO = memberInvitationSyncDAO,
            basketExchangeSyncDAO = basketExchangeSyncDAO,
            activationTokenDAO = activationTokenDAO,
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
    fun `GIVEN a client payload with another or no registration date WHEN upsert THEN the stored date is kept`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val registeredAt = Instant.fromEpochMilliseconds(1_790_000_000_000L)
            val existing = buildMember(id = "caller-2").copy(registeredAt = registeredAt)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            val persisted = mutableListOf<Member>()
            coEvery { memberSyncDAO.put(capture(persisted), any()) } returns Unit

            listOf(null, Instant.fromEpochMilliseconds(0L)).forEach { forged ->
                val edited = existing.copy(firstName = "Claude", registeredAt = forged)
                service.applyUpsert(nonAdminAuth, buildMutation(edited), MemberPayload(edited))
            }

            assertEquals(listOf(registeredAt, registeredAt), persisted.map { it.registeredAt })
        }

    @Test
    fun `GIVEN a member created with a tmp id WHEN upsert THEN the server sets its registration date`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            val persisted = slot<Member>()
            coEvery { memberSyncDAO.put(capture(persisted), any()) } returns Unit
            val created = buildMember(id = "tmp_member").copy(registeredAt = Instant.fromEpochMilliseconds(0L))

            val before = Clock.System.now()
            service.applyUpsert(adminAuth, buildMutation(created), MemberPayload(created))

            val registeredAt = assertNotNull(persisted.captured.registeredAt)
            assertTrue(registeredAt >= before)
        }

    @Test
    fun `GIVEN non-admin caller editing their own member without changing roles WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            // nonAdminAuth.memberId = "caller-2"; use same id as the member so it is a self-edit
            val existing = buildMember(id = "caller-2", roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(accountStatus = MemberAccountStatus.SUSPENDED)
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
            coEvery { memberSyncDAO.setAccountStatusBySub(any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.setAccountStatusBySub("sub-target", MemberAccountStatus.SUSPENDED, any()) }
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
                    .copy(accountStatus = MemberAccountStatus.SUSPENDED)
            val updated = existing.copy(accountStatus = MemberAccountStatus.ACTIVE)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.getMembersBySub("sub-target") } returns listOf(existing)
            coEvery { memberSyncDAO.setAccountStatusBySub(any(), any(), any()) } returns Unit

            val outcome = service.applyUpsert(ownerAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.setAccountStatusBySub("sub-target", MemberAccountStatus.ACTIVE, any()) }
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
            coVerify(exactly = 0) { memberSyncDAO.setAccountStatusBySub(any(), any(), any()) }
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
            coVerify(exactly = 1) {
                accountDeletionLogDAO.append(
                    match { it.actorId == ownerAuth.memberId && it.actorRole == DeletionActorRole.OWNER },
                )
            }
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

    @Test
    fun `GIVEN member profile edits breaking the form rules WHEN upsert THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember().copy(firstName = "Alice", lastName = "Martin", email = "alice@example.com")
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            val invalid =
                listOf(
                    existing.copy(firstName = " "),
                    existing.copy(lastName = ""),
                    existing.copy(email = "alice@example"),
                    existing.copy(roles = emptySet()),
                    existing.copy(phone = "abc<script>"),
                    // The email is the login identity: changing it would desynchronize
                    // the auth account, so it is immutable once set.
                    existing.copy(email = "other@example.com"),
                )

            invalid.forEach { updated ->
                val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

                assertEquals(MutationStatus.REJECTED, outcome.status, "expected rejection for $updated")
                assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            }
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN a legacy member without names WHEN an unrelated field is upserted THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember(roles = setOf(Role.VOLUNTEER))
            val updated = existing.copy(roles = setOf(Role.VOLUNTEER, Role.COORDINATOR))
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a member email differing only by case WHEN upsert THEN APPLIED`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val existing = buildMember().copy(firstName = "Alice", lastName = "Martin", email = "alice@example.com")
            val updated = existing.copy(email = "Alice@Example.com", phone = "06 12 34 56 78")
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(existing)
            coEvery { memberSyncDAO.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updated), MemberPayload(updated))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    // ── Delete authorization ────────────────────────────────────────────────

    private val coordinatorAuth = volunteerAuth.copy(memberId = "coordinator-sub", roles = listOf(Role.COORDINATOR, Role.VOLUNTEER))

    @Test
    fun `GIVEN non-admin callers WHEN deleting another member THEN REJECTED FORBIDDEN and nothing is written`() =
        runTest {
            listOf(volunteerAuth, coordinatorAuth, nonAdminAuth).forEach { caller ->
                val memberSyncDAO = mockk<MemberSyncDAO>()
                val service = buildService(memberSyncDAO)
                coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(buildMember(id = "target-sub"))

                val outcome =
                    service.applyDelete(caller, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

                assertEquals(MutationStatus.REJECTED, outcome.status, "caller ${caller.roles}")
                assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code, "caller ${caller.roles}")
                coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
                coVerify(exactly = 0) { memberSyncDAO.anonymiseBySub(any(), any()) }
            }
        }

    @Test
    fun `GIVEN ADMIN WHEN deleting an account-backed member of the org THEN anonymises it and deletes the auth user`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val target = buildMember(id = "target-sub")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.anonymiseBySub("target-sub", any()) }
            coVerify(exactly = 1) { userProvisioningPort.deleteUser("target-sub") }
            coVerify(exactly = 1) {
                accountDeletionLogDAO.append(
                    match { it.actorId == adminAuth.memberId && it.actorRole == DeletionActorRole.ADMIN },
                )
            }
            coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN a deleted member WHEN their settled invitation carries their identity THEN it is anonymised`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val target = buildMember(id = "target-sub").copy(email = "Target@Example.org", firstName = "Ada", lastName = "Lovelace")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit

            fun invitation(
                id: String,
                email: String,
                status: MemberInvitationStatus,
            ) = MemberInvitation(
                invitationId = id,
                organizationId = organizationId.toId(),
                email = email,
                firstName = "Ada",
                lastName = "Lovelace",
                roles = setOf(Role.VOLUNTEER),
                status = status,
                createdAt = Instant.fromEpochMilliseconds(1_000_000L),
                expiresAt = Instant.fromEpochMilliseconds(2_000_000L),
                customEmailSubject = "Bonjour Ada",
            )
            val activated = invitation("inv-activated", "target@example.org", MemberInvitationStatus.ACTIVATED)
            // A new pending invitation is a fresh, legitimate request: kept.
            val pending = invitation("inv-pending", "target@example.org", MemberInvitationStatus.PENDING_ACTIVATION)
            val someoneElse = invitation("inv-other", "other@example.org", MemberInvitationStatus.ACTIVATED)
            coEvery { memberInvitationSyncDAO.listByOrganizationId(organizationId.toId()) } returns listOf(activated, pending, someoneElse)
            val written = mutableListOf<MemberInvitation>()
            val changes = mutableListOf<List<Change>>()
            coEvery { memberInvitationSyncDAO.put(capture(written), capture(changes)) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(
                listOf(activated.copy(email = "", firstName = "", lastName = "", customEmailSubject = null, customEmailBody = null)),
                written,
            )
            assertEquals(
                setOf("organization:$organizationId", "instance-owner"),
                changes.single().map { it.scopeKey }.toSet(),
            )
            // Its activation tokens keep no email either; the pending invitation's are untouched.
            coVerify(exactly = 1) { activationTokenDAO.anonymiseByMemberInvitationId("inv-activated".toId()) }
            coVerify(exactly = 0) { activationTokenDAO.anonymiseByMemberInvitationId("inv-pending".toId()) }
        }

    @Test
    fun `GIVEN a deleted member registered on an upcoming delivery WHEN deleted THEN the organization is written without them`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, orgDAO = orgDAO)
            val target = buildMember(id = "target-sub")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit
            val upcoming =
                Delivery(
                    deliveryId = "delivery-next".toId(),
                    organizationId = organizationId.toId(),
                    scheduledDate = LocalDateTime.parse("2099-01-15T19:00:00"),
                    status = DeliveryStatus.PLANNED,
                    minVolunteersRequired = 2,
                    contracts =
                        listOf(
                            DeliveryContract(
                                contractId = "contract-1".toId(),
                                coordinators = listOf("target-sub".toId()),
                                basketQuantity = 10,
                                deliveryDescription = "Légumes",
                                status = DeliveryContractStatus.PENDING,
                            ),
                        ),
                )
            val stored =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "AMAP",
                    contactEmail = "amap@example.org",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Instant.fromEpochMilliseconds(0),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
                    deliveries = listOf(upcoming),
                )
            coEvery { orgDAO.getById(organizationId.toId()) } returns stored
            val written = slot<Organization>()
            val change = slot<Change>()
            coEvery { orgDAO.put(capture(written), capture(change), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(
                emptyList(),
                written.captured.deliveries
                    .single()
                    .contracts
                    .single()
                    .coordinators,
            )
            assertEquals("organization:$organizationId", change.captured.scopeKey)
        }

    @Test
    fun `GIVEN a deleted member absent from every delivery WHEN deleted THEN the organization is not rewritten`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, orgDAO = orgDAO)
            val target = buildMember(id = "target-sub")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit
            coEvery { orgDAO.getById(organizationId.toId()) } returns
                Organization(
                    organizationId = organizationId.toId(),
                    name = "AMAP",
                    contactEmail = "amap@example.org",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Instant.fromEpochMilliseconds(0),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
                )

            service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            coVerify(exactly = 0) { orgDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN an open basket exchange offer of a deleted member WHEN deleted THEN it is cancelled on the organization scope`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val target = buildMember(id = "target-sub")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit
            val open =
                BasketExchange(
                    basketExchangeId = "exchange-1".toId(),
                    organizationId = organizationId.toId(),
                    deliveryId = "delivery-1".toId(),
                    contractId = "contract-1".toId(),
                    offeringMemberId = "target-sub".toId(),
                    status = BasketExchangeStatus.OPEN,
                    createdAt = Instant.fromEpochMilliseconds(1_000L),
                )
            val settled = open.copy(basketExchangeId = "exchange-2".toId(), status = BasketExchangeStatus.ACCEPTED)
            coEvery { basketExchangeSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(open, settled)
            val written = mutableListOf<BasketExchange>()
            val changes = mutableListOf<Change>()
            coEvery { basketExchangeSyncDAO.put(capture(written), capture(changes)) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(listOf("exchange-1" to BasketExchangeStatus.CANCELLED), written.map { it.basketExchangeId.id to it.status })
            assertEquals("organization:$organizationId", changes.single().scopeKey)
        }

    @Test
    fun `GIVEN a deleted member subscribed to a running contract WHEN deleted THEN the subscription is cancelled`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val contractDAO = mockk<ContractSyncDAO>(relaxed = true)
            val service = buildService(memberSyncDAO, contractDAO = contractDAO, orgDAO = orgDAO)
            val target = buildMember(id = "target-sub")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.getMembersBySub("target-sub") } returns listOf(target)
            coEvery { memberSyncDAO.anonymiseBySub(any(), any()) } returns Unit
            coEvery { orgDAO.getById(organizationId.toId()) } returns
                Organization(
                    organizationId = organizationId.toId(),
                    name = "AMAP",
                    contactEmail = "amap@example.org",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Instant.fromEpochMilliseconds(0),
                    lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
                )
            val running =
                Contract(
                    contractId = "contract-1".toId(),
                    name = "Légumes",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = LocalDate.parse("2026-01-01"),
                    maxDeliveryDate = LocalDate.parse("2099-12-31"),
                    deliveryCount = 10,
                    seasonYear = 2026,
                    status = ContractStatus.ACTIVE,
                    members =
                        listOf(
                            ContractMember(
                                memberId = "target-sub".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(1_000L),
                                status = MemberContractStatus.ACTIVE,
                            ),
                        ),
                )
            coEvery { contractDAO.getByOrganizationId(organizationId.toId()) } returns listOf(running)
            val written = slot<Contract>()
            val change = slot<Change>()
            coEvery { contractDAO.put(capture(written), capture(change), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("target-sub"), Delete(EntityType.Member, "target-sub"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(
                MemberContractStatus.CANCELLED,
                written.captured.members
                    .single()
                    .status,
            )
            assertEquals("organization:$organizationId", change.captured.scopeKey)
        }

    @Test
    fun `GIVEN ADMIN WHEN deleting a never-synced tmp member THEN the row is hard-deleted`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val target = buildMember(id = "tmp_member")
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, target)
            coEvery { memberSyncDAO.delete(any(), any(), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, buildDeleteMutation("tmp_member"), Delete(EntityType.Member, "tmp_member"))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { memberSyncDAO.delete("tmp_member".toId(), organizationId.toId(), any()) }
            coVerify(exactly = 0) { userProvisioningPort.deleteUser(any()) }
        }

    @Test
    fun `GIVEN ADMIN WHEN deleting a member of another organization THEN REJECTED NOT_FOUND`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin)

            val outcome =
                service.applyDelete(adminAuth, buildDeleteMutation("other-org-member"), Delete(EntityType.Member, "other-org-member"))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
            coVerify(exactly = 0) { memberSyncDAO.anonymiseBySub(any(), any()) }
        }

    @Test
    fun `GIVEN ADMIN WHEN deleting their own member row THEN REJECTED SELF_ACTION_FORBIDDEN`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val service = buildService(memberSyncDAO)
            val admin = buildMember(id = adminAuth.memberId, roles = setOf(Role.ADMIN))
            val otherAdmin = buildMember(id = "other-admin", roles = setOf(Role.ADMIN))
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(admin, otherAdmin)

            val outcome =
                service.applyDelete(adminAuth, buildDeleteMutation(adminAuth.memberId), Delete(EntityType.Member, adminAuth.memberId))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.SELF_ACTION_FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
            coVerify(exactly = 0) { memberSyncDAO.anonymiseBySub(any(), any()) }
        }
}

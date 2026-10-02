@file:OptIn(ExperimentalTime::class)

package activation

import authentication.Role
import core.UserProvisioningPort
import id.generateId
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.coVerifyOrder
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.changes.Change
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ServerDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.ActivityType
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContract
import persistence.model.MemberContractStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerOrganization
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import persistence.model.RegistrationStatus
import persistence.model.Server
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class ActivationServiceTest {
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val organizationRequestDAO = mockk<OrganizationRequestDAO>(relaxed = true)
    private val producerRequestDAO = mockk<ProducerRequestDAO>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val serverDAO = mockk<ServerDAO>(relaxed = true)
    private val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val memberInvitationDAO = mockk<MemberInvitationSyncDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val ownerInvitationDAO = mockk<OwnerInvitationSyncDAO>(relaxed = true)
    private val ownerDAO = mockk<OwnerSyncDAO>(relaxed = true)
    private val contractSyncDAO = mockk<ContractSyncDAO>(relaxed = true)
    private val basketExchangeSyncDAO = mockk<BasketExchangeSyncDAO>(relaxed = true)

    private val service =
        ActivationService(
            activationTokenDAO = activationTokenDAO,
            organizationRequestDAO = organizationRequestDAO,
            producerRequestDAO = producerRequestDAO,
            organizationSyncDAO = organizationSyncDAO,
            serverDAO = serverDAO,
            producerAccountSyncDAO = producerAccountSyncDAO,
            producerSyncDAO = mockk(relaxed = true),
            userProvisioningPort = userProvisioningPort,
            memberInvitationDAO = memberInvitationDAO,
            memberSyncDAO = memberSyncDAO,
            ownerInvitationDAO = ownerInvitationDAO,
            ownerDAO = ownerDAO,
            contractSyncDAO = contractSyncDAO,
            basketExchangeSyncDAO = basketExchangeSyncDAO,
        )

    private fun buildOrganizationAdminToken(
        activated: Boolean = false,
        expired: Boolean = false,
    ): ActivationToken {
        val now = Clock.System.now()
        val organizationId = generateId<Organization>()
        return ActivationToken(
            token = "tok-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.ORGANIZATION_ADMIN,
            requestId = generateId(),
            adminEmail = "admin@example.com",
            organizationId = organizationId,
            createdAt = now,
            expiresAt = if (expired) now - 1.seconds else now + 72.hours,
            activatedAt = if (activated) now - 1.hours else null,
        )
    }

    private fun buildOwnerToken(
        activated: Boolean = false,
        expired: Boolean = false,
    ): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-owner-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.OWNER,
            ownerInvitationId = generateId<OwnerInvitation>(),
            adminEmail = "owner@example.com",
            createdAt = now,
            expiresAt = if (expired) now - 1.seconds else now + 168.hours,
            activatedAt = if (activated) now - 1.hours else null,
        )
    }

    private fun buildProducerToken(
        activated: Boolean = false,
        expired: Boolean = false,
    ): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-producer-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.PRODUCER,
            producerRequestId = generateId<ProducerRequest>(),
            adminEmail = "producer@example.com",
            producerAccountId = generateId<ProducerAccount>(),
            createdAt = now,
            expiresAt = if (expired) now - 1.seconds else now + 72.hours,
            activatedAt = if (activated) now - 1.hours else null,
        )
    }

    private fun buildMemberToken(
        activated: Boolean = false,
        expired: Boolean = false,
        invalidated: Boolean = false,
    ): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-member-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.MEMBER,
            memberInvitationId = generateId<MemberInvitation>(),
            adminEmail = "member@example.com",
            createdAt = now,
            expiresAt = if (expired) now - 1.seconds else now + 168.hours,
            invalidatedAt = if (invalidated) now - 1.hours else null,
            activatedAt = if (activated) now - 1.hours else null,
        )
    }

    private fun buildRequest(requestId: id.Id<OrganizationRequest>): OrganizationRequest {
        val now = Clock.System.now()
        return OrganizationRequest(
            requestId = requestId,
            organizationName = "AMAP Test",
            organizationType = OrganizationType.AMAP,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            adminFirstName = "Alice",
            adminLastName = "Martin",
            adminEmail = "admin@example.com",
            status = OrganizationRequestStatus.APPROVED,
            submittedAt = now,
        )
    }

    private fun buildOwnerInvitation(invitationId: id.Id<OwnerInvitation>): OwnerInvitation {
        val now = Clock.System.now()
        return OwnerInvitation(
            invitationId = invitationId,
            firstName = "Bob",
            lastName = "Dupont",
            email = "owner@example.com",
            status = OwnerInvitationStatus.PENDING_ACTIVATION,
            submittedAt = now,
        )
    }

    private fun buildProducerRequest(requestId: id.Id<ProducerRequest>): ProducerRequest {
        val now = Clock.System.now()
        return ProducerRequest(
            requestId = requestId,
            producerName = "Ferme Test",
            adminFirstName = "Alice",
            adminLastName = "Martin",
            adminEmail = "producer@example.com",
            status = ProducerRequestStatus.APPROVED,
            submittedAt = now,
        )
    }

    private fun buildMemberInvitation(invitationId: id.Id<MemberInvitation>): MemberInvitation {
        val now = Clock.System.now()
        return MemberInvitation(
            invitationId = invitationId.id,
            organizationId = "org-1".toId(),
            email = "member@example.com",
            firstName = "Jane",
            lastName = "Doe",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = now,
            expiresAt = now + 168.hours,
        )
    }

    @Test
    fun `GIVEN valid ORGANIZATION_ADMIN token WHEN activate THEN creates admin user`() =
        runTest {
            val token = buildOrganizationAdminToken()
            val request = buildRequest(token.requestId!!)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { organizationRequestDAO.findById(token.requestId!!) } returns request
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))
            coEvery { userProvisioningPort.createAdminUser(any(), any()) } returns "admin-sub-123"

            val result = service.activate(token.token, "password123")

            assertIs<ActivationOutcome.Success>(result)
            coVerify { userProvisioningPort.createAdminUser(token.adminEmail, "password123") }
        }

    @Test
    fun `GIVEN valid ORGANIZATION_ADMIN token WHEN activate THEN creates Member with role ADMIN and correct sub`() =
        runTest {
            val token = buildOrganizationAdminToken()
            val request = buildRequest(token.requestId!!)
            val organization =
                Organization(
                    organizationId = token.organizationId!!,
                    name = request.organizationName,
                    contactEmail = token.adminEmail,
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Clock.System.now(),
                    lastUpdatedInstant = Clock.System.now(),
                )
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { organizationRequestDAO.findById(token.requestId!!) } returns request
            coEvery { organizationSyncDAO.getById(token.organizationId!!) } returns organization
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))
            coEvery { userProvisioningPort.createAdminUser(any(), any()) } returns "admin-sub-123"

            val result = service.activate(token.token, "password123")

            assertIs<ActivationOutcome.Success>(result)
            coVerify {
                memberSyncDAO.put(
                    match { member ->
                        member.memberId.id == "admin-sub-123" &&
                            member.roles == setOf(Role.ADMIN) &&
                            member.organizationId == token.organizationId!! &&
                            member.accountStatus == MemberAccountStatus.ACTIVE &&
                            member.email == token.adminEmail &&
                            member.firstName == request.adminFirstName &&
                            member.lastName == request.adminLastName &&
                            member.registeredAt != null
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN valid OWNER token WHEN activate THEN creates owner user and sync-updates invitation`() =
        runTest {
            val token = buildOwnerToken()
            val invitation = buildOwnerInvitation(token.ownerInvitationId!!)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { ownerInvitationDAO.findById(token.ownerInvitationId!!) } returns invitation
            coEvery { userProvisioningPort.createOwnerUser(any(), any(), any(), any()) } returns "owner-sub-123"

            val result = service.activate(token.token, "password456")

            assertIs<ActivationOutcome.Success>(result)
            coVerify { ownerDAO.put(any(), any()) }
            coVerify { ownerInvitationDAO.put(match { it.status == OwnerInvitationStatus.ACTIVATED }, any()) }
            coVerify { activationTokenDAO.markActivated(token.token, any()) }
        }

    @Test
    fun `GIVEN valid PRODUCER token WHEN activate THEN creates producer user`() =
        runTest {
            val token = buildProducerToken()
            val request = buildProducerRequest(token.producerRequestId!!)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { producerRequestDAO.findById(token.producerRequestId!!) } returns request
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))

            val result = service.activate(token.token, "password456")

            assertIs<ActivationOutcome.Success>(result)
            coVerify {
                userProvisioningPort.createProducerUser(
                    email = token.adminEmail,
                    password = "password456",
                    firstName = request.adminFirstName,
                    lastName = request.adminLastName,
                )
            }
            coVerify { activationTokenDAO.markActivated(token.token, any()) }
        }

    @Test
    fun `GIVEN valid PRODUCER token WHEN describe THEN returns account info without side effects`() =
        runTest {
            val token = buildProducerToken()
            val request = buildProducerRequest(token.producerRequestId!!)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { producerRequestDAO.findById(token.producerRequestId!!) } returns request

            val result = service.describe(token.token)

            val success = assertIs<ActivationOutcome.Success>(result)
            assertEquals(ActivationKind.PRODUCER, success.response.kind)
            assertEquals(token.adminEmail, success.response.email)
            assertEquals(request.producerName, success.response.organizationName)
            coVerify(exactly = 0) { userProvisioningPort.createProducerUser(any(), any(), any(), any()) }
            coVerify(exactly = 0) { activationTokenDAO.markActivated(any(), any()) }
        }

    @Test
    fun `GIVEN expired or activated token WHEN describe THEN mirrors activate outcomes`() =
        runTest {
            val expired = buildProducerToken(expired = true)
            val activated = buildProducerToken(activated = true)
            coEvery { activationTokenDAO.findByToken(expired.token) } returns expired
            coEvery { activationTokenDAO.findByToken(activated.token) } returns activated
            coEvery { activationTokenDAO.findByToken("unknown") } returns null

            assertIs<ActivationOutcome.Expired>(service.describe(expired.token))
            assertIs<ActivationOutcome.AlreadyActivated>(service.describe(activated.token))
            assertIs<ActivationOutcome.NotFound>(service.describe("unknown"))
        }

    @Test
    fun `GIVEN producer pending activation WHEN activate THEN pending flag is cleared with an instance-owner change`() =
        runTest {
            val token = buildProducerToken()
            val request = buildProducerRequest(token.producerRequestId!!)
            val producerAccount =
                ProducerAccount(
                    producerAccountId = token.producerAccountId!!,
                    name = request.producerName,
                    contactEmail = token.adminEmail,
                    activeStatus = true,
                    createdInstant = Clock.System.now(),
                    lastUpdatedInstant = Clock.System.now(),
                    organizations =
                        listOf(
                            ProducerOrganization(
                                organizationId = "org-1".toId(),
                                associationInstant = Clock.System.now(),
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                    pendingActivation = true,
                )
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { producerRequestDAO.findById(token.producerRequestId!!) } returns request
            coEvery { producerAccountSyncDAO.findById(token.producerAccountId!!) } returns producerAccount
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))

            val result = service.activate(token.token, "password456")

            assertIs<ActivationOutcome.Success>(result)
            val changesSlot = slot<List<Change>>()
            coVerify {
                producerAccountSyncDAO.updatePendingActivation(token.producerAccountId!!, false, capture(changesSlot))
            }
            val scopes = changesSlot.captured.map { it.scopeKey }.toSet()
            assertEquals(setOf(SyncScope.InstanceOwner.key, SyncScope.Organization("org-1").key), scopes)
            changesSlot.captured.forEach { change ->
                val payload = change.payload as ProducerAccountPayload
                assertEquals(false, payload.producerAccount.pendingActivation)
            }
        }

    @Test
    fun `GIVEN valid MEMBER token WHEN activate THEN creates auth user member row and sync-updates invitation`() =
        runTest {
            val token = buildMemberToken()
            val invitation = buildMemberInvitation(token.memberInvitationId!!)
            val organization =
                Organization(
                    organizationId = invitation.organizationId,
                    name = "Org 1",
                    contactEmail = "org@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Clock.System.now(),
                    lastUpdatedInstant = Clock.System.now(),
                )
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { memberInvitationDAO.findById(token.memberInvitationId!!.id) } returns invitation
            coEvery { organizationSyncDAO.getById(invitation.organizationId) } returns organization
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))
            coEvery {
                userProvisioningPort.createMemberUser(
                    email = invitation.email,
                    password = "password789",
                    firstName = invitation.firstName,
                    lastName = invitation.lastName,
                    organizationId = invitation.organizationId.id,
                    roles = invitation.roles,
                )
            } returns "member-sub-1"

            val result = service.activate(token.token, "password789")

            assertIs<ActivationOutcome.Success>(result)
            coVerify { memberSyncDAO.put(match { it.registeredAt != null }, any()) }
            coVerify { memberInvitationDAO.put(match { it.status == MemberInvitationStatus.ACTIVATED }, any()) }
            coVerify { activationTokenDAO.markActivated(token.token, any()) }
        }

    @Test
    fun `GIVEN a member imported without account WHEN its invitation is activated THEN the imported row is re-keyed to the new sub`() =
        runTest {
            val token = buildMemberToken()
            val invitation = buildMemberInvitation(token.memberInvitationId!!)
            val epoch = Instant.fromEpochMilliseconds(0)
            val importedId = "imported-1".toId<Member>()
            val imported =
                Member(
                    memberId = importedId,
                    organizationId = invitation.organizationId,
                    roles = setOf(Role.VOLUNTEER),
                    firstName = "Jane",
                    lastName = "Doe",
                    // Letter case differs from the invitation email.
                    email = "Member@Example.com",
                    phone = "06 12 34 56 78",
                    contracts = listOf(MemberContract("contract-1".toId(), epoch, MemberContractStatus.ACTIVE)),
                    memberPreferences = MemberPreferences(true, true, epoch),
                    userPreferences = UserPreferences(true, false, epoch),
                    userSettings = UserSettings("fr", TimeZone.of("Europe/Paris"), "default".toId(), epoch),
                )
            val contract =
                Contract(
                    contractId = "contract-1".toId(),
                    name = "Légumes",
                    organizationId = invitation.organizationId,
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = LocalDate.parse("2026-01-01"),
                    maxDeliveryDate = LocalDate.parse("2026-12-31"),
                    deliveryCount = 40,
                    seasonYear = 2026,
                    members = listOf(ContractMember(importedId, epoch, MemberContractStatus.ACTIVE)),
                )
            val unrelatedContract = contract.copy(contractId = "contract-2".toId(), members = emptyList())
            val organization =
                Organization(
                    organizationId = invitation.organizationId,
                    name = "Org 1",
                    contactEmail = "org@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = epoch,
                    lastUpdatedInstant = epoch,
                    deliveries =
                        listOf(
                            Delivery(
                                deliveryId = "delivery-1".toId(),
                                organizationId = invitation.organizationId,
                                scheduledDate = LocalDateTime.parse("2026-03-01T18:00"),
                                status = DeliveryStatus.COMPLETED,
                                minVolunteersRequired = 1,
                                contracts =
                                    listOf(
                                        DeliveryContract(
                                            contractId = "contract-1".toId(),
                                            basketQuantity = 10,
                                            deliveryDescription = "Légumes",
                                            status = DeliveryContractStatus.DISTRIBUTED,
                                            slots =
                                                listOf(
                                                    MemberSlot(
                                                        startTime = LocalDateTime.parse("2026-03-01T18:00"),
                                                        endTime = LocalDateTime.parse("2026-03-01T20:00"),
                                                        activityType = ActivityType.DISTRIBUTION,
                                                        requiredVolunteers = 1,
                                                        currentRegistrations = 1,
                                                        status = SlotStatus.CLOSED,
                                                        registrations =
                                                            listOf(
                                                                MemberRegistration(
                                                                    importedId,
                                                                    "Jane Doe",
                                                                    "member@example.com",
                                                                    epoch,
                                                                    RegistrationStatus.CONFIRMED,
                                                                ),
                                                            ),
                                                    ),
                                                ),
                                        ),
                                    ),
                            ),
                        ),
                )
            val exchange =
                BasketExchange(
                    basketExchangeId = "exchange-1".toId(),
                    organizationId = invitation.organizationId,
                    deliveryId = "delivery-1".toId(),
                    contractId = "contract-1".toId(),
                    offeringMemberId = importedId,
                    status = BasketExchangeStatus.OPEN,
                    createdAt = epoch,
                )
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { memberInvitationDAO.findById(token.memberInvitationId!!.id) } returns invitation
            coEvery { organizationSyncDAO.getById(invitation.organizationId) } returns organization
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))
            coEvery { userProvisioningPort.createMemberUser(any(), any(), any(), any(), any(), any()) } returns "member-sub-1"
            coEvery { memberSyncDAO.getByOrganizationId(invitation.organizationId) } returns listOf(imported)
            coEvery { contractSyncDAO.getByOrganizationId(invitation.organizationId) } returns listOf(contract, unrelatedContract)
            coEvery { basketExchangeSyncDAO.getByOrganizationId(invitation.organizationId) } returns listOf(exchange)

            val result = service.activate(token.token, "password789")

            assertIs<ActivationOutcome.Success>(result)
            val newId = "member-sub-1".toId<Member>()
            val activated = slot<Member>()
            coVerifyOrder {
                memberSyncDAO.put(capture(activated), any())
                memberSyncDAO.delete(importedId, invitation.organizationId, any())
            }
            assertEquals(newId, activated.captured.memberId)
            assertEquals(imported.contracts, activated.captured.contracts)
            assertEquals("06 12 34 56 78", activated.captured.phone)
            assertEquals(invitation.roles, activated.captured.roles)
            assertEquals(MemberAccountStatus.ACTIVE, activated.captured.accountStatus)
            assertEquals("server-1".toId(), activated.captured.userSettings.serverId)
            assertTrue(activated.captured.registeredAt != null)
            coVerify(exactly = 1) {
                contractSyncDAO.put(match { it.contractId.id == "contract-1" && it.members.single().memberId == newId }, any(), any())
            }
            coVerify(exactly = 0) { contractSyncDAO.put(match { it.contractId.id == "contract-2" }, any(), any()) }
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        org.deliveries
                            .single()
                            .contracts
                            .single()
                            .slots
                            .single()
                            .registrations
                            .single()
                            .memberId == newId
                    },
                    any(),
                    any(),
                )
            }
            coVerify(exactly = 1) { basketExchangeSyncDAO.put(match { it.offeringMemberId == newId }, any()) }
        }

    @Test
    fun `GIVEN no imported member with the invitation email WHEN activate THEN no member row is deleted`() =
        runTest {
            val token = buildMemberToken()
            val invitation = buildMemberInvitation(token.memberInvitationId!!)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token
            coEvery { memberInvitationDAO.findById(token.memberInvitationId!!.id) } returns invitation
            coEvery { organizationSyncDAO.getById(invitation.organizationId) } returns
                Organization(
                    organizationId = invitation.organizationId,
                    name = "Org 1",
                    contactEmail = "org@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = Clock.System.now(),
                    lastUpdatedInstant = Clock.System.now(),
                )
            coEvery { serverDAO.list() } returns listOf(Server("server-1".toId(), "Test", "https://example.com"))
            coEvery { userProvisioningPort.createMemberUser(any(), any(), any(), any(), any(), any()) } returns "member-sub-1"
            coEvery { memberSyncDAO.getByOrganizationId(invitation.organizationId) } returns emptyList()

            val result = service.activate(token.token, "password789")

            assertIs<ActivationOutcome.Success>(result)
            coVerify(exactly = 1) { memberSyncDAO.put(match { it.memberId.id == "member-sub-1" }, any()) }
            coVerify(exactly = 0) { memberSyncDAO.delete(any(), any(), any()) }
            coVerify(exactly = 0) { contractSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN invalidated MEMBER token WHEN activate THEN NotFound`() =
        runTest {
            val token = buildMemberToken(invalidated = true)
            coEvery { activationTokenDAO.findByToken(token.token) } returns token

            val result = service.activate(token.token, "password789")

            assertIs<ActivationOutcome.NotFound>(result)
        }
}

@file:OptIn(ExperimentalTime::class)

package activation

import authentication.Role
import core.UserProvisioningPort
import id.generateId
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.dao.ActivationTokenDAO
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
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import persistence.model.Server
import kotlin.test.Test
import kotlin.test.assertIs
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds
import kotlin.time.ExperimentalTime

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
                            member.lastName == request.adminLastName
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
            coVerify { memberSyncDAO.put(any(), any()) }
            coVerify { memberInvitationDAO.put(match { it.status == MemberInvitationStatus.ACTIVATED }, any()) }
            coVerify { activationTokenDAO.markActivated(token.token, any()) }
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

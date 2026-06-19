@file:OptIn(ExperimentalTime::class)

package onboarding

import authentication.Role
import email.MemberJoinRequestNotificationEmailPort
import email.OrganizationRequestNotificationEmailPort
import email.ProducerRequestNotificationEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import notificationpublisher.NotificationPublisher
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.dao.ServerDAO
import persistence.model.AccessibilityOptions
import persistence.model.AccountStatus
import persistence.model.CreateMemberJoinRequestBody
import persistence.model.CreateOrganizationRequestBody
import persistence.model.CreateProducerRequestBody
import persistence.model.DeliveryReminders
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationType
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import persistence.model.Owner
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerRequestStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
internal class PublicServiceTest {
    private val organizationDAO = mockk<OrganizationDAO>(relaxed = true)
    private val serverDAO = mockk<ServerDAO>(relaxed = true)
    private val organizationRequestDAO = mockk<OrganizationRequestDAO>(relaxed = true)
    private val organizationRequestSyncDAO = mockk<OrganizationRequestSyncDAO>(relaxed = true)
    private val producerRequestDAO = mockk<ProducerRequestDAO>(relaxed = true)
    private val producerRequestSyncDAO = mockk<ProducerRequestSyncDAO>(relaxed = true)
    private val memberJoinRequestDAO = mockk<MemberJoinRequestDAO>(relaxed = true)
    private val memberJoinRequestSyncDAO = mockk<MemberJoinRequestSyncDAO>(relaxed = true)
    private val memberJoinRequestNotificationEmailPort = mockk<MemberJoinRequestNotificationEmailPort>(relaxed = true)
    private val organizationRequestNotificationEmailPort = mockk<OrganizationRequestNotificationEmailPort>(relaxed = true)
    private val producerRequestNotificationEmailPort = mockk<ProducerRequestNotificationEmailPort>(relaxed = true)
    private val notificationPublisher = mockk<NotificationPublisher>(relaxed = true)
    private val ownerDAO = mockk<OwnerSyncDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val service =
        PublicService(
            organizationDAO,
            serverDAO,
            organizationRequestDAO,
            organizationRequestSyncDAO,
            producerRequestDAO,
            producerRequestSyncDAO,
            memberJoinRequestDAO,
            memberJoinRequestSyncDAO,
            memberJoinRequestNotificationEmailPort,
            organizationRequestNotificationEmailPort,
            producerRequestNotificationEmailPort,
            notificationPublisher,
            ownerDAO,
            memberSyncDAO,
            producerAccountSyncDAO,
            organizationSyncDAO,
        )

    private val validBody =
        CreateOrganizationRequestBody(
            organizationName = "AMAP des Collines",
            organizationType = OrganizationType.AMAP,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean@example.com",
        )

    private val validProducerBody =
        CreateProducerRequestBody(
            producerName = "Ferme des Collines",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean@example.com",
        )

    @Test
    fun `GIVEN new organization request WHEN createOrganizationRequest THEN put called on syncDAO with Change`() =
        runTest {
            coEvery { organizationRequestDAO.existsByOrganizationName(any(), any()) } returns null
            coEvery { organizationRequestDAO.existsByAdminEmail(any(), any()) } returns null

            val outcome = service.createOrganizationRequest(validBody)

            assertTrue(outcome is CreateOrganizationOutcome.Success)
            coVerify { organizationRequestSyncDAO.put(any(), any()) }
            coVerify(exactly = 0) { organizationRequestDAO.create(any()) }
            coVerify { organizationRequestNotificationEmailPort.notifyOwners(any()) }
        }

    @Test
    fun `GIVEN duplicate organization name WHEN createOrganizationRequest THEN returns Conflict and no syncDAO call`() =
        runTest {
            coEvery {
                organizationRequestDAO.existsByOrganizationName(validBody.organizationName, any())
            } returns OrganizationRequestStatus.PENDING_VALIDATION

            val outcome = service.createOrganizationRequest(validBody)

            assertEquals(CreateOrganizationOutcome.Conflict("organization_name", OrganizationRequestStatus.PENDING_VALIDATION), outcome)
            coVerify(exactly = 0) { organizationRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN duplicate admin email WHEN createOrganizationRequest THEN returns Conflict and no syncDAO call`() =
        runTest {
            coEvery { organizationRequestDAO.existsByOrganizationName(any(), any()) } returns null
            coEvery {
                organizationRequestDAO.existsByAdminEmail(validBody.adminEmail, any())
            } returns OrganizationRequestStatus.PENDING_VALIDATION

            val outcome = service.createOrganizationRequest(validBody)

            assertEquals(CreateOrganizationOutcome.Conflict("admin_email", OrganizationRequestStatus.PENDING_VALIDATION), outcome)
            coVerify(exactly = 0) { organizationRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN new member join request WHEN createMemberJoinRequest THEN put called on syncDAO with Change`() =
        runTest {
            coEvery { memberJoinRequestDAO.existsPendingByEmailAndOrganization(any(), any()) } returns false

            val outcome =
                service.createMemberJoinRequest(
                    CreateMemberJoinRequestBody(
                        organizationId = "org-1",
                        email = "alice@example.com",
                        firstName = "Alice",
                        lastName = "Martin",
                    ),
                )

            assertTrue(outcome is CreateMemberJoinOutcome.Success)
            coVerify { memberJoinRequestSyncDAO.put(any(), any()) }
            coVerify(exactly = 0) { memberJoinRequestDAO.create(any()) }
            coVerify { memberJoinRequestNotificationEmailPort.notifyAdmins(any(), any()) }
        }

    @Test
    fun `GIVEN duplicate member join request email WHEN createMemberJoinRequest THEN returns Conflict and no syncDAO call`() =
        runTest {
            coEvery { memberJoinRequestDAO.existsPendingByEmailAndOrganization(any(), any()) } returns true

            val outcome =
                service.createMemberJoinRequest(
                    CreateMemberJoinRequestBody(
                        organizationId = "org-1",
                        email = "alice@example.com",
                        firstName = "Alice",
                        lastName = "Martin",
                    ),
                )

            assertEquals(CreateMemberJoinOutcome.Conflict("email"), outcome)
            coVerify(exactly = 0) { memberJoinRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN new producer request WHEN createProducerRequest THEN put called on syncDAO with Change`() =
        runTest {
            coEvery { producerRequestDAO.existsByProducerName(any(), any()) } returns null
            coEvery { producerRequestDAO.existsByAdminEmail(any(), any()) } returns null

            val outcome = service.createProducerRequest(validProducerBody)

            assertTrue(outcome is CreateProducerOutcome.Success)
            coVerify { producerRequestSyncDAO.put(any(), any()) }
            coVerify(exactly = 0) { producerRequestDAO.create(any()) }
            coVerify { producerRequestNotificationEmailPort.notifyOwners(any()) }
        }

    @Test
    fun `GIVEN duplicate producer name WHEN createProducerRequest THEN returns Conflict and no syncDAO call`() =
        runTest {
            coEvery {
                producerRequestDAO.existsByProducerName(validProducerBody.producerName, any())
            } returns ProducerRequestStatus.PENDING_VALIDATION

            val outcome = service.createProducerRequest(validProducerBody)

            assertEquals(CreateProducerOutcome.Conflict("producer_name", ProducerRequestStatus.PENDING_VALIDATION), outcome)
            coVerify(exactly = 0) { producerRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN duplicate producer admin email WHEN createProducerRequest THEN returns Conflict and no syncDAO call`() =
        runTest {
            coEvery { producerRequestDAO.existsByProducerName(any(), any()) } returns null
            coEvery {
                producerRequestDAO.existsByAdminEmail(validProducerBody.adminEmail, any())
            } returns ProducerRequestStatus.PENDING_VALIDATION

            val outcome = service.createProducerRequest(validProducerBody)

            assertEquals(CreateProducerOutcome.Conflict("admin_email", ProducerRequestStatus.PENDING_VALIDATION), outcome)
            coVerify(exactly = 0) { producerRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN previously rejected org request WHEN createOrganizationRequest with same email THEN returns Success`() =
        runTest {
            coEvery { organizationRequestDAO.existsByOrganizationName(any(), any()) } returns null
            coEvery { organizationRequestDAO.existsByAdminEmail(any(), any()) } returns null

            val outcome = service.createOrganizationRequest(validBody)

            assertTrue(outcome is CreateOrganizationOutcome.Success)
        }

    @Test
    fun `GIVEN submitter comment WHEN createOrganizationRequest THEN request has the comment`() =
        runTest {
            coEvery { organizationRequestDAO.existsByOrganizationName(any(), any()) } returns null
            coEvery { organizationRequestDAO.existsByAdminEmail(any(), any()) } returns null

            val bodyWithComment = validBody.copy(submitterComment = "Je gère une AMAP depuis 2018")
            val outcome = service.createOrganizationRequest(bodyWithComment)

            assertTrue(outcome is CreateOrganizationOutcome.Success)
            coVerify {
                organizationRequestSyncDAO.put(
                    match { it.submitterComment == "Je gère une AMAP depuis 2018" },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN previously rejected producer request WHEN createProducerRequest with same email THEN returns Success`() =
        runTest {
            coEvery { producerRequestDAO.existsByProducerName(any(), any()) } returns null
            coEvery { producerRequestDAO.existsByAdminEmail(any(), any()) } returns null

            val outcome = service.createProducerRequest(validProducerBody)

            assertTrue(outcome is CreateProducerOutcome.Success)
        }

    @Test
    fun `GIVEN active owners WHEN createOrganizationRequest THEN notifies each owner via NotificationPublisher`() =
        runTest {
            val owner = buildOwner(sub = "sub-1", pushEnabled = true)
            coEvery { organizationRequestDAO.existsByOrganizationName(any(), any()) } returns null
            coEvery { organizationRequestDAO.existsByAdminEmail(any(), any()) } returns null
            coEvery { ownerDAO.listAll() } returns listOf(owner)

            service.createOrganizationRequest(validBody)

            coVerify {
                notificationPublisher.publish(
                    recipientScope = "owner:sub-1",
                    type = NotificationType.INFO,
                    category = NotificationCategory.ORGANIZATION_REQUEST_SUBMITTED,
                    content = any(),
                    channels = setOf(NotificationChannel.PUSH),
                )
            }
        }

    @Test
    fun `GIVEN active owners WHEN createProducerRequest THEN notifies each owner via NotificationPublisher`() =
        runTest {
            val owner = buildOwner(sub = "sub-1", pushEnabled = false)
            coEvery { producerRequestDAO.existsByProducerName(any(), any()) } returns null
            coEvery { producerRequestDAO.existsByAdminEmail(any(), any()) } returns null
            coEvery { ownerDAO.listAll() } returns listOf(owner)

            service.createProducerRequest(validProducerBody)

            coVerify {
                notificationPublisher.publish(
                    recipientScope = "owner:sub-1",
                    type = NotificationType.INFO,
                    category = NotificationCategory.PRODUCER_REQUEST_SUBMITTED,
                    content = any(),
                    channels = emptySet(),
                )
            }
        }

    @Test
    fun `GIVEN active admin WHEN createMemberJoinRequest THEN notifies admin via NotificationPublisher`() =
        runTest {
            val admin = buildMember(sub = "sub-admin", role = Role.ADMIN, pushEnabled = true)
            coEvery { memberJoinRequestDAO.existsPendingByEmailAndOrganization(any(), any()) } returns false
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns listOf(admin)

            service.createMemberJoinRequest(
                CreateMemberJoinRequestBody(
                    organizationId = "org-1",
                    email = "alice@example.com",
                    firstName = "Alice",
                    lastName = "Martin",
                ),
            )

            coVerify {
                notificationPublisher.publish(
                    recipientScope = "member:sub-admin",
                    type = NotificationType.INFO,
                    category = NotificationCategory.MEMBER_JOIN_REQUEST_SUBMITTED,
                    content = any(),
                    channels = setOf(NotificationChannel.PUSH),
                )
            }
        }

    @Test
    fun `GIVEN active member with same email WHEN createMemberJoinRequest THEN returns Conflict email_member`() =
        runTest {
            val activeMember =
                buildMember(sub = "sub-member", role = Role.VOLUNTEER, pushEnabled = false).copy(
                    email = "alice@example.com",
                    accountStatus = MemberAccountStatus.ACTIVE,
                )
            coEvery { memberSyncDAO.listAll() } returns listOf(activeMember)

            val outcome =
                service.createMemberJoinRequest(
                    CreateMemberJoinRequestBody(
                        organizationId = "org-1",
                        email = "alice@example.com",
                        firstName = "Alice",
                        lastName = "Martin",
                    ),
                )

            assertEquals(CreateMemberJoinOutcome.Conflict("email_member"), outcome)
            coVerify(exactly = 0) { memberJoinRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN owner with same email WHEN createMemberJoinRequest THEN returns Conflict email_owner`() =
        runTest {
            coEvery { memberSyncDAO.listAll() } returns emptyList()
            coEvery { ownerDAO.existsByEmail("alice@example.com") } returns true

            val outcome =
                service.createMemberJoinRequest(
                    CreateMemberJoinRequestBody(
                        organizationId = "org-1",
                        email = "alice@example.com",
                        firstName = "Alice",
                        lastName = "Martin",
                    ),
                )

            assertEquals(CreateMemberJoinOutcome.Conflict("email_owner"), outcome)
            coVerify(exactly = 0) { memberJoinRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN active producer account with same email WHEN createMemberJoinRequest THEN returns Conflict email_producer`() =
        runTest {
            val activeProducer = buildProducerAccount(contactEmail = "alice@example.com", activeStatus = true)
            coEvery { memberSyncDAO.listAll() } returns emptyList()
            coEvery { ownerDAO.existsByEmail(any()) } returns false
            coEvery { producerAccountSyncDAO.listAll() } returns listOf(activeProducer)

            val outcome =
                service.createMemberJoinRequest(
                    CreateMemberJoinRequestBody(
                        organizationId = "org-1",
                        email = "alice@example.com",
                        firstName = "Alice",
                        lastName = "Martin",
                    ),
                )

            assertEquals(CreateMemberJoinOutcome.Conflict("email_producer"), outcome)
            coVerify(exactly = 0) { memberJoinRequestSyncDAO.put(any(), any()) }
        }

    private fun buildProducerAccount(
        contactEmail: String?,
        activeStatus: Boolean,
    ): ProducerAccount {
        val now = Instant.fromEpochMilliseconds(0L)
        return ProducerAccount(
            producerAccountId = "producer-1".toId(),
            name = "Ferme des Collines",
            contactEmail = contactEmail,
            activeStatus = activeStatus,
            managementMode = ProducerManagementMode.ACCOUNT_BACKED,
            createdInstant = now,
            lastUpdatedInstant = now,
        )
    }

    private fun buildOwner(
        sub: String,
        pushEnabled: Boolean,
    ): Owner {
        val now = Instant.fromEpochMilliseconds(0L)
        // After sub/id unification: ownerId == sub.
        return Owner(
            ownerId = sub.toId(),
            firstName = "Alice",
            lastName = "Durand",
            email = "alice@example.com",
            accountStatus = AccountStatus.ACTIVE,
            registeredAt = now,
            updatedAt = now,
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = pushEnabled,
                    lastUpdatedInstant = now,
                ),
        )
    }

    private fun buildMember(
        sub: String,
        role: Role,
        pushEnabled: Boolean,
    ): Member {
        val now = Instant.fromEpochMilliseconds(0L)
        // After sub/id unification: memberId == sub.
        return Member(
            memberId = sub.toId(),
            organizationId = "org-1".toId(),
            roles = setOf(role),
            activeStatus = true,
            accountStatus = MemberAccountStatus.ACTIVE,
            memberSettings =
                MemberSettings(
                    deliveryReminders = DeliveryReminders(daysBefore = 1, reminderTime = "08:00"),
                    accessibilityOptions = AccessibilityOptions(highContrast = false, largeText = false, screenReader = false),
                    lastUpdatedInstant = now,
                ),
            memberPreferences =
                MemberPreferences(
                    deliveryRemindersEnabled = true,
                    volunteerAlertsEnabled = true,
                    lastUpdatedInstant = now,
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = pushEnabled,
                    lastUpdatedInstant = now,
                ),
            userSettings =
                UserSettings(
                    language = "fr",
                    timezone = TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId(),
                    lastUpdatedInstant = now,
                ),
        )
    }
}

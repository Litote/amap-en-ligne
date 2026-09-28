@file:OptIn(ExperimentalTime::class)

package volunteershortage

import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import notificationpublisher.NotificationPublisher
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.SentAlertDAO
import persistence.model.ActivityType
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class VolunteerShortageServiceTest {
    private val organizationId = "org-1"
    private val deliveryId = "delivery-1"
    private val mainContractId = "contract-main"
    private val secondaryContractId = "contract-eggs"
    private val longAgo = Instant.parse("2026-01-01T00:00:00Z")

    // 2026-10-15T18:30 Europe/Paris (CEST, UTC+2) = 16:30Z.
    private val deliveryDate = LocalDateTime.parse("2026-10-15T18:30:00")
    private val urgentDueAt = Instant.parse("2026-10-14T16:30:00Z")
    private val shortageDueAt = Instant.parse("2026-10-12T16:30:00Z")

    private val organizationSyncDAO = mockk<OrganizationSyncDAO>()
    private val contractSyncDAO = mockk<ContractSyncDAO>()
    private val memberSyncDAO = mockk<MemberSyncDAO>()
    private val memberInvitationSyncDAO = mockk<MemberInvitationSyncDAO>()
    private val notificationPublisher = mockk<NotificationPublisher>(relaxed = true)
    private val sentAlertDAO = InMemorySentAlertDAO()

    private val service =
        VolunteerShortageService(
            organizationSyncDAO,
            contractSyncDAO,
            memberSyncDAO,
            memberInvitationSyncDAO,
            sentAlertDAO,
            notificationPublisher,
        )

    @BeforeEach
    fun setUp() {
        coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(contract(mainContractId, isMain = true))
        coEvery { memberInvitationSyncDAO.listByOrganizationId(organizationId.toId()) } returns emptyList()
    }

    private fun givenOrganization(
        delivery: Delivery = delivery(),
        activeStatus: Boolean = true,
        overrides: Map<NotificationCategory, NotificationCopyOverride> = emptyMap(),
    ) {
        coEvery { organizationSyncDAO.listAll() } returns
            listOf(
                Organization(
                    organizationId = organizationId.toId(),
                    name = "AMAP des Collines",
                    contactEmail = "contact@example.com",
                    activeStatus = activeStatus,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = longAgo,
                    lastUpdatedInstant = longAgo,
                    deliveries = listOf(delivery),
                    notificationOverrides = overrides,
                ),
            )
    }

    private fun givenMembers(vararg members: Member) {
        coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns members.toList()
    }

    private fun delivery(
        scheduledDate: LocalDateTime = deliveryDate,
        status: DeliveryStatus = DeliveryStatus.CONFIRMED,
        contracts: List<DeliveryContract> = listOf(deliveryContract(mainContractId)),
    ): Delivery =
        Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = organizationId.toId(),
            scheduledDate = scheduledDate,
            status = status,
            minVolunteersRequired = 2,
            contracts = contracts,
        )

    private fun deliveryContract(
        contractId: String,
        slots: List<MemberSlot> = listOf(slot()),
        coordinators: List<String> = listOf("coordinator-1"),
    ): DeliveryContract =
        DeliveryContract(
            contractId = contractId.toId(),
            coordinators = coordinators.map { it.toId() },
            basketQuantity = 10,
            deliveryDescription = "Weekly basket",
            status = DeliveryContractStatus.PENDING,
            slots = slots,
        )

    private fun slot(
        requiredVolunteers: Int = 2,
        registrations: List<MemberRegistration> = emptyList(),
        status: SlotStatus = SlotStatus.OPEN,
    ): MemberSlot =
        MemberSlot(
            slotId = "slot-${registrations.size}-$requiredVolunteers",
            startTime = deliveryDate,
            endTime = LocalDateTime.parse("2026-10-15T20:00:00"),
            activityType = ActivityType.RECEPTION,
            requiredVolunteers = requiredVolunteers,
            currentRegistrations = registrations.size,
            status = status,
            slotKind = SlotKind.STANDARD,
            registrations = registrations,
        )

    private fun registration(
        memberId: String,
        status: RegistrationStatus = RegistrationStatus.REGISTERED,
    ): MemberRegistration =
        MemberRegistration(
            memberId = memberId.toId(),
            displayName = memberId,
            memberEmail = "$memberId@example.com",
            registrationInstant = longAgo,
            status = status,
        )

    private fun contract(
        contractId: String,
        isMain: Boolean = false,
        status: ContractStatus = ContractStatus.ACTIVE,
    ): Contract =
        Contract(
            contractId = contractId.toId(),
            name = contractId,
            organizationId = organizationId.toId(),
            producerAccountId = "pa-1".toId(),
            minDeliveryDate = LocalDate.parse("2026-01-01"),
            maxDeliveryDate = LocalDate.parse("2026-12-31"),
            deliveryCount = 40,
            seasonYear = 2026,
            status = status,
            isMainContract = isMain,
        )

    private fun member(
        memberId: String,
        shortage: Boolean = true,
        urgent: Boolean = true,
        accountStatus: MemberAccountStatus = MemberAccountStatus.ACTIVE,
    ): Member =
        Member(
            memberId = memberId.toId(),
            organizationId = organizationId.toId(),
            email = "$memberId@example.com",
            accountStatus = accountStatus,
            memberPreferences =
                MemberPreferences(
                    deliveryRemindersEnabled = true,
                    volunteerAlertsEnabled = true,
                    lastUpdatedInstant = longAgo,
                    urgentNeedAlertsEnabled = urgent,
                    incompleteSlotRemindersEnabled = shortage,
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = longAgo,
                ),
            userSettings =
                UserSettings(
                    language = "fr",
                    timezone = TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId(),
                    lastUpdatedInstant = longAgo,
                ),
        )

    private fun verifyAlerted(
        memberId: String,
        category: NotificationCategory,
        times: Int = 1,
    ) {
        coVerify(exactly = times) {
            notificationPublisher.publish(
                recipientScope = "member:$memberId",
                type = any(),
                category = category,
                content = any(),
                contact = any(),
                channels = any(),
            )
        }
    }

    private fun verifyNoAlert() {
        coVerify(exactly = 0) { notificationPublisher.publish(any(), any(), any(), any(), any(), any()) }
    }

    @Test
    fun `GIVEN an understaffed delivery tomorrow WHEN the urgent due time passes THEN opted-in members get an urgent alert`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"), member("m2", urgent = false))

            service.run(urgentDueAt + 1.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
            verifyAlerted("m2", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 0)
            coVerify(exactly = 0) {
                notificationPublisher.publish(any(), any(), NotificationCategory.VOLUNTEER_SHORTAGE, any(), any(), any())
            }
        }

    @Test
    fun `GIVEN an understaffed delivery in three days WHEN the shortage due time passes THEN opted-in members get a shortage alert`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"), member("m2", shortage = false))

            service.run(shortageDueAt + 1.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_SHORTAGE)
            verifyAlerted("m2", NotificationCategory.VOLUNTEER_SHORTAGE, times = 0)
        }

    @Test
    fun `GIVEN the job already ran WHEN it runs again within the lookback THEN no alert is sent twice`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)
            service.run(urgentDueAt + 15.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 1)
        }

    @Test
    fun `GIVEN a due time older than the lookback WHEN the job runs THEN the alert is dropped`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"))

            service.run(urgentDueAt + 31.minutes, lookback = 30.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN a tick delayed within the lookback WHEN the job runs THEN the alert is still sent`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"))

            service.run(urgentDueAt + 29.minutes, lookback = 30.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
        }

    @Test
    fun `GIVEN a due time not reached yet WHEN the job runs THEN no alert`() =
        runTest {
            givenOrganization()
            givenMembers(member("m1"))

            service.run(urgentDueAt - 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN a delivery right after a DST change WHEN the job runs THEN the due time uses the organization offset`() =
        runTest {
            // 2026-10-26T18:30 Europe/Paris is CET (UTC+1) = 17:30Z; urgent due 2026-10-25T17:30Z.
            givenOrganization(delivery = delivery(scheduledDate = LocalDateTime.parse("2026-10-26T18:30:00")))
            givenMembers(member("m1"))

            service.run(Instant.parse("2026-10-25T16:40:00Z"))
            verifyNoAlert()

            service.run(Instant.parse("2026-10-25T17:40:00Z"))
            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
        }

    @Test
    fun `GIVEN a fully staffed delivery WHEN the job runs THEN no alert`() =
        runTest {
            val slot = slot(requiredVolunteers = 2, registrations = listOf(registration("v1"), registration("v2")))
            givenOrganization(delivery = delivery(contracts = listOf(deliveryContract(mainContractId, slots = listOf(slot)))))
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN registered members and coordinators WHEN the job runs THEN they are not alerted and coordinators do not count`() =
        runTest {
            // Two places: one taken by the coordinator (does not count), one by v1 ⇒ still 1 missing.
            val slot =
                slot(
                    requiredVolunteers = 2,
                    registrations = listOf(registration("coordinator-1"), registration("v1")),
                )
            givenOrganization(delivery = delivery(contracts = listOf(deliveryContract(mainContractId, slots = listOf(slot)))))
            givenMembers(member("v1"), member("coordinator-1"), member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
            verifyAlerted("v1", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 0)
            verifyAlerted("coordinator-1", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 0)
        }

    @Test
    fun `GIVEN a cancelled registration WHEN the job runs THEN it frees the place and its member is alerted`() =
        runTest {
            val slot = slot(requiredVolunteers = 1, registrations = listOf(registration("v1", RegistrationStatus.CANCELLED)))
            givenOrganization(delivery = delivery(contracts = listOf(deliveryContract(mainContractId, slots = listOf(slot)))))
            givenMembers(member("v1"))

            service.run(urgentDueAt + 1.minutes)

            verifyAlerted("v1", NotificationCategory.VOLUNTEER_URGENT_NEED)
        }

    @Test
    fun `GIVEN only secondary contract slots are understaffed WHEN the job runs THEN no alert`() =
        runTest {
            val staffed = slot(requiredVolunteers = 1, registrations = listOf(registration("v1")))
            givenOrganization(
                delivery =
                    delivery(
                        contracts =
                            listOf(
                                deliveryContract(mainContractId, slots = listOf(staffed)),
                                deliveryContract(secondaryContractId, slots = listOf(slot(requiredVolunteers = 3))),
                            ),
                    ),
            )
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(contract(mainContractId, isMain = true), contract(secondaryContractId))
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN a cancelled slot WHEN the job runs THEN it does not count toward the need`() =
        runTest {
            givenOrganization(
                delivery =
                    delivery(
                        contracts = listOf(deliveryContract(mainContractId, slots = listOf(slot(status = SlotStatus.CANCELLED)))),
                    ),
            )
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN a cancelled delivery WHEN the job runs THEN no alert`() =
        runTest {
            givenOrganization(delivery = delivery(status = DeliveryStatus.CANCELLED))
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN a delivery whose contracts are all in preparation WHEN the job runs THEN no alert`() =
        runTest {
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(contract(mainContractId, isMain = true, status = ContractStatus.IN_PREPARATION))
            givenOrganization()
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN an inactive organization WHEN the job runs THEN no alert`() =
        runTest {
            givenOrganization(activeStatus = false)
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyNoAlert()
        }

    @Test
    fun `GIVEN suspended or not yet activated members WHEN the job runs THEN they are not alerted`() =
        runTest {
            coEvery { memberInvitationSyncDAO.listByOrganizationId(organizationId.toId()) } returns
                listOf(
                    MemberInvitation(
                        invitationId = "inv-1",
                        organizationId = organizationId.toId(),
                        email = "PENDING@example.com",
                        firstName = "P",
                        lastName = "P",
                        roles = emptySet(),
                        status = MemberInvitationStatus.PENDING_ACTIVATION,
                        createdAt = longAgo,
                        expiresAt = longAgo + 24.hours,
                    ),
                )
            givenOrganization()
            givenMembers(member("suspended", accountStatus = MemberAccountStatus.SUSPENDED), member("pending"), member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
            verifyAlerted("suspended", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 0)
            verifyAlerted("pending", NotificationCategory.VOLUNTEER_URGENT_NEED, times = 0)
        }

    @Test
    fun `GIVEN an admin override WHEN the job runs THEN the overridden copy is used`() =
        runTest {
            givenOrganization(
                overrides = mapOf(NotificationCategory.VOLUNTEER_URGENT_NEED to NotificationCopyOverride(title = "À l'aide !")),
            )
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            coVerify(exactly = 1) {
                notificationPublisher.publish(
                    recipientScope = "member:m1",
                    type = any(),
                    category = NotificationCategory.VOLUNTEER_URGENT_NEED,
                    content =
                        match {
                            it.title == "À l'aide !" &&
                                it.body == "La livraison du 15 octobre 2026 manque encore de 2 bénévoles. Pouvez-vous aider ?" &&
                                it.deepLink == "/planning" &&
                                it.relatedEntityId == deliveryId
                        },
                    contact = any(),
                    channels = any(),
                )
            }
        }

    @Test
    fun `GIVEN a failing organization WHEN the job runs THEN the other organizations are still processed`() =
        runTest {
            val broken =
                Organization(
                    organizationId = "broken".toId(),
                    name = "Broken",
                    contactEmail = "b@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = longAgo,
                    lastUpdatedInstant = longAgo,
                    deliveries = listOf(delivery().copy(organizationId = "broken".toId())),
                )
            givenOrganization()
            val healthy = organizationSyncDAO.listAll()
            coEvery { organizationSyncDAO.listAll() } returns listOf(broken) + healthy
            coEvery { contractSyncDAO.getByOrganizationId("broken".toId()) } throws IllegalStateException("boom")
            givenMembers(member("m1"))

            service.run(urgentDueAt + 1.minutes)

            verifyAlerted("m1", NotificationCategory.VOLUNTEER_URGENT_NEED)
        }

    @Test
    fun `GIVEN missing volunteers helper WHEN no contract is main THEN every contract counts`() {
        val d =
            delivery(
                contracts =
                    listOf(
                        deliveryContract(mainContractId, slots = listOf(slot(requiredVolunteers = 1))),
                        deliveryContract(secondaryContractId, slots = listOf(slot(requiredVolunteers = 2))),
                    ),
            )

        assertEquals(3, missingVolunteers(d, listOf(contract(mainContractId), contract(secondaryContractId))))
    }

    private class InMemorySentAlertDAO : SentAlertDAO {
        private val keys = mutableSetOf<String>()

        override suspend fun markIfAbsent(
            key: String,
            sentAt: Instant,
        ): Boolean = keys.add(key)

        override suspend fun purgeBefore(instant: Instant) = Unit
    }
}

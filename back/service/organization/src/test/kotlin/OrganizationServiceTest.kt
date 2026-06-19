@file:OptIn(ExperimentalTime::class)

package organization

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.todayIn
import notificationpublisher.NotificationPublisher
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.ActivityType
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryReminders
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSettings
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.Product
import persistence.model.ProductType
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
internal class OrganizationServiceTest {
    private val organizationId = "org-1"
    private val volunteerId = "volunteer-member-id"
    private val otherMemberId = "other-member-id"
    private val deliveryId = "delivery-1"
    private val contractId = "contract-1"
    private val templateId = "template-1"

    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val deliveryTemplateSyncDAO = mockk<DeliveryTemplateSyncDAO>(relaxed = true)
    private val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val notificationPublisher = mockk<NotificationPublisher>(relaxed = true)
    private val contractSyncDAO = mockk<ContractSyncDAO>(relaxed = true)
    private val service =
        OrganizationService(
            organizationSyncDAO,
            deliveryTemplateSyncDAO,
            producerAccountSyncDAO,
            memberSyncDAO,
            notificationPublisher,
            contractSyncDAO,
        )

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-sub",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = organizationId,
            roles = listOf(Role.ADMIN),
        )

    private val volunteerAuth =
        AuthenticatedInfo(
            memberId = volunteerId,
            firstName = "Volunteer",
            lastName = "User",
            email = "volunteer@example.com",
            organizationId = organizationId,
            roles = listOf(Role.VOLUNTEER),
        )

    private val coordinatorMemberId = "coordinator-member-id"

    private val coordinatorAuth =
        AuthenticatedInfo(
            memberId = coordinatorMemberId,
            firstName = "Coord",
            lastName = "User",
            email = "coord@example.com",
            organizationId = organizationId,
            roles = listOf(Role.COORDINATOR),
        )

    private val now: Instant = Clock.System.now()

    private fun buildOrganization(deliveries: List<Delivery> = emptyList()): Organization =
        Organization(
            organizationId = organizationId.toId(),
            name = "AMAP des Collines",
            contactEmail = "contact@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = now,
            lastUpdatedInstant = now,
            deliveries = deliveries,
        )

    private fun buildDelivery(
        status: DeliveryStatus = DeliveryStatus.CONFIRMED,
        contracts: List<DeliveryContract> = emptyList(),
        deliveryTemplateId: String? = templateId,
        earlySlot: EarlySlot? = null,
    ): Delivery =
        Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = organizationId.toId(),
            deliveryTemplateId = deliveryTemplateId?.toId(),
            scheduledDate = LocalDateTime.parse("2099-01-15T18:30:00"),
            status = status,
            minVolunteersRequired = 2,
            earlySlot = earlySlot,
            contracts = contracts,
        )

    private fun buildContract(
        slots: List<MemberSlot> = emptyList(),
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

    private fun buildContractDefinition(coordinators: List<String>): Contract =
        Contract(
            contractId = contractId.toId(),
            name = "Légumes 2099",
            organizationId = organizationId.toId(),
            producerAccountId = "pa-1".toId(),
            minDeliveryDate = LocalDate.parse("2099-01-01"),
            maxDeliveryDate = LocalDate.parse("2099-12-31"),
            deliveryCount = 10,
            seasonYear = 2099,
            coordinators = coordinators.map { it.toId() },
        )

    private fun buildStandardSlot(
        requiredVolunteers: Int = 2,
        registrations: List<MemberRegistration> = emptyList(),
        slotId: String? = "slot-1",
        status: SlotStatus = SlotStatus.OPEN,
    ): MemberSlot =
        MemberSlot(
            slotId = slotId,
            startTime = LocalDateTime.parse("2099-01-15T18:00:00"),
            endTime = LocalDateTime.parse("2099-01-15T20:00:00"),
            activityType = ActivityType.RECEPTION,
            requiredVolunteers = requiredVolunteers,
            currentRegistrations = registrations.size,
            status = status,
            slotKind = SlotKind.STANDARD,
            registrations = registrations,
        )

    private fun buildEarlySlot(registrations: List<MemberRegistration> = emptyList()): MemberSlot =
        MemberSlot(
            slotId = "slot-early-1",
            startTime = LocalDateTime.parse("2099-01-15T17:00:00"),
            endTime = LocalDateTime.parse("2099-01-15T18:00:00"),
            activityType = ActivityType.PREPARATION,
            requiredVolunteers = 1,
            currentRegistrations = registrations.size,
            status = SlotStatus.OPEN,
            slotKind = SlotKind.EARLY,
            registrations = registrations,
        )

    private fun buildRegistration(
        memberId: String,
        status: RegistrationStatus = RegistrationStatus.REGISTERED,
    ): MemberRegistration =
        MemberRegistration(
            memberId = memberId.toId(),
            displayName = "Member $memberId",
            memberEmail = "$memberId@example.com",
            registrationInstant = now,
            status = status,
        )

    private fun buildTemplate(earlySlotMaxVolunteers: Int? = 1): DeliveryTemplate =
        DeliveryTemplate(
            deliveryTemplateId = templateId.toId(),
            organizationId = organizationId.toId(),
            name = "Livraison du jeudi",
            standardStartTime = "18:00",
            standardEndTime = "20:00",
            earlySlot =
                if (earlySlotMaxVolunteers != null) {
                    EarlySlot(arrivalTime = "17:00", explanation = "Early setup", maxVolunteers = earlySlotMaxVolunteers)
                } else {
                    null
                },
        )

    private fun buildMutation(org: Organization): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(OrganizationPayload(org)),
        )

    // ---- Uniqueness ----

    @Test
    fun `GIVEN admin caller WHEN payload contains two deliveries on the same day THEN REJECTED UNIQUE_VIOLATION`() =
        runTest {
            val existingDelivery = buildDelivery()
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val duplicateDelivery =
                existingDelivery.copy(
                    deliveryId = "delivery-2".toId(),
                    scheduledDate = LocalDateTime.parse("2099-01-15T09:00:00"),
                )
            val updatedOrg = existingOrg.copy(deliveries = listOf(existingDelivery, duplicateDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    // ---- Privileged callers ----

    @Test
    fun `GIVEN admin caller WHEN edits a registration of another member THEN APPLIED`() =
        runTest {
            val existingSlot = buildStandardSlot(registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(otherMemberId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    // ---- Volunteer self-registration ----

    @Test
    fun `GIVEN volunteer caller WHEN registers self to standard slot THEN APPLIED`() =
        runTest {
            val existingSlot = buildStandardSlot(requiredVolunteers = 2, registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self and client increments currentRegistrations THEN APPLIED`() =
        runTest {
            // The client updates currentRegistrations as a denormalized counter alongside the
            // registration list. The validator must not treat that counter change as a structural
            // violation — only the registrations list itself matters.
            val existingSlot = buildStandardSlot(requiredVolunteers = 2, registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            // Client bumps currentRegistrations from 0 to 1 and adds its own registration.
            val updatedSlot =
                existingSlot.copy(
                    currentRegistrations = 1,
                    registrations = listOf(buildRegistration(volunteerId)),
                )
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN unregisters self from standard slot THEN APPLIED`() =
        runTest {
            val existingSlot = buildStandardSlot(registrations = listOf(buildRegistration(volunteerId)))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = emptyList())
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to early slot within capacity THEN APPLIED`() =
        runTest {
            val existingSlot = buildEarlySlot(registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildTemplate(earlySlotMaxVolunteers = 2))

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    // ---- Volunteer forbidden actions ----

    @Test
    fun `GIVEN volunteer caller WHEN registers another member's id THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingSlot = buildStandardSlot(registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(otherMemberId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN modifies organization name THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingOrg = buildOrganization()
            val updatedOrg = existingOrg.copy(name = "Hacked Name")

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns emptyList()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN adds a delivery THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = emptyList())
            val updatedOrg = existingOrg.copy(deliveries = listOf(buildDelivery()))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to a full standard slot THEN REJECTED FORBIDDEN`() =
        runTest {
            // Slot has requiredVolunteers=1 and already has 1 active registration from someone else
            val existingReg = buildRegistration(otherMemberId)
            val existingSlot = buildStandardSlot(requiredVolunteers = 1, registrations = listOf(existingReg))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            // Volunteer adds themselves (slot now has 2 registrations, exceeding cap of 1)
            val updatedSlot = existingSlot.copy(registrations = listOf(existingReg, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN slot is full but all registrations are coordinators THEN APPLIED`() =
        runTest {
            // Slot has requiredVolunteers=1. The coordinator of the contract is already registered.
            // A volunteer registering should be APPLIED because the coordinator does not consume volunteer capacity.
            val coordinatorId = "coordinator-1"
            val coordinatorReg = buildRegistration(coordinatorId)
            val existingSlot = buildStandardSlot(requiredVolunteers = 1, registrations = listOf(coordinatorReg))
            val existingOrg =
                buildOrganization(
                    deliveries =
                        listOf(
                            buildDelivery(
                                contracts = listOf(buildContract(slots = listOf(existingSlot), coordinators = listOf(coordinatorId))),
                            ),
                        ),
                )
            val updatedSlot = existingSlot.copy(registrations = listOf(coordinatorReg, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(
                                contracts = listOf(buildContract(slots = listOf(updatedSlot), coordinators = listOf(coordinatorId))),
                            ),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to an early slot beyond max THEN REJECTED FORBIDDEN`() =
        runTest {
            // Template has earlySlot.maxVolunteers=1; slot already has 1 active registration
            val existingReg = buildRegistration(otherMemberId)
            val existingSlot = buildEarlySlot(registrations = listOf(existingReg))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(existingReg, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot)))),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildTemplate(earlySlotMaxVolunteers = 1))

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to early slot of a template-less delivery whose override allows it THEN APPLIED`() =
        runTest {
            // No template, but the delivery itself carries an early-slot override with maxVolunteers=2.
            val deliveryEarlySlot = EarlySlot(arrivalTime = "16:30", explanation = "Réception", maxVolunteers = 2)
            val existingSlot = buildEarlySlot(registrations = emptyList())
            val existingOrg =
                buildOrganization(
                    deliveries =
                        listOf(
                            buildDelivery(
                                deliveryTemplateId = null,
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(existingSlot))),
                            ),
                        ),
                )
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(
                                deliveryTemplateId = null,
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(updatedSlot))),
                            ),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns emptyList()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers to template-less early slot beyond its override max THEN REJECTED FORBIDDEN`() =
        runTest {
            // Delivery override caps the early slot at 1; the slot already has 1 active registration.
            val deliveryEarlySlot = EarlySlot(arrivalTime = "16:30", explanation = "Réception", maxVolunteers = 1)
            val existingReg = buildRegistration(otherMemberId)
            val existingSlot = buildEarlySlot(registrations = listOf(existingReg))
            val existingOrg =
                buildOrganization(
                    deliveries =
                        listOf(
                            buildDelivery(
                                deliveryTemplateId = null,
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(existingSlot))),
                            ),
                        ),
                )
            val updatedSlot = existingSlot.copy(registrations = listOf(existingReg, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(
                                deliveryTemplateId = null,
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(updatedSlot))),
                            ),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns emptyList()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN delivery early-slot override is more generous than the template THEN the override wins and APPLIED`() =
        runTest {
            // Template caps at 1, but the delivery override raises the cap to 3; a second registration is allowed.
            val deliveryEarlySlot = EarlySlot(arrivalTime = "16:30", explanation = "Réception", maxVolunteers = 3)
            val existingReg = buildRegistration(otherMemberId)
            val existingSlot = buildEarlySlot(registrations = listOf(existingReg))
            val existingOrg =
                buildOrganization(
                    deliveries =
                        listOf(
                            buildDelivery(
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(existingSlot))),
                            ),
                        ),
                )
            val updatedSlot = existingSlot.copy(registrations = listOf(existingReg, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            buildDelivery(
                                earlySlot = deliveryEarlySlot,
                                contracts = listOf(buildContract(slots = listOf(updatedSlot))),
                            ),
                        ),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildTemplate(earlySlotMaxVolunteers = 1))

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    // ---- Coordinator assignment guard (MISSING_COORDINATOR) ----

    @Test
    fun `GIVEN admin caller WHEN payload has CONFIRMED delivery with empty coordinators THEN REJECTED MISSING_COORDINATOR`() =
        runTest {
            val existingOrg = buildOrganization()
            val confirmedWithoutCoord =
                buildDelivery(
                    status = DeliveryStatus.CONFIRMED,
                    contracts = listOf(buildContract(coordinators = emptyList())),
                )
            val updatedOrg = existingOrg.copy(deliveries = listOf(confirmedWithoutCoord))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.MISSING_COORDINATOR, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN payload has PLANNED delivery with empty coordinators THEN APPLIED`() =
        runTest {
            val existingOrg = buildOrganization()
            val planned =
                buildDelivery(
                    status = DeliveryStatus.PLANNED,
                    contracts = listOf(buildContract(coordinators = emptyList())),
                )
            val updatedOrg = existingOrg.copy(deliveries = listOf(planned))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    @Test
    fun `GIVEN coordinator caller WHEN self-assigns on a PLANNED delivery THEN APPLIED`() =
        runTest {
            val existingContract = buildContract(coordinators = emptyList())
            val existingDelivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(existingContract))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val updatedContract = existingContract.copy(coordinators = listOf(coordinatorMemberId.toId()))
            val updatedDelivery = existingDelivery.copy(contracts = listOf(updatedContract))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN removes the last coordinator on a CONFIRMED delivery THEN REJECTED MISSING_COORDINATOR`() =
        runTest {
            val existingContract = buildContract()
            val existingDelivery = buildDelivery(status = DeliveryStatus.CONFIRMED, contracts = listOf(existingContract))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val updatedContract = existingContract.copy(coordinators = emptyList())
            val updatedDelivery = existingDelivery.copy(contracts = listOf(updatedContract))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.MISSING_COORDINATOR, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN tries to assign themselves as coordinator THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingContract = buildContract(coordinators = emptyList())
            val existingDelivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(existingContract))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val updatedContract = existingContract.copy(coordinators = listOf(volunteerId.toId()))
            val updatedDelivery = existingDelivery.copy(contracts = listOf(updatedContract))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN assigns a coordinator not in the contract pool THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existingContract = buildContract(coordinators = emptyList())
            val existingDelivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(existingContract))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val updatedContract = existingContract.copy(coordinators = listOf("outsider-id".toId()))
            val updatedDelivery = existingDelivery.copy(contracts = listOf(updatedContract))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(coordinators = listOf(coordinatorMemberId)))

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN assigns a coordinator from the contract pool THEN APPLIED`() =
        runTest {
            val existingContract = buildContract(coordinators = emptyList())
            val existingDelivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(existingContract))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            val updatedContract = existingContract.copy(coordinators = listOf(coordinatorMemberId.toId()))
            val updatedDelivery = existingDelivery.copy(contracts = listOf(updatedContract))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(coordinators = listOf(coordinatorMemberId)))

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to a cancelled delivery THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingSlot = buildStandardSlot(registrations = emptyList())
            val cancelledDelivery =
                buildDelivery(status = DeliveryStatus.CANCELLED, contracts = listOf(buildContract(slots = listOf(existingSlot))))
            val existingOrg = buildOrganization(deliveries = listOf(cancelledDelivery))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(volunteerId)))
            val updatedDelivery = cancelledDelivery.copy(contracts = listOf(buildContract(slots = listOf(updatedSlot))))
            val updatedOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    // ---- Product modification guard ----

    private val noAccountProducerId = "no-account-producer-id"
    private val accountBackedProducerId = "account-backed-producer-id"
    private val productTypeId = "product-type-1"

    private fun buildNoAccountProducer(): ProducerAccount =
        ProducerAccount(
            producerAccountId = noAccountProducerId.toId(),
            name = "AMAP Producer",
            activeStatus = true,
            createdInstant = now,
            lastUpdatedInstant = now,
            managementMode = ProducerManagementMode.NO_ACCOUNT,
        )

    private fun buildAccountBackedProducer(): ProducerAccount =
        ProducerAccount(
            producerAccountId = accountBackedProducerId.toId(),
            name = "Account-Backed Producer",
            activeStatus = true,
            createdInstant = now,
            lastUpdatedInstant = now,
            managementMode = ProducerManagementMode.ACCOUNT_BACKED,
        )

    private fun buildProduct(producerId: String): Product =
        Product(
            name = "Vegetables",
            productTypeId = productTypeId.toId(),
            producerAccountId = producerId.toId(),
            supportedBasketSizes = listOf(BasketSize("small")),
        )

    @Test
    fun `GIVEN admin caller WHEN adds a product for a NO_ACCOUNT producer via org payload THEN APPLIED but NO_ACCOUNT products stripped`() =
        runTest {
            // NO_ACCOUNT products are now exclusively derived from ProducerAccount.products.
            // An admin sending NO_ACCOUNT products through the org payload is silently stripped;
            // the authoritative NO_ACCOUNT products (from the persisted org, put there by
            // ProducerAccountService.deriveOrganizationProducts) are preserved instead.
            val existingOrg = buildOrganization() // no products persisted yet
            val incomingOrg = existingOrg.copy(products = listOf(buildProduct(noAccountProducerId)))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildNoAccountProducer())

            val outcome = service.applyUpsert(adminAuth, buildMutation(incomingOrg), OrganizationPayload(incomingOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            // The org stored must have the NO_ACCOUNT products stripped (persisted org had none)
            coVerify(exactly = 1) { organizationSyncDAO.put(match { it.products.isEmpty() }, any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN modifies a product for an ACCOUNT_BACKED producer THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingProduct = buildProduct(accountBackedProducerId)
            val existingOrg = buildOrganization().copy(products = listOf(existingProduct))
            val updatedProduct = existingProduct.copy(name = "Organic Vegetables")
            val updatedOrg = existingOrg.copy(products = listOf(updatedProduct))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildAccountBackedProducer())

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN removes a product for an ACCOUNT_BACKED producer THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingProduct = buildProduct(accountBackedProducerId)
            val existingOrg = buildOrganization().copy(products = listOf(existingProduct))
            val updatedOrg = existingOrg.copy(products = emptyList())

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildAccountBackedProducer())

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN adds a product for an ACCOUNT_BACKED producer THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingOrg = buildOrganization()
            val updatedOrg = existingOrg.copy(products = listOf(buildProduct(accountBackedProducerId)))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildAccountBackedProducer())

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN org mutation THEN NO_ACCOUNT products from persisted org are preserved`() =
        runTest {
            // A persisted org already has a NO_ACCOUNT product (put there by ProducerAccountService).
            // When admin sends an org mutation without that product, it must be re-injected.
            val noAccountProduct = buildProduct(noAccountProducerId)
            val existingOrg = buildOrganization().copy(products = listOf(noAccountProduct))
            // Admin sends org without the NO_ACCOUNT product (e.g. stale payload)
            val incomingOrg = existingOrg.copy(name = "Updated AMAP Name", products = emptyList())

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildNoAccountProducer())

            val outcome = service.applyUpsert(adminAuth, buildMutation(incomingOrg), OrganizationPayload(incomingOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            // The stored org must still carry the NO_ACCOUNT product preserved from the persisted org
            coVerify(exactly = 1) { organizationSyncDAO.put(match { it.products == listOf(noAccountProduct) }, any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN products list is unchanged THEN APPLIED`() =
        runTest {
            val existingProduct = buildProduct(accountBackedProducerId)
            val existingOrg = buildOrganization().copy(products = listOf(existingProduct))
            val updatedOrg = existingOrg.copy(name = "Updated AMAP Name")

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            // mergeNoAccountProducts always queries to identify NO_ACCOUNT producers;
            // relaxed mock returns emptyList() so no NO_ACCOUNT products are preserved.

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    // ---- Slot lifecycle (delete / cancel / reschedule) ----

    private fun buildMember(memberId: String): Member =
        Member(
            memberId = memberId.toId(),
            organizationId = organizationId.toId(),
            activeStatus = true,
            email = "$memberId@example.com",
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
                    pushNotificationsEnabled = false,
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

    @Test
    fun `GIVEN coordinator caller WHEN deletes a slot with active registrations THEN REJECTED CONFLICT`() =
        runTest {
            val existingSlot = buildStandardSlot(registrations = listOf(buildRegistration(otherMemberId)))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = emptyList())))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN coordinator caller WHEN deletes a slot whose registrations are all cancelled THEN APPLIED`() =
        runTest {
            val existingSlot =
                buildStandardSlot(
                    registrations = listOf(buildRegistration(otherMemberId, status = RegistrationStatus.CANCELLED)),
                )
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = emptyList())))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    @Test
    fun `GIVEN coordinator caller WHEN cancels a slot THEN registrations cascaded server-side and active members notified`() =
        runTest {
            val activeReg = buildRegistration(otherMemberId)
            val alreadyCancelledReg = buildRegistration("cancelled-member-id", status = RegistrationStatus.CANCELLED)
            val ghostReg = buildRegistration("ghost-member-id")
            val existingSlot = buildStandardSlot(registrations = listOf(activeReg, alreadyCancelledReg, ghostReg))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            // The client flips the status without cascading the registrations
            val updatedSlot = existingSlot.copy(status = SlotStatus.CANCELLED)
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            // ghost-member-id has no member row anymore → must be skipped for notification
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildMember(otherMemberId), buildMember("cancelled-member-id"))

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        val slot =
                            org.deliveries
                                .single()
                                .contracts
                                .single()
                                .slots
                                .single()
                        slot.status == SlotStatus.CANCELLED &&
                            slot.currentRegistrations == 0 &&
                            slot.registrations.all { it.status == RegistrationStatus.CANCELLED }
                    },
                    any(),
                )
            }
            coVerify(exactly = 1) {
                notificationPublisher.publish(
                    recipientScope = "member:$otherMemberId",
                    type = any(),
                    category = NotificationCategory.SLOT_CANCELLED,
                    content = any(),
                    contact = any(),
                    channels = any(),
                )
            }
            coVerify(exactly = 0) {
                notificationPublisher.publish(
                    recipientScope = "member:cancelled-member-id",
                    type = any(),
                    category = any(),
                    content = any(),
                    contact = any(),
                    channels = any(),
                )
            }
            coVerify(exactly = 0) {
                notificationPublisher.publish(
                    recipientScope = "member:ghost-member-id",
                    type = any(),
                    category = any(),
                    content = any(),
                    contact = any(),
                    channels = any(),
                )
            }
        }

    @Test
    fun `GIVEN coordinator caller WHEN reopens a cancelled slot THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingSlot = buildStandardSlot(status = SlotStatus.CANCELLED)
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(status = SlotStatus.OPEN)
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN coordinator caller WHEN reschedules a slot with active registrations THEN APPLIED and members notified`() =
        runTest {
            val activeReg = buildRegistration(otherMemberId)
            val existingSlot = buildStandardSlot(registrations = listOf(activeReg))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot =
                existingSlot.copy(
                    startTime = LocalDateTime.parse("2099-01-15T19:00:00"),
                    endTime = LocalDateTime.parse("2099-01-15T21:00:00"),
                )
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildMember(otherMemberId))

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            // Registrations are preserved as-is
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        org.deliveries
                            .single()
                            .contracts
                            .single()
                            .slots
                            .single()
                            .registrations == listOf(activeReg)
                    },
                    any(),
                )
            }
            coVerify(exactly = 1) {
                notificationPublisher.publish(
                    recipientScope = "member:$otherMemberId",
                    type = any(),
                    category = NotificationCategory.SLOT_RESCHEDULED,
                    content = any(),
                    contact = any(),
                    channels = any(),
                )
            }
        }

    @Test
    fun `GIVEN admin caller WHEN upserts a slot without slot_id THEN a slot id is backfilled at write`() =
        runTest {
            val existingOrg = buildOrganization()
            val newSlot = buildStandardSlot(slotId = null)
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(newSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        org.deliveries
                            .single()
                            .contracts
                            .single()
                            .slots
                            .single()
                            .slotId != null
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN persisted legacy slot without id WHEN coordinator cancels it by natural key THEN matched and cascaded`() =
        runTest {
            val activeReg = buildRegistration(otherMemberId)
            val legacySlot = buildStandardSlot(slotId = null, registrations = listOf(activeReg))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(legacySlot))))))
            // Incoming slot still has no id: matched by natural key (start, end, activity)
            val updatedSlot = legacySlot.copy(status = SlotStatus.CANCELLED)
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildMember(otherMemberId))

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        val slot =
                            org.deliveries
                                .single()
                                .contracts
                                .single()
                                .slots
                                .single()
                        slot.slotId != null &&
                            slot.status == SlotStatus.CANCELLED &&
                            slot.registrations.all { it.status == RegistrationStatus.CANCELLED }
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN volunteer caller WHEN payload echoes slots without slot_id THEN APPLIED and persisted slot ids preserved`() =
        runTest {
            // The persisted slot carries a server-backfilled id; a legacy client echo
            // without slot_id must neither be rejected nor erase the id.
            val existingSlot = buildStandardSlot(slotId = "slot-backfilled-1", registrations = emptyList())
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot =
                existingSlot.copy(
                    slotId = null,
                    registrations = listOf(buildRegistration(volunteerId)),
                )
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                organizationSyncDAO.put(
                    match { org ->
                        val slot =
                            org.deliveries
                                .single()
                                .contracts
                                .single()
                                .slots
                                .single()
                        slot.slotId == "slot-backfilled-1" && slot.registrations.size == 1
                    },
                    any(),
                )
            }
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to a cancelled slot THEN REJECTED FORBIDDEN`() =
        runTest {
            val existingSlot = buildStandardSlot(status = SlotStatus.CANCELLED)
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedSlot = existingSlot.copy(registrations = listOf(buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN coordinator caller WHEN deletes a whole delivery containing registered slots THEN APPLIED`() =
        runTest {
            // Decision 2: the guard only applies when delivery and contract both survive in the payload.
            val existingSlot = buildStandardSlot(registrations = listOf(buildRegistration(otherMemberId)))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val updatedOrg = existingOrg.copy(deliveries = emptyList())

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any()) }
        }

    // ---- Contract ended guard (delivery-link, CONTRACT_ENDED) ----

    private fun buildSeasonContract(
        id: String = contractId,
        maxDeliveryDate: LocalDate,
        coordinators: List<String> = listOf("coordinator-1"),
    ): Contract =
        Contract(
            contractId = id.toId(),
            name = "Test contract",
            organizationId = organizationId.toId(),
            producerAccountId = "producer-1".toId(),
            minDeliveryDate = LocalDate(2024, 1, 1),
            maxDeliveryDate = maxDeliveryDate,
            deliveryCount = 10,
            seasonYear = 2024,
            coordinators = coordinators.map { it.toId() },
        )

    @Test
    fun `GIVEN new delivery linking an ended contract THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            // Use the same timezone as buildOrganization (Europe/Paris) so "today" is consistent
            val orgTimezone = TimeZone.of("Europe/Paris")
            val today = Clock.System.todayIn(orgTimezone)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val seasonContract = buildSeasonContract(maxDeliveryDate = pastDate)
            val existingOrg = buildOrganization()
            val newDelivery = buildDelivery(contracts = listOf(buildContract()))
            val incomingOrg = existingOrg.copy(deliveries = listOf(newDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(seasonContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(incomingOrg), OrganizationPayload(incomingOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN existing past delivery already linked to ended contract edited THEN APPLIED`() =
        runTest {
            // Use the same timezone as buildOrganization (Europe/Paris) so "today" is consistent
            val orgTimezone = TimeZone.of("Europe/Paris")
            val today = Clock.System.todayIn(orgTimezone)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val seasonContract = buildSeasonContract(maxDeliveryDate = pastDate)
            // Delivery already exists in the persisted org with the same contract link
            val existingDelivery = buildDelivery(status = DeliveryStatus.COMPLETED, contracts = listOf(buildContract()))
            val existingOrg = buildOrganization(deliveries = listOf(existingDelivery))
            // Admin edits the delivery (e.g. change status) but keeps the same contract link
            val updatedDelivery = existingDelivery.copy(status = DeliveryStatus.COMPLETED)
            val incomingOrg = existingOrg.copy(deliveries = listOf(updatedDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(seasonContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(incomingOrg), OrganizationPayload(incomingOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN new delivery linking contract whose maxDeliveryDate is today THEN APPLIED`() =
        runTest {
            // Use the same timezone as buildOrganization (Europe/Paris) so "today" is consistent
            val orgTimezone = TimeZone.of("Europe/Paris")
            val today = Clock.System.todayIn(orgTimezone)
            val seasonContract = buildSeasonContract(maxDeliveryDate = today)
            val existingOrg = buildOrganization()
            val newDelivery = buildDelivery(contracts = listOf(buildContract()))
            val incomingOrg = existingOrg.copy(deliveries = listOf(newDelivery))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(seasonContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(incomingOrg), OrganizationPayload(incomingOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(any(), any()) }
        }

    // ---- Deny-by-default (P1.2) ----

    @Test
    fun `GIVEN caller with only PRODUCER role WHEN applyUpsert THEN REJECTED FORBIDDEN and put never called`() =
        runTest {
            val producerAuth =
                AuthenticatedInfo(
                    memberId = "producer-sub",
                    firstName = "Producer",
                    lastName = "User",
                    email = "producer@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.PRODUCER),
                )
            val org = buildOrganization()

            val outcome = service.applyUpsert(producerAuth, buildMutation(org), OrganizationPayload(org))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN caller with empty roles WHEN applyUpsert THEN REJECTED FORBIDDEN and put never called`() =
        runTest {
            val noRoleAuth =
                AuthenticatedInfo(
                    memberId = "empty-roles-sub",
                    firstName = "No",
                    lastName = "Role",
                    email = "norole@example.com",
                    organizationId = organizationId,
                    roles = emptyList(),
                )
            val org = buildOrganization()

            val outcome = service.applyUpsert(noRoleAuth, buildMutation(org), OrganizationPayload(org))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }
}

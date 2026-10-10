@file:OptIn(ExperimentalTime::class)

package organization

import authentication.AuthenticatedInfo
import authentication.Role
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
import kotlinx.datetime.atTime
import kotlinx.datetime.minus
import kotlinx.datetime.todayIn
import notificationpublisher.NotificationPublisher
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.ProducerSchedulePayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.ActivityType
import persistence.model.BasketDeliveryDescription
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryItem
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.EntityType
import persistence.model.ItemType
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.Product
import persistence.model.ProductType
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
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
        scheduledDate: LocalDateTime = LocalDateTime.parse("2099-01-15T18:30:00"),
    ): Delivery =
        Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = organizationId.toId(),
            deliveryTemplateId = deliveryTemplateId?.toId(),
            scheduledDate = scheduledDate,
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

    // ---- instance-owner fan-out ----

    @Test
    fun `GIVEN admin caller WHEN renames the organization THEN the change is fanned out to instance-owner`() =
        runTest {
            val existingOrg = buildOrganization()
            val renamed = existingOrg.copy(name = "Renamed AMAP")
            val fanOut = slot<List<Change>>()
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { organizationSyncDAO.put(any(), any(), capture(fanOut)) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(renamed), OrganizationPayload(renamed))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val change = fanOut.captured.single { it.scopeKey == SyncScope.InstanceOwner.key }
            assertEquals(ChangeOp.UPSERT, change.op)
            assertEquals("Renamed AMAP", (change.payload as OrganizationPayload).organization.name)
        }

    @Test
    fun `GIVEN admin caller WHEN edit leaves the identity unchanged THEN nothing is fanned out to instance-owner`() =
        runTest {
            val existingOrg = buildOrganization()
            val fanOut = slot<List<Change>>()
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { organizationSyncDAO.put(any(), any(), capture(fanOut)) } returns Unit

            service.applyUpsert(adminAuth, buildMutation(existingOrg), OrganizationPayload(existingOrg))

            assertTrue(fanOut.captured.none { it.scopeKey == SyncScope.InstanceOwner.key })
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
    fun `GIVEN volunteer caller served masked emails WHEN registers self THEN APPLIED and the stored emails are kept`() =
        runTest {
            // The plain member was served the other registrations without their email
            // (PlainMemberRedaction) and writes the whole organization back.
            val existingSlot = buildStandardSlot(requiredVolunteers = 3, registrations = listOf(buildRegistration("neighbour")))
            val existingOrg =
                buildOrganization(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(existingSlot))))))
            val maskedNeighbour =
                buildRegistration(
                    "neighbour",
                ).copy(memberEmail = "", registrationInstant = Instant.fromEpochMilliseconds(0))
            val updatedSlot = existingSlot.copy(registrations = listOf(maskedNeighbour, buildRegistration(volunteerId)))
            val updatedOrg =
                existingOrg.copy(deliveries = listOf(buildDelivery(contracts = listOf(buildContract(slots = listOf(updatedSlot))))))
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())
            val written = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(written), any(), any()) } returns Unit

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val registrations =
                written.captured.deliveries
                    .single()
                    .contracts
                    .single()
                    .slots
                    .single()
                    .registrations
            assertEquals("neighbour@example.com", registrations.single { it.memberId.id == "neighbour" }.memberEmail)
            assertEquals("$volunteerId@example.com", registrations.single { it.memberId.id == volunteerId }.memberEmail)
        }

    private fun maskedPlainMemberCopy(): Pair<Organization, Organization> {
        // Stored: a past delivery (attendance + an absence + coordinator notes) and an
        // upcoming one where the neighbour is registered.
        val past =
            buildDelivery(
                scheduledDate = LocalDateTime.parse("2026-01-07T19:00:00"),
                contracts =
                    listOf(
                        buildContract(
                            slots =
                                listOf(
                                    buildStandardSlot(
                                        requiredVolunteers = 3,
                                        registrations =
                                            listOf(
                                                buildRegistration("neighbour", RegistrationStatus.CONFIRMED),
                                                buildRegistration("absentee", RegistrationStatus.CANCELLED),
                                            ),
                                    ),
                                ),
                        ).copy(preparationNotes = "Clé chez la gardienne"),
                    ),
            ).copy(deliveryId = "delivery-past".toId())
        val upcomingSlot = buildStandardSlot(requiredVolunteers = 3, registrations = listOf(buildRegistration("neighbour")))
        val upcoming = buildDelivery(contracts = listOf(buildContract(slots = listOf(upcomingSlot))))
        val stored = buildOrganization(deliveries = listOf(past, upcoming))
        // What the plain member was served (PlainMemberRedaction), then their self-registration.
        val maskedPast =
            past.copy(
                contracts =
                    past.contracts.map { link ->
                        link.copy(
                            preparationNotes = null,
                            slots =
                                link.slots.map {
                                    it.copy(
                                        registrations =
                                            listOf(
                                                buildRegistration("anonymous", RegistrationStatus.CONFIRMED).copy(
                                                    displayName = "",
                                                    memberEmail = "",
                                                    registrationInstant = Instant.fromEpochMilliseconds(0),
                                                ),
                                            ),
                                    )
                                },
                        )
                    },
            )
        val maskedNeighbour = buildRegistration("neighbour").copy(memberEmail = "", registrationInstant = Instant.fromEpochMilliseconds(0))
        val registered =
            buildDelivery(
                contracts =
                    listOf(
                        buildContract(
                            slots = listOf(upcomingSlot.copy(registrations = listOf(maskedNeighbour, buildRegistration(volunteerId)))),
                        ),
                    ),
            )
        return stored to stored.copy(deliveries = listOf(maskedPast, registered), participationCountsBySeason = mapOf(2026 to listOf(1, 0)))
    }

    @Test
    fun `GIVEN volunteer caller writing back the masked copy WHEN registers self THEN APPLIED and nothing stored is lost`() =
        runTest {
            val (stored, written) = maskedPlainMemberCopy()
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns stored
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())
            val persisted = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(persisted), any(), any()) } returns Unit

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(written), OrganizationPayload(written))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val expected =
                stored.copy(
                    deliveries =
                        listOf(
                            stored.deliveries[0],
                            stored.deliveries[1].copy(
                                contracts =
                                    stored.deliveries[1].contracts.map { link ->
                                        link.copy(
                                            slots =
                                                link.slots.map {
                                                    it.copy(
                                                        registrations =
                                                            it.registrations + buildRegistration(volunteerId),
                                                        currentRegistrations = it.currentRegistrations + 1,
                                                    )
                                                },
                                        )
                                    },
                            ),
                        ),
                )
            assertEquals(expected.deliveries, persisted.captured.deliveries)
            assertNull(persisted.captured.participationCountsBySeason)
        }

    @Test
    fun `GIVEN a stale copy missing a newer registration WHEN volunteer registers self elsewhere THEN APPLIED and both kept`() =
        runTest {
            // Two members register around the same time: the caller's copy predates the
            // neighbour's registration on the first delivery.
            val emptySlot = buildStandardSlot(requiredVolunteers = 3, registrations = emptyList())
            val first = buildDelivery(contracts = listOf(buildContract(slots = listOf(emptySlot))))
            val second =
                buildDelivery(
                    contracts = listOf(buildContract(slots = listOf(emptySlot))),
                    scheduledDate = LocalDateTime.parse("2099-01-22T18:30:00"),
                ).copy(deliveryId = "delivery-2".toId())
            val callerCopy = buildOrganization(deliveries = listOf(first, second))
            val stored =
                callerCopy.copy(
                    deliveries =
                        listOf(
                            first.copy(
                                contracts =
                                    listOf(
                                        buildContract(
                                            slots = listOf(emptySlot.copy(registrations = listOf(buildRegistration("neighbour")))),
                                        ),
                                    ),
                            ),
                            second,
                        ),
                )
            val written =
                callerCopy.copy(
                    deliveries =
                        listOf(
                            first,
                            second.copy(
                                contracts =
                                    listOf(
                                        buildContract(
                                            slots = listOf(emptySlot.copy(registrations = listOf(buildRegistration(volunteerId)))),
                                        ),
                                    ),
                            ),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns stored
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())
            val persisted = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(persisted), any(), any()) } returns Unit

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(written), OrganizationPayload(written))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val registrationsByDelivery =
                persisted.captured.deliveries.associate { delivery ->
                    delivery.deliveryId.id to
                        delivery.contracts
                            .single()
                            .slots
                            .single()
                            .registrations
                            .map { it.memberId.id }
                }
            assertEquals(mapOf(deliveryId to listOf("neighbour"), "delivery-2" to listOf(volunteerId)), registrationsByDelivery)
        }

    @Test
    fun `GIVEN volunteer caller WHEN altering a masked registration of another member THEN the stored registrations are kept`() =
        runTest {
            val (stored, written) = maskedPlainMemberCopy()
            // Turns the anonymous attendance into an absence: not the copy that was served.
            val tampered =
                written.copy(
                    deliveries =
                        listOf(
                            written.deliveries[0].copy(
                                contracts =
                                    written.deliveries[0].contracts.map { link ->
                                        link.copy(
                                            slots =
                                                link.slots.map { slot ->
                                                    slot.copy(
                                                        registrations =
                                                            slot.registrations.map {
                                                                it.copy(
                                                                    status = RegistrationStatus.CANCELLED,
                                                                )
                                                            },
                                                    )
                                                },
                                        )
                                    },
                            ),
                            written.deliveries[1],
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns stored
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())
            val persisted = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(persisted), any(), any()) } returns Unit

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(tampered), OrganizationPayload(tampered))

            // The self-registration goes through; the tampered attendance is ignored.
            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(stored.deliveries[0], persisted.captured.deliveries[0])
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
    fun `GIVEN volunteer caller WHEN registers another member's id THEN ignored and the stored organization is written back`() =
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

            // Only the caller's own registrations are taken from a volunteer write: the stored
            // organization is written back unchanged, so the caller's cache converges on it.
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(existingOrg, any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN modifies organization name THEN ignored and the stored organization is written back`() =
        runTest {
            val existingOrg = buildOrganization()
            val updatedOrg = existingOrg.copy(name = "Hacked Name")

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns emptyList()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            // Only the caller's own registrations are taken from a volunteer write: the stored
            // organization is written back unchanged, so the caller's cache converges on it.
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(existingOrg, any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN adds a delivery THEN ignored and the stored organization is written back`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = emptyList())
            val updatedOrg = existingOrg.copy(deliveries = listOf(buildDelivery()))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            // Only the caller's own registrations are taken from a volunteer write: the stored
            // organization is written back unchanged, so the caller's cache converges on it.
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(existingOrg, any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN registers self to a full standard slot THEN REJECTED CONFLICT`() =
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
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
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
    fun `GIVEN volunteer caller WHEN registers self to an early slot beyond max THEN REJECTED CONFLICT`() =
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
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
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
    fun `GIVEN volunteer caller WHEN registers to template-less early slot beyond its override max THEN REJECTED CONFLICT`() =
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
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
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
    fun `GIVEN a CONFIRMED delivery already without coordinator WHEN admin edits another delivery THEN APPLIED`() =
        runTest {
            // E.g. its only coordinator's account was deleted: the alert asks to assign one,
            // but unrelated writes must not be blocked meanwhile.
            val orphan =
                buildDelivery(status = DeliveryStatus.CONFIRMED, contracts = listOf(buildContract(coordinators = emptyList())))
            val other =
                buildDelivery(
                    status = DeliveryStatus.PLANNED,
                    contracts = listOf(buildContract()),
                    scheduledDate = LocalDateTime.parse("2099-01-22T18:30:00"),
                ).copy(deliveryId = "delivery-2".toId())
            val existingOrg = buildOrganization(deliveries = listOf(orphan, other))
            val updatedOrg = existingOrg.copy(deliveries = listOf(orphan, other.copy(minVolunteersRequired = 3)))
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(listOf("coordinator-1")))

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a CONFIRMED delivery already without coordinator WHEN volunteer registers on it THEN APPLIED`() =
        runTest {
            val slot = buildStandardSlot(requiredVolunteers = 2, registrations = emptyList())
            val orphan =
                buildDelivery(
                    status = DeliveryStatus.CONFIRMED,
                    contracts = listOf(buildContract(slots = listOf(slot), coordinators = emptyList())),
                )
            val existingOrg = buildOrganization(deliveries = listOf(orphan))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            orphan.copy(
                                contracts =
                                    listOf(
                                        buildContract(
                                            slots = listOf(slot.copy(registrations = listOf(buildRegistration(volunteerId)))),
                                            coordinators = emptyList(),
                                        ),
                                    ),
                            ),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(buildTemplate())

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    // ---- Closing guard: a delivery cannot be COMPLETED before its day ----

    @Test
    fun `GIVEN planned future delivery WHEN coordinator marks it COMPLETED THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val planned = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(buildContract()))
            val existingOrg = buildOrganization(deliveries = listOf(planned))
            val updatedOrg = existingOrg.copy(deliveries = listOf(planned.copy(status = DeliveryStatus.COMPLETED)))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN new future delivery WHEN created already COMPLETED THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existingOrg = buildOrganization()
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(buildDelivery(status = DeliveryStatus.COMPLETED, contracts = listOf(buildContract()))),
                )

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
        }

    @Test
    fun `GIVEN delivery scheduled today WHEN coordinator marks it COMPLETED THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.of("Europe/Paris"))
            val todayDelivery =
                buildDelivery(
                    status = DeliveryStatus.IN_PROGRESS,
                    contracts = listOf(buildContract()),
                    scheduledDate = today.atTime(23, 59),
                )
            val existingOrg = buildOrganization(deliveries = listOf(todayDelivery))
            val updatedOrg = existingOrg.copy(deliveries = listOf(todayDelivery.copy(status = DeliveryStatus.COMPLETED)))

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN future delivery already COMPLETED WHEN org is re-upserted THEN APPLIED`() =
        runTest {
            val completed = buildDelivery(status = DeliveryStatus.COMPLETED, contracts = listOf(buildContract()))
            val existingOrg = buildOrganization(deliveries = listOf(completed))
            val updatedOrg = existingOrg.copy(name = "AMAP renommée")

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    // ---- Day-of guard: presences and collection are recorded from the delivery day on ----

    private fun futureDeliveryWithRegistration(
        registrationStatus: RegistrationStatus = RegistrationStatus.REGISTERED,
        slotStatus: SlotStatus = SlotStatus.OPEN,
        contractStatus: DeliveryContractStatus = DeliveryContractStatus.PENDING,
        scheduledDate: LocalDateTime = LocalDateTime.parse("2099-01-15T18:30:00"),
    ): Delivery =
        buildDelivery(
            status = DeliveryStatus.PLANNED,
            scheduledDate = scheduledDate,
            contracts =
                listOf(
                    buildContract(
                        slots =
                            listOf(
                                buildStandardSlot(
                                    status = slotStatus,
                                    registrations = listOf(buildRegistration("volunteer-1", registrationStatus)),
                                ),
                            ),
                    ).copy(status = contractStatus),
                ),
        )

    @Test
    fun `GIVEN future delivery WHEN coordinator marks a volunteer present THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = listOf(futureDeliveryWithRegistration()))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(futureDeliveryWithRegistration(registrationStatus = RegistrationStatus.CONFIRMED)),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN future delivery WHEN coordinator marks a volunteer absent THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = listOf(futureDeliveryWithRegistration()))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(futureDeliveryWithRegistration(registrationStatus = RegistrationStatus.CANCELLED)),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
        }

    @Test
    fun `GIVEN future delivery WHEN coordinator marks a contract collected THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = listOf(futureDeliveryWithRegistration()))
            val updatedOrg =
                existingOrg.copy(
                    deliveries = listOf(futureDeliveryWithRegistration(contractStatus = DeliveryContractStatus.DISTRIBUTED)),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
        }

    @Test
    fun `GIVEN future delivery WHEN coordinator cancels the slot with its registrations THEN APPLIED`() =
        runTest {
            val existingOrg = buildOrganization(deliveries = listOf(futureDeliveryWithRegistration()))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            futureDeliveryWithRegistration(
                                registrationStatus = RegistrationStatus.CANCELLED,
                                slotStatus = SlotStatus.CANCELLED,
                            ),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN delivery scheduled today WHEN coordinator records presence and collection THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.of("Europe/Paris")).atTime(23, 59)
            val existingOrg = buildOrganization(deliveries = listOf(futureDeliveryWithRegistration(scheduledDate = today)))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            futureDeliveryWithRegistration(
                                registrationStatus = RegistrationStatus.CONFIRMED,
                                contractStatus = DeliveryContractStatus.DISTRIBUTED,
                                scheduledDate = today,
                            ),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN past delivery already COMPLETED WHEN coordinator records presence and collection afterwards THEN APPLIED`() =
        runTest {
            // A closed delivery (manually archived or auto-closed the next day) can still be
            // pointed after the fact.
            val past = LocalDateTime.parse("2026-01-07T19:00:00")
            val closed = futureDeliveryWithRegistration(scheduledDate = past).copy(status = DeliveryStatus.COMPLETED)
            val existingOrg = buildOrganization(deliveries = listOf(closed))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            futureDeliveryWithRegistration(
                                registrationStatus = RegistrationStatus.CONFIRMED,
                                contractStatus = DeliveryContractStatus.DISTRIBUTED,
                                scheduledDate = past,
                            ).copy(status = DeliveryStatus.COMPLETED),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN past delivery already COMPLETED WHEN coordinator marks a volunteer absent afterwards THEN APPLIED`() =
        runTest {
            val past = LocalDateTime.parse("2026-01-07T19:00:00")
            val closed = futureDeliveryWithRegistration(scheduledDate = past).copy(status = DeliveryStatus.COMPLETED)
            val existingOrg = buildOrganization(deliveries = listOf(closed))
            val updatedOrg =
                existingOrg.copy(
                    deliveries =
                        listOf(
                            futureDeliveryWithRegistration(
                                registrationStatus = RegistrationStatus.CANCELLED,
                                scheduledDate = past,
                            ).copy(status = DeliveryStatus.COMPLETED),
                        ),
                )
            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
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
    fun `GIVEN volunteer caller WHEN tries to assign themselves as coordinator THEN ignored and the stored organization is written back`() =
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

            // Only the caller's own registrations are taken from a volunteer write: the stored
            // organization is written back unchanged, so the caller's cache converges on it.
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(existingOrg, any(), any()) }
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
            coVerify(exactly = 1) { organizationSyncDAO.put(match { it.products == listOf(noAccountProduct) }, any(), any()) }
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
            coVerify(exactly = 1) { organizationSyncDAO.put(updatedOrg, any(), any()) }
        }

    // ---- Slot lifecycle (delete / cancel / reschedule) ----

    private fun buildMember(memberId: String): Member =
        Member(
            memberId = memberId.toId(),
            organizationId = organizationId.toId(),
            email = "$memberId@example.com",
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
                    // French date and times, not the ISO ones.
                    content = match { it.body == "Le créneau du 15 janvier 2099 (18h00–20h00) a été annulé." },
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
    fun `GIVEN registered member opted out of planning changes WHEN slot rescheduled THEN member not notified`() =
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
            val optedOut =
                buildMember(otherMemberId).let {
                    it.copy(memberPreferences = it.memberPreferences.copy(planningChangesAlertsEnabled = false))
                }

            coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns existingOrg
            coEvery { memberSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(optedOut)

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(updatedOrg), OrganizationPayload(updatedOrg))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) {
                notificationPublisher.publish(any(), any(), any(), any(), any(), any())
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

    @Test
    fun `GIVEN organization edits breaking the form rules WHEN admin upserts THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val persisted = buildOrganization(deliveries = listOf(buildDelivery(status = DeliveryStatus.PLANNED)))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val delivery = persisted.deliveries.single()
            val invalid =
                listOf(
                    persisted.copy(name = " "),
                    persisted.copy(contactEmail = "contact@nowhere"),
                    persisted.copy(website = "amap.example.org"),
                    persisted.copy(defaultLanguage = ""),
                    persisted.copy(defaultLanguage = "français"),
                    persisted.copy(deliveries = listOf(delivery.copy(standardEndTime = "18:00"))),
                    persisted.copy(deliveries = listOf(delivery.copy(standardEndTime = "8pm"))),
                    persisted.copy(deliveries = listOf(delivery.copy(volunteerArrivalTime = "19:00"))),
                    persisted.copy(deliveries = listOf(delivery.copy(earlySlot = EarlySlot("18:30", maxVolunteers = 2)))),
                    persisted.copy(deliveries = listOf(delivery.copy(earlySlot = EarlySlot("17:30", maxVolunteers = 0)))),
                    persisted.copy(deliveries = listOf(delivery.copy(minVolunteersRequired = 0))),
                    // Basket composition: a new component needs a name (free entry), both
                    // name and weight are bounded.
                    persisted.copy(deliveries = listOf(delivery.withItem(DeliveryItem("free-1".toId(), name = " ")))),
                    persisted.copy(deliveries = listOf(delivery.withItem(DeliveryItem("free-1".toId(), name = "x".repeat(201))))),
                    persisted.copy(
                        deliveries = listOf(delivery.withItem(DeliveryItem("free-1".toId(), name = "Courge", weight = "x".repeat(201)))),
                    ),
                    // Component catalog: a name and a small SVG-only icon (the icons are stored
                    // with the whole organization, in one 400 KB DynamoDB item).
                    persisted.copy(itemTypes = listOf(ItemType("it-1".toId(), " "))),
                    persisted.copy(itemTypes = listOf(ItemType("it-1".toId(), "Brie", imageSvg = "https://x/y.png"))),
                    persisted.copy(itemTypes = listOf(ItemType("it-1".toId(), "Brie", imageSvg = "<svg>${"x".repeat(10_000)}</svg>"))),
                    // Custom alert copy is sent verbatim: a {…} placeholder would reach members as is.
                    persisted.copy(
                        notificationOverrides =
                            mapOf(
                                NotificationCategory.SLOT_CANCELLED to NotificationCopyOverride(body = "Le créneau du {date} est annulé."),
                            ),
                    ),
                    persisted.copy(
                        notificationOverrides =
                            mapOf(NotificationCategory.SLOT_CANCELLED to NotificationCopyOverride(title = "Annulation {date}")),
                    ),
                    // Only the org alerts actually sent can be customised (DELIVERY_REMINDER is never
                    // published; owner categories have no owning organization).
                    persisted.copy(
                        notificationOverrides =
                            mapOf(NotificationCategory.DELIVERY_REMINDER to NotificationCopyOverride(title = "Rappel")),
                    ),
                    persisted.copy(
                        notificationOverrides =
                            mapOf(NotificationCategory.ORGANIZATION_REQUEST_SUBMITTED to NotificationCopyOverride(body = "Nouvelle AMAP")),
                    ),
                )

            invalid.forEach { incoming ->
                val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

                assertEquals(MutationStatus.REJECTED, outcome.status, "expected rejection for $incoming")
                assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            }
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN a legacy organization with an invalid contact email WHEN an unrelated delivery field changes THEN APPLIED`() =
        runTest {
            val persisted =
                buildOrganization(deliveries = listOf(buildDelivery(status = DeliveryStatus.PLANNED)))
                    .copy(contactEmail = "legacy-without-at")
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val incoming =
                persisted.copy(deliveries = listOf(persisted.deliveries.single().copy(standardEndTime = "20:30")))

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN an account-backed producer enrolled without any product WHEN admin upserts THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val persisted = buildOrganization()
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            coEvery { producerAccountSyncDAO.findById("pa-new".toId()) } returns
                ProducerAccount(
                    producerAccountId = "pa-new".toId(),
                    name = "Ferme",
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED,
                )
            val incoming =
                persisted.copy(
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = "pa-new".toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN a newly enrolled account-backed producer WHEN admin upserts THEN its account gets the link and reaches the org scope`() =
        runTest {
            val persisted = buildOrganization()
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val account =
                ProducerAccount(
                    producerAccountId = "pa-new".toId(),
                    name = "Ferme Test",
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED,
                )
            coEvery { producerAccountSyncDAO.findById("pa-new".toId()) } returns account
            val accountSlot = slot<ProducerAccount>()
            val changesSlot = slot<List<Change>>()
            coEvery {
                producerAccountSyncDAO.put(capture(accountSlot), organizationId.toId(), capture(changesSlot))
            } returns Unit
            val incoming =
                persisted.copy(
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = "pa-new".toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                    products =
                        listOf(Product("Fromages", "pt-cheese".toId(), "pa-new".toId(), listOf(BasketSize("Petit")))),
                )

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(
                listOf(ProducerOrganization(organizationId.toId(), now, OrganizationProducerStatus.ACTIVE)),
                accountSlot.captured.organizations,
            )
            val orgChange = changesSlot.captured.single { it.scopeKey == SyncScope.Organization(organizationId).key }
            assertEquals(EntityType.ProducerAccount, orgChange.entityType)
            assertEquals(ChangeOp.UPSERT, orgChange.op)
            assertEquals("Ferme Test", (orgChange.payload as ProducerAccountPayload).producerAccount.name)
        }

    @Test
    fun `GIVEN an already linked account-backed producer WHEN an unrelated field changes THEN the producer account is not rewritten`() =
        runTest {
            val link =
                OrganizationProducer(
                    producerAccountId = "pa-new".toId(),
                    associationInstant = now,
                    status = OrganizationProducerStatus.ACTIVE,
                )
            val persisted =
                buildOrganization().copy(
                    producers = listOf(link),
                    products =
                        listOf(Product("Fromages", "pt-cheese".toId(), "pa-new".toId(), listOf(BasketSize("Petit")))),
                )
            coEvery { organizationSyncDAO.getById(any()) } returns persisted

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    buildMutation(persisted.copy(name = "Nouveau nom")),
                    OrganizationPayload(persisted.copy(name = "Nouveau nom")),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { producerAccountSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN a component added for a product of a producer not linked to the delivery WHEN upsert THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            // The delivery only carries the eggs contract of pa-1: a cheese component from
            // another producer (pa-2) does not belong to it.
            val delivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(buildContract()))
            val persisted =
                buildOrganization(deliveries = listOf(delivery)).copy(
                    products =
                        listOf(
                            Product("Oeufs", "pt-eggs".toId(), "pa-1".toId(), listOf(BasketSize("Boîte"))),
                            Product("Fromages", "pt-cheese".toId(), "pa-2".toId(), listOf(BasketSize("Petit"))),
                        ),
                )
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(listOf("coordinator-1")))
            val cheese =
                BasketDeliveryDescription(
                    productTypeId = "pt-cheese".toId(),
                    basketSizeName = "Petit",
                    items = listOf(DeliveryItem("free-1".toId(), name = "Comté")),
                )
            val incoming = persisted.copy(deliveries = listOf(delivery.copy(basketDescriptions = listOf(cheese))))

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN a component added for a product of the delivery contract producer WHEN upsert THEN APPLIED`() =
        runTest {
            val delivery = buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(buildContract()))
            val persisted =
                buildOrganization(deliveries = listOf(delivery)).copy(
                    products = listOf(Product("Oeufs", "pt-eggs".toId(), "pa-1".toId(), listOf(BasketSize("Boîte")))),
                )
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(listOf("coordinator-1")))
            val eggs =
                BasketDeliveryDescription(
                    productTypeId = "pt-eggs".toId(),
                    basketSizeName = "Boîte",
                    items = listOf(DeliveryItem("free-1".toId(), name = "Oeufs plein air")),
                )
            val incoming = persisted.copy(deliveries = listOf(delivery.copy(basketDescriptions = listOf(eggs))))

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a delivery added for a linked producer's contract WHEN admin upserts THEN its schedule is fanned out`() =
        runTest {
            val link = OrganizationProducer("pa-1".toId(), now, OrganizationProducerStatus.ACTIVE)
            val persisted = buildOrganization().copy(producers = listOf(link))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns
                listOf(buildContractDefinition(listOf("coordinator-1")))
            val fanOut = slot<List<Change>>()
            coEvery { organizationSyncDAO.put(any(), any(), capture(fanOut)) } returns Unit
            val incoming =
                persisted.copy(
                    deliveries = listOf(buildDelivery(status = DeliveryStatus.PLANNED, contracts = listOf(buildContract()))),
                )

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val change = fanOut.captured.single()
            assertEquals(EntityType.ProducerSchedule, change.entityType)
            assertEquals(SyncScope.ProducerAccount("pa-1").key, change.scopeKey)
            assertEquals(
                listOf(deliveryId),
                (change.payload as ProducerSchedulePayload).producerSchedule.deliveries.map { it.deliveryId.id },
            )
        }

    @Test
    fun `GIVEN a change the producers' schedules do not depend on WHEN upsert THEN no fan-out and no contract lookup`() =
        runTest {
            val link = OrganizationProducer("pa-1".toId(), now, OrganizationProducerStatus.ACTIVE)
            val delivery = buildDelivery(status = DeliveryStatus.PLANNED)
            val persisted = buildOrganization(deliveries = listOf(delivery)).copy(producers = listOf(link))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val fanOut = slot<List<Change>>()
            coEvery { organizationSyncDAO.put(any(), any(), capture(fanOut)) } returns Unit
            val incoming = persisted.copy(deliveries = listOf(delivery.copy(minVolunteersRequired = 3)))

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertTrue(fanOut.captured.isEmpty())
            coVerify(exactly = 0) { contractSyncDAO.getByOrganizationId(any()) }
        }

    @Test
    fun `GIVEN a legacy oversized component icon WHEN an unrelated delivery field changes THEN APPLIED`() =
        runTest {
            val persisted =
                buildOrganization(deliveries = listOf(buildDelivery(status = DeliveryStatus.PLANNED)))
                    .copy(itemTypes = listOf(ItemType("it-1".toId(), "Brie", imageSvg = "<svg>${"x".repeat(10_000)}</svg>")))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val incoming =
                persisted.copy(deliveries = listOf(persisted.deliveries.single().copy(standardEndTime = "20:30")))

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a legacy blank-named component WHEN another component is added THEN APPLIED`() =
        runTest {
            val legacy = buildDelivery(status = DeliveryStatus.PLANNED).withItem(DeliveryItem("it-legacy".toId()))
            val persisted = buildOrganization(deliveries = listOf(legacy))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val incoming =
                persisted.copy(
                    deliveries = listOf(legacy.withItem(DeliveryItem("free-1".toId(), name = "Courge", weight = "1 pièce"))),
                )

            val outcome = service.applyUpsert(adminAuth, buildMutation(incoming), OrganizationPayload(incoming))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a composition edited after the caller's cached copy WHEN a stale upsert arrives THEN the newer items are kept`() =
        runTest {
            val producerEdit =
                BasketDeliveryDescription(
                    productTypeId = "pt-1".toId(),
                    basketSizeName = "small",
                    items = listOf(DeliveryItem("brie".toId(), name = "Brie")),
                    itemsUpdatedAt = Instant.parse("2026-10-01T11:00:00Z"),
                )
            val delivery = buildDelivery(status = DeliveryStatus.PLANNED)
            val persisted =
                buildOrganization(deliveries = listOf(delivery.copy(basketDescriptions = listOf(producerEdit))))
                    .copy(itemTypes = listOf(ItemType("brie".toId(), "Brie")))
            coEvery { organizationSyncDAO.getById(any()) } returns persisted
            val written = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(written), any(), any()) } returns Unit
            // The coordinator's cache predates the producer's edit: no item, no timestamp, no icon.
            val stale =
                persisted.copy(
                    itemTypes = emptyList(),
                    deliveries =
                        listOf(
                            delivery.copy(
                                minVolunteersRequired = 3,
                                basketDescriptions = listOf(producerEdit.copy(items = emptyList(), itemsUpdatedAt = null)),
                            ),
                        ),
                )

            val outcome = service.applyUpsert(adminAuth, buildMutation(stale), OrganizationPayload(stale))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val saved = written.captured.deliveries.single()
            assertEquals(3, saved.minVolunteersRequired)
            assertEquals(listOf(producerEdit), saved.basketDescriptions)
            assertEquals(listOf("brie"), written.captured.itemTypes.map { it.id.id })
        }

    private fun Delivery.withItem(item: DeliveryItem): Delivery {
        val description =
            basketDescriptions.firstOrNull()
                ?: BasketDeliveryDescription(productTypeId = "pt-1".toId(), basketSizeName = "small")
        return copy(basketDescriptions = listOf(description.copy(items = description.items + item)))
    }
}

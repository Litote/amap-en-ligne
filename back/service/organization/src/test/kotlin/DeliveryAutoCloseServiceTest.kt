package organization

import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivityType
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Instant

internal class DeliveryAutoCloseServiceTest {
    private val organizationId = "org-1"
    private val producerId = "producer-1"
    private val contractId = "contract-1"
    private val longAgo = Instant.parse("2026-01-01T00:00:00Z")

    // 2026-10-15T00:30 Europe/Paris (CEST, UTC+2) = 2026-10-14T22:30Z: already the 15th in
    // Paris while it is still the 14th in UTC.
    private val parisMidnightPast = Instant.parse("2026-10-14T22:30:00Z")

    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val contractSyncDAO = mockk<ContractSyncDAO>()

    private val service = DeliveryAutoCloseService(organizationSyncDAO, contractSyncDAO)

    @BeforeEach
    fun setUp() {
        coEvery { contractSyncDAO.getByOrganizationId(organizationId.toId()) } returns listOf(contract())
    }

    private fun givenOrganization(vararg deliveries: Delivery): Organization {
        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP des Collines",
                contactEmail = "contact@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = longAgo,
                lastUpdatedInstant = longAgo,
                producers =
                    listOf(
                        OrganizationProducer(
                            producerAccountId = producerId.toId(),
                            associationInstant = longAgo,
                            status = OrganizationProducerStatus.ACTIVE,
                        ),
                    ),
                deliveries = deliveries.toList(),
            )
        coEvery { organizationSyncDAO.listAll() } returns listOf(organization)
        coEvery { organizationSyncDAO.getById(organizationId.toId()) } returns organization
        return organization
    }

    private fun delivery(
        id: String,
        scheduledDate: String,
        status: DeliveryStatus = DeliveryStatus.PLANNED,
        registrations: List<MemberRegistration> = emptyList(),
    ): Delivery =
        Delivery(
            deliveryId = id.toId(),
            organizationId = organizationId.toId(),
            scheduledDate = LocalDateTime.parse(scheduledDate),
            status = status,
            minVolunteersRequired = 2,
            contracts =
                listOf(
                    DeliveryContract(
                        contractId = contractId.toId(),
                        coordinators = emptyList(),
                        basketQuantity = 10,
                        deliveryDescription = "Weekly basket",
                        status = DeliveryContractStatus.PENDING,
                        slots =
                            listOf(
                                MemberSlot(
                                    slotId = "slot-$id",
                                    startTime = LocalDateTime.parse(scheduledDate),
                                    endTime = LocalDateTime.parse(scheduledDate),
                                    activityType = ActivityType.RECEPTION,
                                    requiredVolunteers = 2,
                                    currentRegistrations = registrations.size,
                                    status = SlotStatus.OPEN,
                                    registrations = registrations,
                                ),
                            ),
                    ),
                ),
        )

    private fun contract(): Contract =
        Contract(
            contractId = contractId.toId(),
            name = "Légumes",
            organizationId = organizationId.toId(),
            producerAccountId = producerId.toId(),
            minDeliveryDate = LocalDate.parse("2026-01-01"),
            maxDeliveryDate = LocalDate.parse("2026-12-31"),
            deliveryCount = 40,
            seasonYear = 2026,
            status = ContractStatus.ACTIVE,
        )

    private fun capturedWrite(): Triple<Organization, Change, List<Change>> {
        val organization = slot<Organization>()
        val change = slot<Change>()
        val fanOut = slot<List<Change>>()
        coVerify(exactly = 1) { organizationSyncDAO.put(capture(organization), capture(change), capture(fanOut)) }
        return Triple(organization.captured, change.captured, fanOut.captured)
    }

    private fun Organization.statusOf(id: String) = deliveries.single { it.deliveryId.id == id }.status

    @Test
    fun `GIVEN active deliveries before today in the organization timezone WHEN run THEN they are closed and later ones kept`() =
        runTest {
            givenOrganization(
                delivery("planned-past", "2026-10-07T19:00:00", DeliveryStatus.PLANNED),
                delivery("confirmed-past", "2026-10-13T19:00:00", DeliveryStatus.CONFIRMED),
                delivery("in-progress-past", "2026-10-14T19:00:00", DeliveryStatus.IN_PROGRESS),
                delivery("today", "2026-10-15T19:00:00", DeliveryStatus.PLANNED),
                delivery("future", "2026-10-21T19:00:00", DeliveryStatus.PLANNED),
            )

            service.run(parisMidnightPast)

            val (written, _, _) = capturedWrite()
            assertEquals(DeliveryStatus.COMPLETED, written.statusOf("planned-past"))
            assertEquals(DeliveryStatus.COMPLETED, written.statusOf("confirmed-past"))
            // The 14th is already past in Paris (00:30 on the 15th) though not in UTC.
            assertEquals(DeliveryStatus.COMPLETED, written.statusOf("in-progress-past"))
            assertEquals(DeliveryStatus.PLANNED, written.statusOf("today"))
            assertEquals(DeliveryStatus.PLANNED, written.statusOf("future"))
            assertEquals(parisMidnightPast, written.lastUpdatedInstant)
        }

    @Test
    fun `GIVEN the delivery day itself WHEN run THEN the delivery is not closed yet`() =
        runTest {
            givenOrganization(delivery("tonight", "2026-10-15T19:00:00"))

            // 23:59 in Paris on the delivery day.
            service.run(Instant.parse("2026-10-15T21:59:00Z"))

            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN only cancelled, completed or future deliveries WHEN run THEN nothing is written`() =
        runTest {
            givenOrganization(
                delivery("cancelled", "2026-10-07T19:00:00", DeliveryStatus.CANCELLED),
                delivery("completed", "2026-10-08T19:00:00", DeliveryStatus.COMPLETED),
                delivery("future", "2026-10-21T19:00:00"),
            )

            service.run(parisMidnightPast)

            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN unrecorded registrations WHEN the delivery is closed THEN they are left untouched`() =
        runTest {
            val registration =
                MemberRegistration(
                    memberId = "member-1".toId(),
                    displayName = "member-1",
                    memberEmail = "member-1@example.com",
                    registrationInstant = longAgo,
                    status = RegistrationStatus.REGISTERED,
                )
            val original = givenOrganization(delivery("past", "2026-10-07T19:00:00", registrations = listOf(registration)))

            service.run(parisMidnightPast)

            val (written, _, _) = capturedWrite()
            val closed = written.deliveries.single()
            assertEquals(DeliveryStatus.COMPLETED, closed.status)
            assertEquals(original.deliveries.single().contracts, closed.contracts)
        }

    @Test
    fun `GIVEN a closed delivery WHEN written THEN the organization scope and the producer schedule get a change`() =
        runTest {
            givenOrganization(delivery("past", "2026-10-07T19:00:00"))

            service.run(parisMidnightPast)

            val (written, change, fanOut) = capturedWrite()
            assertEquals(SyncScope.Organization(organizationId).key, change.scopeKey)
            assertEquals(EntityType.Organization, change.entityType)
            assertEquals(ChangeOp.UPSERT, change.op)
            assertEquals(written, (change.payload as OrganizationPayload).organization)
            val producerChange = fanOut.single()
            assertEquals(EntityType.ProducerSchedule, producerChange.entityType)
            assertEquals(SyncScope.ProducerAccount(producerId).key, producerChange.scopeKey)
        }

    @Test
    fun `GIVEN one organization failing WHEN run THEN the others are still processed`() =
        runTest {
            val good = givenOrganization(delivery("past", "2026-10-07T19:00:00"))
            val broken = good.copy(organizationId = "org-broken".toId())
            coEvery { organizationSyncDAO.listAll() } returns listOf(broken, good)
            coEvery { organizationSyncDAO.getById("org-broken".toId()) } throws IllegalStateException("boom")

            service.run(parisMidnightPast)

            val (written, _, _) = capturedWrite()
            assertTrue(written.deliveries.all { it.status == DeliveryStatus.COMPLETED })
        }
}

package core

import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.changes.ChangeOp
import persistence.changes.ProducerSchedulePayload
import persistence.model.ActivityType
import persistence.model.BasketDeliveryDescription
import persistence.model.BasketSize
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
import persistence.model.Product
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

internal class ProducerScheduleProjectionTest {
    private val epoch = Instant.fromEpochMilliseconds(0)

    private fun contract(
        id: String,
        producer: String,
        name: String = "Contrat $id",
    ) = Contract(
        contractId = id.toId(),
        name = name,
        organizationId = "org-1".toId(),
        producerAccountId = producer.toId(),
        minDeliveryDate = LocalDate.parse("2026-01-01"),
        maxDeliveryDate = LocalDate.parse("2026-12-31"),
        deliveryCount = 10,
        seasonYear = 2026,
    )

    private fun delivery(
        id: String,
        date: String,
        vararg contractIds: String,
        registrations: List<MemberRegistration> = emptyList(),
    ) = Delivery(
        deliveryId = id.toId(),
        organizationId = "org-1".toId(),
        scheduledDate = LocalDateTime.parse(date),
        status = DeliveryStatus.PLANNED,
        minVolunteersRequired = 2,
        contracts =
            contractIds.map { contractId ->
                DeliveryContract(
                    contractId = contractId.toId(),
                    coordinators = listOf("coordinator-1".toId()),
                    basketQuantity = 12,
                    deliveryDescription = "",
                    status = DeliveryContractStatus.PENDING,
                    slots =
                        listOf(
                            MemberSlot(
                                slotId = "slot-$id",
                                startTime = LocalDateTime.parse(date),
                                endTime = LocalDateTime.parse(date),
                                activityType = ActivityType.RECEPTION,
                                requiredVolunteers = 2,
                                currentRegistrations = registrations.size,
                                status = SlotStatus.OPEN,
                                slotKind = SlotKind.STANDARD,
                                registrations = registrations,
                            ),
                        ),
                )
            },
        basketDescriptions =
            listOf(
                BasketDeliveryDescription(productTypeId = "pt-eggs".toId(), basketSizeName = "Boîte"),
                BasketDeliveryDescription(productTypeId = "pt-cheese".toId(), basketSizeName = "Petit"),
            ),
    )

    private fun organization(
        deliveries: List<Delivery>,
        cheeseLink: OrganizationProducerStatus = OrganizationProducerStatus.ACTIVE,
    ) = Organization(
        organizationId = "org-1".toId(),
        name = "AMAP des Collines",
        contactEmail = "amap@example.com",
        activeStatus = true,
        timezone = TimeZone.of("Europe/Paris"),
        defaultLanguage = "fr",
        createdInstant = epoch,
        lastUpdatedInstant = epoch,
        producers =
            listOf(
                OrganizationProducer("pa-eggs".toId(), epoch, OrganizationProducerStatus.ACTIVE),
                OrganizationProducer("pa-cheese".toId(), epoch, cheeseLink),
            ),
        products =
            listOf(
                Product("Oeufs", "pt-eggs".toId(), "pa-eggs".toId(), listOf(BasketSize("Boîte"))),
                Product("Fromages", "pt-cheese".toId(), "pa-cheese".toId(), listOf(BasketSize("Petit"))),
            ),
        deliveries = deliveries,
    )

    private val contracts = listOf(contract("c-eggs", "pa-eggs", "Oeufs 2026"), contract("c-cheese", "pa-cheese"))

    @Test
    fun `GIVEN deliveries of two producers WHEN building a schedule THEN only its own deliveries, without personal data`() {
        val org =
            organization(
                listOf(
                    delivery("d-2", "2026-10-08T18:00:00", "c-eggs"),
                    delivery("d-1", "2026-10-01T18:00:00", "c-eggs", "c-cheese"),
                    delivery("d-3", "2026-10-15T18:00:00", "c-cheese"),
                ),
            )

        val schedule = ProducerScheduleProjection.build(org, contracts, "pa-eggs".toId())!!

        assertEquals("AMAP des Collines", schedule.organizationName)
        assertEquals(listOf("d-1", "d-2"), schedule.deliveries.map { it.deliveryId.id })
        val first = schedule.deliveries.first()
        assertEquals(listOf("c-eggs"), first.contracts.map { it.contractId.id })
        assertEquals("Oeufs 2026", first.contracts.single().contractName)
        assertEquals(12, first.contracts.single().basketQuantity)
        assertEquals(listOf("pt-eggs"), first.basketDescriptions.map { it.productTypeId.id })
    }

    @Test
    fun `GIVEN a terminated or missing link WHEN building a schedule THEN none`() {
        val org = organization(emptyList(), cheeseLink = OrganizationProducerStatus.TERMINATED)

        assertNull(ProducerScheduleProjection.build(org, contracts, "pa-cheese".toId()))
        assertNull(ProducerScheduleProjection.build(org, contracts, "pa-unknown".toId()))
    }

    @Test
    fun `GIVEN only a volunteer registration changes WHEN comparing THEN the relevant part and the changes are unchanged`() {
        val before = organization(listOf(delivery("d-1", "2026-10-01T18:00:00", "c-eggs")))
        val registration =
            MemberRegistration(
                memberId = "m-1".toId(),
                displayName = "Alice",
                memberEmail = "alice@example.com",
                registrationInstant = epoch,
                status = RegistrationStatus.REGISTERED,
            )
        val after = organization(listOf(delivery("d-1", "2026-10-01T18:00:00", "c-eggs", registrations = listOf(registration))))

        assertEquals(ProducerScheduleProjection.relevantPart(before), ProducerScheduleProjection.relevantPart(after))
        assertTrue(ProducerScheduleProjection.changes(before, contracts, after, contracts).isEmpty())
    }

    @Test
    fun `GIVEN a new delivery for one producer WHEN computing changes THEN one upsert on that producer's scope only`() {
        val before = organization(listOf(delivery("d-1", "2026-10-01T18:00:00", "c-eggs")))
        val after = organization(before.deliveries + delivery("d-2", "2026-10-08T18:00:00", "c-eggs"))

        val changes = ProducerScheduleProjection.changes(before, contracts, after, contracts)

        val change = changes.single()
        assertEquals("producer-account:pa-eggs", change.scopeKey)
        assertEquals(EntityType.ProducerSchedule, change.entityType)
        assertEquals("org-1", change.entityId)
        assertEquals(ChangeOp.UPSERT, change.op)
        assertEquals(2, (change.payload as ProducerSchedulePayload).producerSchedule.deliveries.size)
    }

    @Test
    fun `GIVEN a producer link terminated WHEN computing changes THEN a delete tombstone on its scope`() {
        val before = organization(emptyList())
        val after = organization(emptyList(), cheeseLink = OrganizationProducerStatus.TERMINATED)

        val change = ProducerScheduleProjection.changes(before, contracts, after, contracts).single()

        assertEquals("producer-account:pa-cheese", change.scopeKey)
        assertEquals(ChangeOp.DELETE, change.op)
        assertNull(change.payload)
    }

    @Test
    fun `GIVEN a contract renamed WHEN computing changes THEN its producer's schedule is updated`() {
        val org = organization(listOf(delivery("d-1", "2026-10-01T18:00:00", "c-eggs")))
        val renamed = contracts.map { if (it.contractId.id == "c-eggs") it.copy(name = "Oeufs bio") else it }

        val change = ProducerScheduleProjection.changes(org, contracts, org, renamed).single()

        assertEquals("producer-account:pa-eggs", change.scopeKey)
        assertEquals(
            "Oeufs bio",
            (change.payload as ProducerSchedulePayload)
                .producerSchedule.deliveries
                .single()
                .contracts
                .single()
                .contractName,
        )
    }

    @Test
    fun `GIVEN a contract activated WHEN computing changes THEN its producer's schedule carries the new contract status`() {
        val org = organization(listOf(delivery("d-1", "2026-10-01T18:00:00", "c-eggs")))
        val activated = contracts.map { if (it.contractId.id == "c-eggs") it.copy(status = ContractStatus.ACTIVE) else it }

        val before = ProducerScheduleProjection.build(org, contracts, "pa-eggs".toId())!!
        val change = ProducerScheduleProjection.changes(org, contracts, org, activated).single()

        assertEquals(
            ContractStatus.IN_PREPARATION,
            before.deliveries
                .single()
                .contracts
                .single()
                .contractStatus,
        )
        assertEquals(
            ContractStatus.ACTIVE,
            (change.payload as ProducerSchedulePayload)
                .producerSchedule.deliveries
                .single()
                .contracts
                .single()
                .contractStatus,
        )
    }
}

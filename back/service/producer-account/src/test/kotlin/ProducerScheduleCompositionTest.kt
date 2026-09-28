@file:OptIn(kotlin.time.ExperimentalTime::class)

package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.changes.Change
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerSchedulePayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketDeliveryDescription
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryItem
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.ItemType
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerSchedule
import persistence.model.Product
import persistence.model.ProductType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Instant

/** A producer edits the basket composition of its own products through its schedule. */
internal class ProducerScheduleCompositionTest {
    private val epoch = Instant.fromEpochMilliseconds(0)
    private val edited = Instant.parse("2026-10-01T11:00:00Z")

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "sub-1",
            firstName = "Ferme",
            lastName = "",
            email = "ferme@example.com",
            producerAccountId = "pa-cheese",
            roles = listOf(Role.PRODUCER),
        )

    private fun description(
        product: String,
        size: String,
        vararg items: String,
        at: Instant? = null,
    ) = BasketDeliveryDescription(
        productTypeId = product.toId(),
        basketSizeName = size,
        items = items.map { DeliveryItem(itemTypeId = it.toId(), name = it) },
        itemsUpdatedAt = at,
    )

    private fun delivery(
        status: DeliveryStatus = DeliveryStatus.PLANNED,
        contractIds: List<String> = listOf("c-cheese", "c-eggs"),
        descriptions: List<BasketDeliveryDescription> =
            listOf(description("pt-cheese", "Petit"), description("pt-eggs", "Boîte", "oeufs")),
    ) = Delivery(
        deliveryId = "d-1".toId(),
        organizationId = "org-1".toId(),
        scheduledDate = LocalDateTime.parse("2026-10-08T18:00:00"),
        status = status,
        minVolunteersRequired = 2,
        contracts =
            contractIds.map {
                DeliveryContract(
                    contractId = it.toId(),
                    basketQuantity = 12,
                    deliveryDescription = "",
                    status = DeliveryContractStatus.PENDING,
                )
            },
        basketDescriptions = descriptions,
    )

    private fun organization(
        delivery: Delivery = delivery(),
        cheeseLink: OrganizationProducerStatus = OrganizationProducerStatus.ACTIVE,
    ) = Organization(
        organizationId = "org-1".toId(),
        name = "AMAP",
        contactEmail = "amap@example.com",
        activeStatus = true,
        timezone = TimeZone.of("Europe/Paris"),
        defaultLanguage = "fr",
        createdInstant = epoch,
        lastUpdatedInstant = epoch,
        producers =
            listOf(
                OrganizationProducer("pa-cheese".toId(), epoch, cheeseLink),
                OrganizationProducer("pa-eggs".toId(), epoch, OrganizationProducerStatus.ACTIVE),
            ),
        products =
            listOf(
                Product("Fromages", "pt-cheese".toId(), "pa-cheese".toId(), listOf(BasketSize("Petit"), BasketSize("Grand"))),
                Product("Oeufs", "pt-eggs".toId(), "pa-eggs".toId(), listOf(BasketSize("Boîte"))),
            ),
        deliveries = listOf(delivery),
    )

    private fun contract(
        id: String,
        producer: String,
    ) = Contract(
        contractId = id.toId(),
        name = "Contrat $id",
        organizationId = "org-1".toId(),
        producerAccountId = producer.toId(),
        minDeliveryDate = LocalDate.parse("2026-01-01"),
        maxDeliveryDate = LocalDate.parse("2026-12-31"),
        deliveryCount = 10,
        seasonYear = 2026,
    )

    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val contractSyncDAO =
        mockk<ContractSyncDAO> {
            coEvery { getByOrganizationId(any()) } returns listOf(contract("c-cheese", "pa-cheese"), contract("c-eggs", "pa-eggs"))
        }
    private val productTypeDAO =
        mockk<ProductTypeSyncDAO> {
            coEvery { getByProducerAccountId(any()) } returns
                listOf(
                    ProductType(
                        productTypeId = "pt-cheese".toId(),
                        producerAccountId = "pa-cheese".toId(),
                        supportedBasketSizes = listOf(BasketSize("Petit")),
                        name = "Fromages",
                        itemTypes = listOf(ItemType("brie".toId(), "brie", imageSvg = "<svg/>")),
                    ),
                )
        }
    private val service = ProducerScheduleService(organizationSyncDAO, contractSyncDAO, productTypeDAO)

    private fun stored(organization: Organization = organization()) {
        coEvery { organizationSyncDAO.getById("org-1".toId()) } returns organization
    }

    /** The producer's schedule with [descriptions] as the composition of its products on d-1. */
    private fun schedule(
        descriptions: List<BasketDeliveryDescription>,
        producer: String = "pa-cheese",
        organization: Organization = organization(),
    ): ProducerSchedulePayload {
        val base = requireNotNull(core.ProducerScheduleProjection.build(organization, contractSyncDAOContracts, producer.toId()))
        return ProducerSchedulePayload(
            base.copy(deliveries = base.deliveries.map { it.copy(basketDescriptions = descriptions) }),
        )
    }

    private val contractSyncDAOContracts = listOf(contract("c-cheese", "pa-cheese"), contract("c-eggs", "pa-eggs"))

    private suspend fun upsert(
        payload: ProducerSchedulePayload,
        auth: AuthenticatedInfo = producerAuth,
    ) = service.applyUpsert(auth, ClientMutation("op-1", Upsert(payload)), payload)

    @Test
    fun `GIVEN a composition of its own product WHEN the producer saves it THEN it is written into the organization`() =
        runTest {
            stored()
            val written = slot<Organization>()
            val change = slot<Change>()
            val fanOut = slot<List<Change>>()
            coEvery { organizationSyncDAO.put(capture(written), capture(change), capture(fanOut)) } returns Unit

            val outcome = upsert(schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited))))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals("org-1", outcome.serverEntityId)
            val descriptions =
                written.captured.deliveries
                    .single()
                    .basketDescriptions
            assertEquals(
                listOf(description("pt-cheese", "Petit", "brie", at = edited), description("pt-eggs", "Boîte", "oeufs")),
                descriptions,
            )
            // Its icon joins the organization catalog, members resolve it from there.
            assertEquals(listOf(ItemType("brie".toId(), "brie", imageSvg = "<svg/>")), written.captured.itemTypes)
            assertEquals(EntityType.Organization, change.captured.entityType)
            assertEquals(SyncScope.Organization("org-1").key, change.captured.scopeKey)
            assertEquals(written.captured, (change.captured.payload as OrganizationPayload).organization)
            // The producer's own schedule is updated in the same write.
            assertTrue(fanOut.captured.any { it.scopeKey == SyncScope.ProducerAccount("pa-cheese").key })
        }

    @Test
    fun `GIVEN a description the producer's copy lacks WHEN saved THEN the stored one is kept`() =
        runTest {
            stored(organization(delivery(descriptions = listOf(description("pt-cheese", "Grand", "tomme")))))
            val written = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(written), any(), any()) } returns Unit

            upsert(
                schedule(
                    listOf(description("pt-cheese", "Petit", "brie", at = edited)),
                    organization = organization(delivery(descriptions = emptyList())),
                ),
            )

            assertEquals(
                listOf("Grand", "Petit"),
                written.captured.deliveries
                    .single()
                    .basketDescriptions
                    .map { it.basketSizeName },
            )
        }

    @Test
    fun `GIVEN a stale copy WHEN saved THEN the stored newer items are kept`() =
        runTest {
            val newer = description("pt-cheese", "Petit", "brie", at = edited)
            stored(organization(delivery(descriptions = listOf(newer))))

            val outcome = upsert(schedule(listOf(description("pt-cheese", "Petit", "comte", at = epoch))))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN another producer's product WHEN saved THEN FORBIDDEN`() =
        runTest {
            stored()

            val outcome = upsert(schedule(listOf(description("pt-eggs", "Boîte", "oeufs", "poule", at = edited))))

            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN someone else's schedule or a non-producer caller WHEN saved THEN FORBIDDEN`() =
        runTest {
            stored()
            val payload = schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited)))

            assertEquals(
                MutationErrorCode.FORBIDDEN,
                upsert(payload, producerAuth.copy(producerAccountId = "pa-eggs")).error?.code,
            )
            assertEquals(
                MutationErrorCode.FORBIDDEN,
                upsert(payload, producerAuth.copy(roles = listOf(Role.COORDINATOR))).error?.code,
            )
        }

    @Test
    fun `GIVEN a terminated link WHEN saved THEN FORBIDDEN`() =
        runTest {
            val payload = schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited)))
            stored(organization(cheeseLink = OrganizationProducerStatus.TERMINATED))

            assertEquals(MutationErrorCode.FORBIDDEN, upsert(payload).error?.code)
        }

    @Test
    fun `GIVEN an unknown organization WHEN saved THEN NOT_FOUND`() =
        runTest {
            val payload = schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited)))
            coEvery { organizationSyncDAO.getById(any()) } returns null

            assertEquals(MutationErrorCode.NOT_FOUND, upsert(payload).error?.code)
        }

    @Test
    fun `GIVEN a delivery without any of its contracts WHEN saved THEN FORBIDDEN`() =
        runTest {
            val payload = schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited)))
            stored(organization(delivery(contractIds = listOf("c-eggs"))))

            assertEquals(MutationErrorCode.FORBIDDEN, upsert(payload).error?.code)
        }

    @Test
    fun `GIVEN a completed delivery WHEN its composition changes THEN INVALID_PAYLOAD`() =
        runTest {
            val payload = schedule(listOf(description("pt-cheese", "Petit", "brie", at = edited)))
            stored(organization(delivery(status = DeliveryStatus.COMPLETED)))

            assertEquals(MutationErrorCode.INVALID_PAYLOAD, upsert(payload).error?.code)
        }

    @Test
    fun `GIVEN a blank component or an unknown basket size WHEN saved THEN INVALID_PAYLOAD`() =
        runTest {
            stored()

            assertEquals(
                MutationErrorCode.INVALID_PAYLOAD,
                upsert(schedule(listOf(description("pt-cheese", "Petit", " ", at = edited)))).error?.code,
            )
            assertEquals(
                MutationErrorCode.INVALID_PAYLOAD,
                upsert(schedule(listOf(description("pt-cheese", "XXL", "brie", at = edited)))).error?.code,
            )
        }

    @Test
    fun `GIVEN an unchanged schedule WHEN saved THEN APPLIED without any write`() =
        runTest {
            stored()

            val outcome = upsert(schedule(listOf(description("pt-cheese", "Petit"))))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any(), any()) }
        }
}

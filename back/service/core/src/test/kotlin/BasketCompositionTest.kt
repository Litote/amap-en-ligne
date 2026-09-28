@file:OptIn(kotlin.time.ExperimentalTime::class)

package core

import id.toId
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.model.BasketDeliveryDescription
import persistence.model.BasketSize
import persistence.model.Delivery
import persistence.model.DeliveryItem
import persistence.model.DeliveryStatus
import persistence.model.ItemType
import persistence.model.Organization
import persistence.model.ProductType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Instant

internal class BasketCompositionTest {
    private val epoch = Instant.fromEpochMilliseconds(0)
    private val older = Instant.parse("2026-10-01T10:00:00Z")
    private val newer = Instant.parse("2026-10-01T11:00:00Z")

    private fun description(
        items: List<String>,
        at: Instant?,
        product: String = "pt-cheese",
    ) = BasketDeliveryDescription(
        productTypeId = product.toId(),
        basketSizeName = "Petit",
        items = items.map { DeliveryItem(itemTypeId = it.toId(), name = it) },
        itemsUpdatedAt = at,
    )

    private fun organization(vararg descriptions: BasketDeliveryDescription) =
        Organization(
            organizationId = "org-1".toId(),
            name = "AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = epoch,
            lastUpdatedInstant = epoch,
            deliveries =
                listOf(
                    Delivery(
                        deliveryId = "d-1".toId(),
                        organizationId = "org-1".toId(),
                        scheduledDate = LocalDateTime.parse("2026-10-08T18:00"),
                        status = DeliveryStatus.PLANNED,
                        minVolunteersRequired = 0,
                        basketDescriptions = descriptions.toList(),
                    ),
                ),
        )

    private fun Organization.onlyDescription() = deliveries.single().basketDescriptions.single()

    @Test
    fun `GIVEN a stale copy with older items WHEN merged THEN the stored newer items are kept`() {
        val stored = organization(description(listOf("brie"), newer))
        val stale = organization(description(listOf("comte"), older))

        assertEquals(description(listOf("brie"), newer), BasketComposition.keepNewestItems(stored, stale).onlyDescription())
    }

    @Test
    fun `GIVEN a copy without timestamp over timestamped items WHEN merged THEN the stored items are kept`() {
        val stored = organization(description(listOf("brie"), older))
        val legacy = organization(description(emptyList(), null))

        assertEquals(
            listOf("brie"),
            BasketComposition
                .keepNewestItems(stored, legacy)
                .onlyDescription()
                .items
                .map { it.name },
        )
    }

    @Test
    fun `GIVEN a newer edit WHEN merged THEN the incoming items win`() {
        val stored = organization(description(listOf("brie"), older))
        val edit = organization(description(listOf("comte"), newer))

        assertEquals(description(listOf("comte"), newer), BasketComposition.keepNewestItems(stored, edit).onlyDescription())
    }

    @Test
    fun `GIVEN no timestamp on either side WHEN merged THEN the incoming items win (legacy)`() {
        val stored = organization(description(listOf("brie"), null))
        val edit = organization(description(listOf("comte"), null))

        assertEquals(
            listOf("comte"),
            BasketComposition
                .keepNewestItems(stored, edit)
                .onlyDescription()
                .items
                .map { it.name },
        )
    }

    @Test
    fun `GIVEN a description removed or added by the incoming write WHEN merged THEN the incoming set is kept`() {
        val stored = organization(description(listOf("brie"), newer))
        val incoming = organization(description(listOf("oeuf"), null, product = "pt-eggs"))

        val merged = BasketComposition.keepNewestItems(stored, incoming).onlyDescription()

        assertEquals("pt-eggs", merged.productTypeId.id)
    }

    @Test
    fun `GIVEN a stale copy missing catalog entries WHEN merged THEN the stored entries are kept`() {
        val stored = organization().copy(itemTypes = listOf(ItemType("brie".toId(), "Brie")))
        val stale = organization().copy(itemTypes = listOf(ItemType("comte".toId(), "Comté")))

        assertEquals(
            listOf("brie", "comte"),
            BasketComposition.keepNewestItems(stored, stale).itemTypes.map { it.id.id },
        )
    }

    @Test
    fun `GIVEN no stored organization WHEN merged THEN the incoming one is returned`() {
        val incoming = organization(description(listOf("brie"), null))

        assertEquals(incoming, BasketComposition.keepNewestItems(null, incoming))
    }

    @Test
    fun `GIVEN a new component without name WHEN checked THEN it is rejected, legacy ones are not`() {
        val legacy = BasketDeliveryDescription("pt".toId(), "Petit", listOf(DeliveryItem("i1".toId(), name = "")))
        val newBlank = legacy.copy(items = legacy.items + DeliveryItem("i2".toId(), name = " "))

        assertNull(BasketComposition.itemsError(listOf(legacy), listOf(legacy), "delivery"))
        assertNotNull(BasketComposition.itemsError(listOf(legacy), listOf(newBlank), "delivery"))
    }

    @Test
    fun `GIVEN used components WHEN merging the catalog THEN their latest definitions are added once`() {
        val catalog = listOf(ItemType("brie".toId(), "Brie (old)"), ItemType("other".toId(), "Autre"))
        val productType =
            ProductType(
                productTypeId = "pt-cheese".toId(),
                producerAccountId = "pa".toId(),
                supportedBasketSizes = listOf(BasketSize("Petit")),
                name = "Fromages",
                itemTypes = listOf(ItemType("brie".toId(), "Brie"), ItemType("unused".toId(), "Tomme")),
            )

        val merged = BasketComposition.mergedItemTypes(catalog, listOf(description(listOf("brie"), null)), listOf(productType))

        assertEquals(listOf("brie" to "Brie", "other" to "Autre"), merged.map { it.id.id to it.name })
    }
}

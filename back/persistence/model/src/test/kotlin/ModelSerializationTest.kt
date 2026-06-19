package persistence.model

import id.toId
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

private val json =
    Json {
        explicitNulls = false
        ignoreUnknownKeys = true
    }

internal class ModelSerializationTest {
    @Test
    fun `GIVEN ProductType with itemTypes WHEN serialized and deserialized THEN round-trips correctly`() {
        val pt =
            ProductType(
                productTypeId = "pt-1".toId(),
                producerAccountId = "pa-1".toId(),
                name = "Légumes",
                itemTypes =
                    listOf(
                        ItemType(id = "it-1".toId(), name = "Carottes", imageSvg = "<svg><circle/></svg>"),
                        ItemType(id = "it-2".toId(), name = "Courgettes"),
                    ),
            )

        val encoded = json.encodeToString(ProductType.serializer(), pt)
        val decoded = json.decodeFromString(ProductType.serializer(), encoded)
        assertEquals(pt, decoded)
        assertEquals(2, decoded.itemTypes.size)
        assertEquals("Carottes", decoded.itemTypes[0].name)
        assertEquals("<svg><circle/></svg>", decoded.itemTypes[0].imageSvg)
        assertNull(decoded.itemTypes[1].imageSvg)
    }

    @Test
    fun `GIVEN ProductType with itemTypes WHEN serialized THEN wire keys are snake_case`() {
        val pt =
            ProductType(
                productTypeId = "pt-1".toId(),
                producerAccountId = "pa-1".toId(),
                name = "Légumes",
                itemTypes = listOf(ItemType(id = "it-1".toId(), name = "Carottes", imageSvg = "<svg></svg>")),
            )
        val encoded = json.encodeToString(ProductType.serializer(), pt)
        assertTrue(encoded.contains("item_types"), "expected item_types but got: $encoded")
        assertTrue(encoded.contains("image_svg"), "expected image_svg but got: $encoded")
    }

    @Test
    fun `GIVEN ProductType JSON without itemTypes WHEN deserialized THEN itemTypes is empty`() {
        val jsonStr = """{"product_type_id":"pt-1","producer_account_id":"pa-1","name":"Oeufs"}"""
        val pt = json.decodeFromString(ProductType.serializer(), jsonStr)
        assertTrue(pt.itemTypes.isEmpty())
    }

    @Test
    fun `GIVEN BasketDeliveryDescription with items WHEN serialized and deserialized THEN round-trips correctly`() {
        val desc =
            BasketDeliveryDescription(
                productTypeId = "pt-1".toId(),
                basketSizeName = "Moyen",
                items =
                    listOf(
                        DeliveryItem(itemTypeId = "it-1".toId(), name = "Carottes", weight = "500g"),
                        DeliveryItem(itemTypeId = "it-2".toId(), name = "Courgettes"),
                    ),
            )

        val encoded = json.encodeToString(BasketDeliveryDescription.serializer(), desc)
        assertTrue(encoded.contains("\"product_type_id\""))
        assertTrue(encoded.contains("\"basket_size_name\""))
        assertTrue(encoded.contains("\"item_type_id\""))
        assertTrue(encoded.contains("\"weight\""))
        // The heavy SVG is never embedded in a delivery item.
        assertTrue(!encoded.contains("image_svg"))

        val decoded = json.decodeFromString(BasketDeliveryDescription.serializer(), encoded)
        assertEquals(desc, decoded)
        assertEquals("Carottes", decoded.items[0].name)
        assertEquals("500g", decoded.items[0].weight)
        assertNull(decoded.items[1].weight)
    }

    @Test
    fun `GIVEN Organization with item_types catalog WHEN serialized and deserialized THEN round-trips`() {
        val org =
            Organization(
                organizationId = "org-1".toId(),
                name = "AMAP test",
                contactEmail = "test@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = Instant.fromEpochMilliseconds(0),
                lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
                itemTypes =
                    listOf(
                        ItemType(id = "it-1".toId(), name = "Carottes", imageSvg = "<svg></svg>"),
                        ItemType(id = "it-2".toId(), name = "Courgettes"),
                    ),
            )
        val encoded = json.encodeToString(Organization.serializer(), org)
        assertTrue(encoded.contains("\"item_types\""))
        assertTrue(encoded.contains("image_svg"))
        val decoded = json.decodeFromString(Organization.serializer(), encoded)
        assertEquals(org, decoded)
        assertEquals("<svg></svg>", decoded.itemTypes[0].imageSvg)
        assertNull(decoded.itemTypes[1].imageSvg)
    }

    @Test
    fun `GIVEN Organization JSON without item_types WHEN deserialized THEN catalog is empty`() {
        val jsonStr =
            """{"organization_id":"org-1","name":"A","contact_email":"a@b.c","active_status":true,
               |"timezone":"UTC","default_language":"FR","created_instant":"1970-01-01T00:00:00Z",
               |"last_updated_instant":"1970-01-01T00:00:00Z"}
            """.trimMargin().replace("\n", "")
        val org = json.decodeFromString(Organization.serializer(), jsonStr)
        assertTrue(org.itemTypes.isEmpty())
    }

    @Test
    fun `GIVEN BasketDeliveryDescription JSON without items WHEN deserialized THEN items is empty`() {
        val jsonStr = """{"product_type_id":"pt-1","basket_size_name":"Petit"}"""
        val desc = json.decodeFromString(BasketDeliveryDescription.serializer(), jsonStr)
        assertTrue(desc.items.isEmpty())
    }

    @Test
    fun `GIVEN Delivery with delivery template id WHEN serialized and deserialized THEN round-trips correctly`() {
        val delivery =
            Delivery(
                deliveryId = "delivery-1".toId(),
                organizationId = "org-1".toId(),
                deliveryTemplateId = "template-1".toId<DeliveryTemplate>(),
                scheduledDate = LocalDateTime.parse("2025-01-15T18:30:00"),
                status = DeliveryStatus.PLANNED,
                minVolunteersRequired = 3,
            )

        val encoded = json.encodeToString(Delivery.serializer(), delivery)
        assertTrue(encoded.contains("\"delivery_template_id\""))

        val decoded = json.decodeFromString(Delivery.serializer(), encoded)
        assertEquals(delivery, decoded)
    }

    @Test
    fun `GIVEN DeliveryTemplate with desired volunteer count WHEN serialized and deserialized THEN round-trips correctly`() {
        val template =
            DeliveryTemplate(
                deliveryTemplateId = "template-1".toId(),
                organizationId = "org-1".toId(),
                name = "Livraison du jeudi",
                standardStartTime = "18:00",
                standardEndTime = "20:00",
                desiredVolunteerCount = 4,
            )

        val encoded = json.encodeToString(DeliveryTemplate.serializer(), template)
        assertTrue(encoded.contains("\"desired_volunteer_count\""))

        val decoded = json.decodeFromString(DeliveryTemplate.serializer(), encoded)
        assertEquals(template, decoded)
    }

    @Test
    fun `GIVEN DeliveryTemplate JSON without desired_volunteer_count WHEN deserialized THEN desiredVolunteerCount defaults to zero`() {
        val jsonStr =
            """
            {
              "delivery_template_id":"template-1",
              "organization_id":"org-1",
              "name":"Livraison du jeudi",
              "standard_start_time":"18:00",
              "standard_end_time":"20:00"
            }
            """.trimIndent()

        val template = json.decodeFromString(DeliveryTemplate.serializer(), jsonStr)

        assertEquals(0, template.desiredVolunteerCount)
    }

    @Test
    fun `GIVEN Organization with default delivery template id WHEN serialized and deserialized THEN round-trips correctly`() {
        val organization =
            Organization(
                organizationId = "org-1".toId(),
                name = "AMAP des Collines",
                contactEmail = "contact@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                defaultDeliveryTemplateId = "template-1".toId(),
                createdInstant = Instant.fromEpochMilliseconds(1_000_000L),
                lastUpdatedInstant = Instant.fromEpochMilliseconds(2_000_000L),
            )

        val encoded = json.encodeToString(Organization.serializer(), organization)
        assertTrue(encoded.contains("\"default_delivery_template_id\""))

        val decoded = json.decodeFromString(Organization.serializer(), encoded)
        assertEquals(organization, decoded)
    }

    @Test
    fun `GIVEN Organization JSON without default_delivery_template_id WHEN deserialized THEN defaultDeliveryTemplateId is null`() {
        val jsonStr =
            """
            {
              "organization_id":"org-1",
              "name":"AMAP des Collines",
              "contact_email":"contact@example.com",
              "active_status":true,
              "timezone":"Europe/Paris",
              "default_language":"fr",
              "created_instant":"1970-01-01T00:16:40Z",
              "last_updated_instant":"1970-01-01T00:33:20Z"
            }
            """.trimIndent()

        val organization = json.decodeFromString(Organization.serializer(), jsonStr)

        assertNull(organization.defaultDeliveryTemplateId)
    }

    @Test
    fun `GIVEN Delivery JSON without delivery_template_id WHEN deserialized THEN deliveryTemplateId is null`() {
        val jsonStr =
            """
            {
              "delivery_id":"delivery-1",
              "organization_id":"org-1",
              "scheduled_date":"2025-01-15T18:30:00",
              "status":"PLANNED",
              "min_volunteers_required":3
            }
            """.trimIndent()

        val delivery = json.decodeFromString(Delivery.serializer(), jsonStr)

        assertNull(delivery.deliveryTemplateId)
    }

    @Test
    fun `GIVEN Delivery with per-delivery time overrides WHEN serialized and deserialized THEN round-trips correctly`() {
        val delivery =
            Delivery(
                deliveryId = "delivery-1".toId(),
                organizationId = "org-1".toId(),
                scheduledDate = LocalDateTime.parse("2025-01-15T18:30:00"),
                status = DeliveryStatus.PLANNED,
                minVolunteersRequired = 3,
                standardEndTime = "20:30",
                volunteerArrivalTime = "17:45",
                earlySlot =
                    EarlySlot(
                        arrivalTime = "16:30",
                        explanation = "Réception des légumes",
                        maxVolunteers = 2,
                    ),
            )

        val encoded = json.encodeToString(Delivery.serializer(), delivery)
        assertTrue(encoded.contains("\"standard_end_time\""))
        assertTrue(encoded.contains("\"volunteer_arrival_time\""))
        assertTrue(encoded.contains("\"early_slot\""))

        val decoded = json.decodeFromString(Delivery.serializer(), encoded)
        assertEquals(delivery, decoded)
    }

    @Test
    fun `GIVEN Delivery JSON without time overrides WHEN deserialized THEN overrides are null`() {
        val jsonStr =
            """
            {
              "delivery_id":"delivery-1",
              "organization_id":"org-1",
              "scheduled_date":"2025-01-15T18:30:00",
              "status":"PLANNED",
              "min_volunteers_required":3
            }
            """.trimIndent()

        val delivery = json.decodeFromString(Delivery.serializer(), jsonStr)

        assertNull(delivery.standardEndTime)
        assertNull(delivery.volunteerArrivalTime)
        assertNull(delivery.earlySlot)
    }

    @Test
    fun `GIVEN MemberSlot JSON without slot_kind WHEN deserialized THEN slotKind defaults to STANDARD`() {
        val jsonStr =
            """
            {
              "start_time":"2025-01-15T18:00:00",
              "end_time":"2025-01-15T20:00:00",
              "activity_type":"RECEPTION",
              "required_volunteers":2,
              "current_registrations":0,
              "status":"OPEN"
            }
            """.trimIndent()

        val slot = json.decodeFromString(MemberSlot.serializer(), jsonStr)

        assertEquals(SlotKind.STANDARD, slot.slotKind)
    }

    @Test
    fun `GIVEN MemberSlot with slot_kind EARLY WHEN serialized and deserialized THEN round-trips correctly`() {
        val slot =
            MemberSlot(
                startTime = LocalDateTime.parse("2025-01-15T17:00:00"),
                endTime = LocalDateTime.parse("2025-01-15T18:00:00"),
                activityType = ActivityType.PREPARATION,
                requiredVolunteers = 1,
                currentRegistrations = 0,
                status = SlotStatus.OPEN,
                slotKind = SlotKind.EARLY,
            )

        val encoded = json.encodeToString(MemberSlot.serializer(), slot)
        assertTrue(encoded.contains("\"slot_kind\""), "expected slot_kind in: $encoded")
        assertTrue(encoded.contains("\"EARLY\""), "expected EARLY in: $encoded")

        val decoded = json.decodeFromString(MemberSlot.serializer(), encoded)
        assertEquals(slot, decoded)
        assertEquals(SlotKind.EARLY, decoded.slotKind)
    }

    @Test
    fun `GIVEN ProducerAccount JSON without management_mode WHEN deserialized THEN managementMode defaults to ACCOUNT_BACKED`() {
        val jsonStr =
            """
            {
              "producer_account_id":"pa-1",
              "name":"Ferme Dupont",
              "active_status":true,
              "created_instant":"1970-01-01T00:16:40Z",
              "last_updated_instant":"1970-01-01T00:33:20Z"
            }
            """.trimIndent()

        val producerAccount = json.decodeFromString(ProducerAccount.serializer(), jsonStr)

        assertEquals(ProducerManagementMode.ACCOUNT_BACKED, producerAccount.managementMode)
        assertNull(producerAccount.linkedProducerAccount)
    }

    @Test
    fun `GIVEN EarlySlot with null explanation WHEN serialized THEN explanation is omitted from JSON`() {
        val slot =
            EarlySlot(
                arrivalTime = "16:30",
                explanation = null,
                maxVolunteers = 2,
            )

        val encoded = json.encodeToString(EarlySlot.serializer(), slot)
        assertTrue(!encoded.contains("explanation"), "explanation should be absent but got: $encoded")

        val decoded = json.decodeFromString(EarlySlot.serializer(), encoded)
        assertEquals(slot, decoded)
        assertNull(decoded.explanation)
    }

    @Test
    fun `GIVEN EarlySlot JSON without explanation WHEN deserialized THEN explanation is null`() {
        val jsonStr = """{"arrival_time":"16:30","max_volunteers":2}"""
        val slot = json.decodeFromString(EarlySlot.serializer(), jsonStr)
        assertNull(slot.explanation)
        assertEquals("16:30", slot.arrivalTime)
        assertEquals(2, slot.maxVolunteers)
    }

    @Test
    fun `GIVEN no-account ProducerAccount with linked target WHEN serialized and deserialized THEN round-trips correctly`() {
        val producerAccount =
            ProducerAccount(
                producerAccountId = "pa-source".toId(),
                name = "AMAP-managed producer",
                activeStatus = true,
                createdInstant = Instant.fromEpochMilliseconds(1_000_000L),
                lastUpdatedInstant = Instant.fromEpochMilliseconds(2_000_000L),
                managementMode = ProducerManagementMode.NO_ACCOUNT,
                linkedProducerAccount = LinkedProducerAccount("pa-target".toId(), "Ferme Martin"),
            )

        val encoded = json.encodeToString(ProducerAccount.serializer(), producerAccount)
        assertTrue(encoded.contains("\"management_mode\""))
        assertTrue(encoded.contains("\"linked_producer_account\""))

        val decoded = json.decodeFromString(ProducerAccount.serializer(), encoded)
        assertEquals(producerAccount, decoded)
    }

    @Test
    fun `GIVEN Contract with shared baskets WHEN serialized and deserialized THEN round-trips and keys are snake_case`() {
        val contract =
            Contract(
                contractId = "contract-1".toId(),
                name = "Contrat 2025",
                organizationId = "org-1".toId(),
                producerAccountId = "pa-1".toId(),
                minDeliveryDate = kotlinx.datetime.LocalDate(2025, 1, 1),
                maxDeliveryDate = kotlinx.datetime.LocalDate(2025, 12, 31),
                deliveryCount = 20,
                seasonYear = 2025,
                sharedBaskets =
                    listOf(
                        SharedBasket(
                            sharedBasketId = "sb-1".toId(),
                            memberIds = listOf("member-a".toId(), "member-b".toId()),
                            anchorDeliveryId = "delivery-1".toId(),
                        ),
                    ),
            )

        val encoded = json.encodeToString(Contract.serializer(), contract)
        assertTrue(encoded.contains("\"shared_baskets\""), "expected shared_baskets but got: $encoded")
        assertTrue(encoded.contains("\"shared_basket_id\""))
        assertTrue(encoded.contains("\"member_ids\""))
        assertTrue(encoded.contains("\"anchor_delivery_id\""))

        val decoded = json.decodeFromString(Contract.serializer(), encoded)
        assertEquals(contract, decoded)
    }

    @Test
    fun `GIVEN Contract JSON without shared_baskets WHEN deserialized THEN sharedBaskets is empty`() {
        val jsonStr =
            """{"contract_id":"c-1","name":"X","organization_id":"o-1","producer_account_id":"pa-1",""" +
                """"min_delivery_date":"2025-01-01","max_delivery_date":"2025-12-31","delivery_count":1,"season_year":2025}"""
        val contract = json.decodeFromString(Contract.serializer(), jsonStr)
        assertTrue(contract.sharedBaskets.isEmpty())
    }

    @Test
    fun `GIVEN Contract with empty shared baskets WHEN serialized THEN anchor delivery id is omitted when null`() {
        val contract =
            Contract(
                contractId = "contract-1".toId(),
                name = "Contrat 2025",
                organizationId = "org-1".toId(),
                producerAccountId = "pa-1".toId(),
                minDeliveryDate = kotlinx.datetime.LocalDate(2025, 1, 1),
                maxDeliveryDate = kotlinx.datetime.LocalDate(2025, 12, 31),
                deliveryCount = 20,
                seasonYear = 2025,
                sharedBaskets =
                    listOf(
                        SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("a".toId(), "b".toId())),
                    ),
            )
        val encoded = json.encodeToString(Contract.serializer(), contract)
        assertTrue(!encoded.contains("anchor_delivery_id"), "expected anchor_delivery_id omitted but got: $encoded")
    }
}

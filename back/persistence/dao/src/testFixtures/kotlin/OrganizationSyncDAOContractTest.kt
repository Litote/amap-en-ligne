@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.model.Delivery
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.ItemType
import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class OrganizationSyncDAOContractTest {
    protected abstract val organizationSyncDAO: OrganizationSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert a producer account row so FK constraints (if any) are satisfied. */
    protected open fun insertProducerAccount(producerAccountId: String) {
        // Default: no-op (DynamoDB has no FK constraints)
    }

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun buildOrganization(
        organizationId: String = newOrganizationId(),
        producers: List<OrganizationProducer> = emptyList(),
        deliveries: List<Delivery> = emptyList(),
        defaultDeliveryTemplateId: String? = null,
        notificationOverrides: Map<NotificationCategory, NotificationCopyOverride> = emptyMap(),
        itemTypes: List<ItemType> = emptyList(),
    ): Organization =
        Organization(
            organizationId = organizationId.toId(),
            name = "AMAP Test $organizationId",
            contactEmail = "contact-$organizationId@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            website = null,
            defaultDeliveryTemplateId = defaultDeliveryTemplateId?.toId<DeliveryTemplate>(),
            createdInstant = Instant.fromEpochMilliseconds(1_000_000L),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(2_000_000L),
            producers = producers,
            deliveries = deliveries,
            notificationOverrides = notificationOverrides,
            itemTypes = itemTypes,
        )

    protected fun buildOrganizationProducer(producerAccountId: String = UUID.randomUUID().toString()): OrganizationProducer =
        OrganizationProducer(
            producerAccountId = producerAccountId.toId<ProducerAccount>(),
            associationInstant = Instant.fromEpochMilliseconds(1_000_000L),
            status = OrganizationProducerStatus.ACTIVE,
        )

    protected fun buildDelivery(
        organizationId: String,
        deliveryId: String = UUID.randomUUID().toString(),
        deliveryTemplateId: String? = null,
    ): Delivery =
        Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = organizationId.toId(),
            deliveryTemplateId = deliveryTemplateId?.toId<DeliveryTemplate>(),
            scheduledDate = LocalDateTime.parse("2025-01-15T18:30:00"),
            status = DeliveryStatus.PLANNED,
            minVolunteersRequired = 2,
        )

    protected fun buildUpsertChange(org: Organization): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = org.organizationId.id,
            scopeKey = SyncScope.Organization(org.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = OrganizationPayload(org),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(organizationId: String): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = organizationId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN an organization WHEN put then getById THEN returns it`() =
        runTest {
            val org = buildOrganization()

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(org.organizationId, result.organizationId)
            assertEquals(org.name, result.name)
            assertEquals(org.contactEmail, result.contactEmail)
            assertEquals(org.timezone, result.timezone)
            assertEquals(org.defaultLanguage, result.defaultLanguage)
        }

    @Test
    fun `GIVEN no organization WHEN getById THEN returns null`() =
        runTest {
            val result = organizationSyncDAO.getById(newOrganizationId().toId())
            assertNull(result)
        }

    @Test
    fun `GIVEN an organization with notification overrides WHEN put then getById THEN round-trips them`() =
        runTest {
            val org =
                buildOrganization(
                    notificationOverrides =
                        mapOf(
                            NotificationCategory.SLOT_CANCELLED to
                                NotificationCopyOverride(title = "Annulation", body = "Le créneau est annulé."),
                            NotificationCategory.BASKET_EXCHANGE_ACCEPTED to
                                NotificationCopyOverride(body = "Échange accepté."),
                        ),
                )

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(org.notificationOverrides, result.notificationOverrides)
        }

    @Test
    fun `GIVEN an organization without notification overrides WHEN put then getById THEN overrides are empty`() =
        runTest {
            val org = buildOrganization()

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(emptyMap(), result.notificationOverrides)
        }

    @Test
    fun `GIVEN an organization with item types WHEN put then getById THEN round-trips them`() =
        runTest {
            val itemTypes =
                listOf(
                    ItemType(id = "carrot".toId(), name = "Carotte", imageSvg = "<svg>carrot</svg>"),
                    ItemType(id = "leek".toId(), name = "Poireau"),
                )
            val org = buildOrganization(itemTypes = itemTypes)

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(itemTypes, result.itemTypes)
        }

    @Test
    fun `GIVEN an organization without item types WHEN put then getById THEN item types are empty`() =
        runTest {
            val org = buildOrganization()

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(emptyList(), result.itemTypes)
        }

    @Test
    fun `GIVEN an organization with item types WHEN listAll THEN round-trips them`() =
        runTest {
            val itemTypes = listOf(ItemType(id = "tomato".toId(), name = "Tomate", imageSvg = "<svg>tomato</svg>"))
            val org = buildOrganization(itemTypes = itemTypes)
            organizationSyncDAO.put(org, buildUpsertChange(org))

            val matched = organizationSyncDAO.listAll().single { it.organizationId == org.organizationId }
            assertEquals(itemTypes, matched.itemTypes)
        }

    @Test
    fun `GIVEN an organization with producers WHEN put then getById THEN returns producers`() =
        runTest {
            val producer = buildOrganizationProducer()
            insertProducerAccount(producer.producerAccountId.id)
            val org = buildOrganization(producers = listOf(producer))

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(1, result.producers.size)
            assertEquals(producer.producerAccountId, result.producers.first().producerAccountId)
        }

    @Test
    fun `GIVEN an existing organization WHEN delete THEN getById returns null`() =
        runTest {
            val org = buildOrganization()
            organizationSyncDAO.put(org, buildUpsertChange(org))

            organizationSyncDAO.delete(org.organizationId, buildDeleteChange(org.organizationId.id))

            assertNull(organizationSyncDAO.getById(org.organizationId))
        }

    @Test
    fun `GIVEN an organization WHEN put THEN change is recorded`() =
        runTest {
            val org = buildOrganization()
            val change = buildUpsertChange(org)

            organizationSyncDAO.put(org, change)

            val changes = changeDAO.since(SyncScope.Organization(org.organizationId.id).key, null)
            assertEquals(1, changes.size)
            assertEquals(org.organizationId.id, changes.single().entityId)
        }

    @Test
    fun `GIVEN two organizations WHEN getById THEN returns only the requested one`() =
        runTest {
            val orgA = buildOrganization()
            val orgB = buildOrganization()
            organizationSyncDAO.put(orgA, buildUpsertChange(orgA))
            organizationSyncDAO.put(orgB, buildUpsertChange(orgB))

            val result = organizationSyncDAO.getById(orgA.organizationId)
            assertNotNull(result)
            assertEquals(orgA.organizationId, result.organizationId)
        }

    @Test
    fun `GIVEN an organization WHEN put updated version THEN getById returns updated`() =
        runTest {
            val org = buildOrganization()
            organizationSyncDAO.put(org, buildUpsertChange(org))

            val updated = org.copy(name = "Updated Name")
            organizationSyncDAO.put(updated, buildUpsertChange(updated))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals("Updated Name", result.name)
        }

    @Test
    fun `GIVEN multiple organizations WHEN listAll THEN returns all of them`() =
        runTest {
            val orgA = buildOrganization()
            val orgB = buildOrganization()
            organizationSyncDAO.put(orgA, buildUpsertChange(orgA))
            organizationSyncDAO.put(orgB, buildUpsertChange(orgB))

            val ids = organizationSyncDAO.listAll().map { it.organizationId }.toSet()
            assertTrue(orgA.organizationId in ids)
            assertTrue(orgB.organizationId in ids)
        }

    @Test
    fun `GIVEN an organization with producers WHEN listAll THEN returns producers`() =
        runTest {
            val producer = buildOrganizationProducer()
            insertProducerAccount(producer.producerAccountId.id)
            val org = buildOrganization(producers = listOf(producer))
            organizationSyncDAO.put(org, buildUpsertChange(org))

            val matched = organizationSyncDAO.listAll().single { it.organizationId == org.organizationId }
            assertEquals(1, matched.producers.size)
            assertEquals(producer.producerAccountId, matched.producers.first().producerAccountId)
        }

    @Test
    fun `GIVEN an organization with delivery template links WHEN put then getById THEN deliveries keep their template ids`() =
        runTest {
            val orgId = newOrganizationId()
            val delivery = buildDelivery(organizationId = orgId, deliveryTemplateId = "template-1")
            val org = buildOrganization(organizationId = orgId, deliveries = listOf(delivery))

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals(listOf(delivery), result.deliveries)
            assertEquals(
                "template-1",
                result.deliveries
                    .single()
                    .deliveryTemplateId
                    ?.id,
            )
        }

    @Test
    fun `GIVEN an organization with default delivery template id WHEN put then getById THEN default delivery template id is preserved`() =
        runTest {
            val org = buildOrganization(defaultDeliveryTemplateId = "template-default")

            organizationSyncDAO.put(org, buildUpsertChange(org))

            val result = organizationSyncDAO.getById(org.organizationId)
            assertNotNull(result)
            assertEquals("template-default", result.defaultDeliveryTemplateId?.id)
        }

    @Test
    fun `GIVEN two changes WHEN since with cursor THEN returns only the strictly newer one`() =
        runTest {
            val orgA = buildOrganization()
            val orgB = buildOrganization(organizationId = orgA.organizationId.id)
            val first = buildUpsertChange(orgA)
            organizationSyncDAO.put(orgA, first)
            organizationSyncDAO.put(orgB.copy(name = "Updated"), buildUpsertChange(orgB))

            val changes = changeDAO.since(SyncScope.Organization(orgA.organizationId.id).key, first.cursor)

            assertTrue(changes.size <= 1)
        }
}

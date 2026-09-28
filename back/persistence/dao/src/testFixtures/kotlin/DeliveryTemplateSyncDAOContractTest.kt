package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.SyncScope
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.EntityType
import persistence.model.Organization
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
abstract class DeliveryTemplateSyncDAOContractTest {
    protected abstract val deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun newDeliveryTemplateId() = UUID.randomUUID().toString()

    protected fun buildDeliveryTemplate(
        deliveryTemplateId: String = newDeliveryTemplateId(),
        organizationId: String = newOrganizationId(),
    ): DeliveryTemplate =
        DeliveryTemplate(
            deliveryTemplateId = deliveryTemplateId.toId(),
            organizationId = organizationId.toId(),
            name = "Livraison du jeudi",
            standardStartTime = "18:00",
            standardEndTime = "20:00",
            desiredVolunteerCount = 3,
        )

    protected fun buildDeliveryTemplateWithEarlySlot(
        deliveryTemplateId: String = newDeliveryTemplateId(),
        organizationId: String = newOrganizationId(),
    ): DeliveryTemplate =
        DeliveryTemplate(
            deliveryTemplateId = deliveryTemplateId.toId(),
            organizationId = organizationId.toId(),
            name = "Livraison avec réception anticipée",
            standardStartTime = "18:00",
            standardEndTime = "20:00",
            desiredVolunteerCount = 4,
            earlySlot =
                EarlySlot(
                    arrivalTime = "17:00",
                    explanation = "Réception des légumes",
                    maxVolunteers = 2,
                ),
        )

    protected fun buildUpsertChange(
        deliveryTemplate: DeliveryTemplate,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeliveryTemplate,
            entityId = deliveryTemplate.deliveryTemplateId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = DeliveryTemplatePayload(deliveryTemplate),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        deliveryTemplateId: String,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeliveryTemplate,
            entityId = deliveryTemplateId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a delivery template WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplate(organizationId = orgId)

            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(template, result.first())
        }

    @Test
    fun `GIVEN no delivery templates WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = deliveryTemplateSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple delivery templates for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template1 = buildDeliveryTemplate(organizationId = orgId)
            val template2 = buildDeliveryTemplate(organizationId = orgId)

            deliveryTemplateSyncDAO.put(template1, buildUpsertChange(template1, orgId))
            deliveryTemplateSyncDAO.put(template2, buildUpsertChange(template2, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.deliveryTemplateId == template1.deliveryTemplateId })
            assertTrue(result.any { it.deliveryTemplateId == template2.deliveryTemplateId })
        }

    @Test
    fun `GIVEN delivery templates for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val templateA = buildDeliveryTemplate(organizationId = orgA)
            val templateB = buildDeliveryTemplate(organizationId = orgB)

            deliveryTemplateSyncDAO.put(templateA, buildUpsertChange(templateA, orgA))
            deliveryTemplateSyncDAO.put(templateB, buildUpsertChange(templateB, orgB))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgA.toId<Organization>())
            assertEquals(1, result.size)
            assertEquals(templateA.deliveryTemplateId, result.first().deliveryTemplateId)
        }

    @Test
    fun `GIVEN an existing delivery template WHEN delete THEN getByOrganizationId returns empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplate(organizationId = orgId)
            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            deliveryTemplateSyncDAO.delete(
                template.deliveryTemplateId,
                orgId.toId(),
                buildDeleteChange(template.deliveryTemplateId.id, orgId),
            )

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a delivery template WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplate(organizationId = orgId)
            val change = buildUpsertChange(template, orgId)

            deliveryTemplateSyncDAO.put(template, change)

            val changes = changeDAO.since(SyncScope.Organization(orgId).key, null)
            assertNotNull(changes.find { it.entityId == template.deliveryTemplateId.id })
        }

    @Test
    fun `GIVEN a delivery template WHEN put updated version THEN getByOrganizationId returns updated`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplate(organizationId = orgId)
            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            val updated = template.copy(name = "Livraison modifiée")
            deliveryTemplateSyncDAO.put(updated, buildUpsertChange(updated, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals("Livraison modifiée", result.first().name)
            assertEquals(3, result.first().desiredVolunteerCount)
        }

    @Test
    fun `GIVEN a delivery template with early slot WHEN put then getByOrganizationId THEN early slot is preserved`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplateWithEarlySlot(organizationId = orgId)

            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val retrieved = result.first()
            val slot = retrieved.earlySlot
            assertNotNull(slot)
            assertEquals(4, retrieved.desiredVolunteerCount)
            assertEquals("17:00", slot.arrivalTime)
            assertEquals("Réception des légumes", slot.explanation)
            assertEquals(2, slot.maxVolunteers)
        }

    @Test
    fun `GIVEN a delivery template without early slot WHEN put then getByOrganizationId THEN early slot is null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template = buildDeliveryTemplate(organizationId = orgId)

            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(null, result.first().earlySlot)
        }

    @Test
    fun `GIVEN a delivery template with early slot without explanation WHEN put then getByOrganizationId THEN explanation is null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val template =
                buildDeliveryTemplateWithEarlySlot(organizationId = orgId)
                    .copy(earlySlot = EarlySlot(arrivalTime = "17:00", explanation = null, maxVolunteers = 2))

            deliveryTemplateSyncDAO.put(template, buildUpsertChange(template, orgId))

            val result = deliveryTemplateSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val slot = result.first().earlySlot
            assertNotNull(slot)
            assertEquals("17:00", slot.arrivalTime)
            assertEquals(null, slot.explanation)
            assertEquals(2, slot.maxVolunteers)
        }
}

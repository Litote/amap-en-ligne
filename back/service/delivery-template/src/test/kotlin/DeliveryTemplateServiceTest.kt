package deliverytemplate

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.Delivery
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.EntityType
import persistence.model.Organization
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.time.Instant

internal class DeliveryTemplateServiceTest {
    private val organizationId = "org-1"
    private val deliveryTemplateId = "tmpl-1"
    private val adminAuth =
        AuthenticatedInfo(
            memberId = "caller-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = organizationId,
            roles = listOf(Role.ADMIN),
        )
    private val volunteerAuth =
        AuthenticatedInfo(
            memberId = "caller-3",
            firstName = "Volunteer",
            lastName = "User",
            email = "volunteer@example.com",
            organizationId = organizationId,
            roles = listOf(Role.VOLUNTEER),
        )
    private val noOrgAuth =
        AuthenticatedInfo(
            memberId = "caller-2",
            firstName = "No",
            lastName = "Org",
            email = "noorg@example.com",
            organizationId = null,
            roles = listOf(Role.ADMIN),
        )

    private fun buildDeliveryTemplate(
        id: String = deliveryTemplateId,
        orgId: String = organizationId,
    ): DeliveryTemplate =
        DeliveryTemplate(
            deliveryTemplateId = id.toId(),
            organizationId = orgId.toId(),
            name = "Livraison du jeudi",
            standardStartTime = "18:00",
            standardEndTime = "20:00",
            volunteerArrivalTime = "17:45",
            desiredVolunteerCount = 2,
        )

    private fun buildMutation(template: DeliveryTemplate): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(DeliveryTemplatePayload(template)),
        )

    @Test
    fun `GIVEN a tmp template id WHEN upsert THEN a real id is allocated and returned`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>(relaxed = true)
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate(id = "tmp_123")
            val stored = slot<DeliveryTemplate>()

            val outcome = service.applyUpsert(adminAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { dao.put(capture(stored), any()) }
            val realId = stored.captured.deliveryTemplateId.id
            assertFalse(realId.startsWith(ClientMutation.TMP_ID_PREFIX))
            assertEquals(realId, outcome.serverEntityId)
        }

    @Test
    fun `GIVEN a legacy template already stored under a tmp id WHEN upsert THEN the id is kept`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>(relaxed = true)
            val legacy = buildDeliveryTemplate(id = "tmp_123")
            coEvery { dao.getByOrganizationId(any()) } returns listOf(legacy)
            val service = DeliveryTemplateService(dao, noOrganization)
            val edited = legacy.copy(name = "Renamed")

            val outcome = service.applyUpsert(adminAuth, buildMutation(edited), DeliveryTemplatePayload(edited))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals("tmp_123", outcome.serverEntityId)
            coVerify { dao.put(match { it.deliveryTemplateId.id == "tmp_123" && it.name == "Renamed" }, any()) }
        }

    @Test
    fun `GIVEN caller without organization id WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate()

            val outcome = service.applyUpsert(noOrgAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN organization id mismatch WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate(orgId = "other-org")

            val outcome = service.applyUpsert(adminAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN valid upsert WHEN applyUpsert THEN APPLIED and DAO is called`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(deliveryTemplateId, outcome.serverEntityId)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN caller without organization id WHEN delete THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(noOrgAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    private val noOrganization = mockk<OrganizationSyncDAO> { coEvery { getById(any()) } returns null }

    private fun organizationWithDelivery(scheduledDate: String): OrganizationSyncDAO {
        val organization =
            Organization(
                organizationId = "org-1".toId(),
                name = "AMAP",
                contactEmail = "amap@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = Instant.fromEpochMilliseconds(0),
                lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
                deliveries =
                    listOf(
                        Delivery(
                            deliveryId = "d-1".toId(),
                            organizationId = "org-1".toId(),
                            deliveryTemplateId = deliveryTemplateId.toId(),
                            scheduledDate = LocalDateTime.parse(scheduledDate),
                            status = DeliveryStatus.PLANNED,
                            minVolunteersRequired = 2,
                        ),
                    ),
            )
        return mockk { coEvery { getById(any()) } returns organization }
    }

    @Test
    fun `GIVEN a template still used by a future delivery WHEN applyDelete THEN REJECTED CONFLICT`() =
        runTest {
            // Mirrors the admin list screen, which refuses the deletion too.
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, organizationWithDelivery("2999-01-15T18:00:00"))
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)

            val outcome = service.applyDelete(adminAuth, ClientMutation(clientOpId = "op-del", op = op), op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN a template only used by past deliveries WHEN applyDelete THEN APPLIED`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            coEvery { dao.delete(any(), any(), any()) } returns Unit
            val service = DeliveryTemplateService(dao, organizationWithDelivery("2000-01-15T18:00:00"))
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)

            val outcome = service.applyDelete(adminAuth, ClientMutation(clientOpId = "op-del", op = op), op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN valid delete WHEN applyDelete THEN APPLIED and DAO is called`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)
            coEvery { dao.delete(any(), any(), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, mutation, op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(deliveryTemplateId, outcome.serverEntityId)
            coVerify(exactly = 1) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN caller without organization id WHEN snapshot THEN returns empty list`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)

            val result = service.snapshot(noOrgAuth)

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { dao.getByOrganizationId(any()) }
        }

    @Test
    fun `GIVEN templates in DAO WHEN snapshot THEN returns all as DeliveryTemplatePayload`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate()
            coEvery { dao.getByOrganizationId(any()) } returns listOf(template)

            val result = service.snapshot(adminAuth)

            assertEquals(1, result.size)
            assertEquals(DeliveryTemplatePayload(template), result.first())
        }

    @Test
    fun `GIVEN volunteer caller WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN delete THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(volunteerAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN templates breaking the form rules WHEN upsert THEN REJECTED INVALID_PAYLOAD and nothing persisted`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao, noOrganization)
            val valid = buildDeliveryTemplate()
            val invalidTemplates =
                listOf(
                    valid.copy(name = "  "),
                    valid.copy(standardStartTime = "18h00"),
                    valid.copy(standardEndTime = "25:00"),
                    valid.copy(standardEndTime = "17:00"),
                    valid.copy(standardEndTime = "18:00"),
                    valid.copy(volunteerArrivalTime = "18:30"),
                    valid.copy(desiredVolunteerCount = 0),
                    valid.copy(earlySlot = EarlySlot(arrivalTime = "18:00", maxVolunteers = 2)),
                    valid.copy(earlySlot = EarlySlot(arrivalTime = "17:00", maxVolunteers = 0)),
                )

            invalidTemplates.forEach { template ->
                val outcome = service.applyUpsert(adminAuth, buildMutation(template), DeliveryTemplatePayload(template))

                assertEquals(MutationStatus.REJECTED, outcome.status, "expected rejection for $template")
                assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            }
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN a template with a valid early slot WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            coEvery { dao.put(any(), any()) } returns Unit
            val service = DeliveryTemplateService(dao, noOrganization)
            val template = buildDeliveryTemplate().copy(earlySlot = EarlySlot(arrivalTime = "17:00", maxVolunteers = 2))

            val outcome = service.applyUpsert(adminAuth, buildMutation(template), DeliveryTemplatePayload(template))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }
}

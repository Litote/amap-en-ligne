package deliverytemplate

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import kotlin.test.Test
import kotlin.test.assertEquals

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
        )

    private fun buildMutation(template: DeliveryTemplate): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(DeliveryTemplatePayload(template)),
        )

    @Test
    fun `GIVEN caller without organization id WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(noOrgAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN valid delete WHEN applyDelete THEN APPLIED and DAO is called`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)

            val result = service.snapshot(noOrgAuth)

            assertEquals(emptyList(), result)
            coVerify(exactly = 0) { dao.getByOrganizationId(any()) }
        }

    @Test
    fun `GIVEN templates in DAO WHEN snapshot THEN returns all as DeliveryTemplatePayload`() =
        runTest {
            val dao = mockk<DeliveryTemplateSyncDAO>()
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)
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
            val service = DeliveryTemplateService(dao)
            val op = Delete(EntityType.DeliveryTemplate, deliveryTemplateId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(volunteerAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }
}

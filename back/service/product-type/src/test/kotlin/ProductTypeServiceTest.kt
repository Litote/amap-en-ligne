package producttype

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.ItemType
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerOrganization
import persistence.model.ProductType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Instant

internal class ProductTypeServiceTest {
    private val producerAuth =
        AuthenticatedInfo(
            memberId = "pa-1",
            firstName = "Pro",
            lastName = "Ducer",
            email = "pro@example.com",
            producerAccountId = "pa-1",
            roles = listOf(Role.PRODUCER),
        )

    private val valid =
        ProductType(
            productTypeId = "pt-1".toId(),
            producerAccountId = "pa-1".toId(),
            name = "Oeufs",
            itemTypes = listOf(ItemType(id = "it-1".toId(), name = "Oeuf", imageSvg = "<svg></svg>")),
        )

    private fun mutation(productType: ProductType) = ClientMutation("op-1", Upsert(ProductTypePayload(productType)))

    private val epoch = Instant.fromEpochMilliseconds(0)

    private fun unlinkedProducers(): ProducerAccountSyncDAO = mockk { coEvery { findById(any()) } returns null }

    private fun producerLinkedTo(vararg links: Pair<String, OrganizationProducerStatus>): ProducerAccountSyncDAO =
        mockk {
            coEvery { findById("pa-1".toId()) } returns
                ProducerAccount(
                    producerAccountId = "pa-1".toId(),
                    name = "Ferme",
                    activeStatus = true,
                    createdInstant = epoch,
                    lastUpdatedInstant = epoch,
                    organizations =
                        links.map { (orgId, status) -> ProducerOrganization(orgId.toId(), epoch, status) },
                )
        }

    @Test
    fun `GIVEN product types breaking the form rules WHEN upsert THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val dao = mockk<ProductTypeSyncDAO>()
            val service = ProductTypeService(dao, unlinkedProducers(), mockk())
            val invalid =
                listOf(
                    valid.copy(name = " "),
                    valid.copy(itemTypes = listOf(ItemType(id = "it-1".toId(), name = " "))),
                    valid.copy(itemTypes = listOf(ItemType(id = "it-1".toId(), name = "Oeuf", imageSvg = "https://x/y.png"))),
                )

            invalid.forEach { productType ->
                val outcome = service.applyUpsert(producerAuth, mutation(productType), ProductTypePayload(productType))

                assertEquals(MutationStatus.REJECTED, outcome.status, "expected rejection for $productType")
                assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            }
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN a valid product type WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<ProductTypeSyncDAO>()
            coEvery { dao.put(any(), any()) } returns Unit
            val service = ProductTypeService(dao, unlinkedProducers(), mockk())

            val outcome = service.applyUpsert(producerAuth, mutation(valid), ProductTypePayload(valid))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN a producer linked to organizations WHEN upsert THEN the change is fanned out to each non-terminated organization scope`() =
        runTest {
            val dao = mockk<ProductTypeSyncDAO>()
            val fanOut = slot<List<persistence.changes.Change>>()
            coEvery { dao.put(any(), any(), capture(fanOut)) } returns Unit
            val service =
                ProductTypeService(
                    dao,
                    producerLinkedTo("org-1" to OrganizationProducerStatus.ACTIVE, "org-2" to OrganizationProducerStatus.TERMINATED),
                    mockk(),
                )

            val outcome = service.applyUpsert(producerAuth, mutation(valid), ProductTypePayload(valid))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(listOf(SyncScope.Organization("org-1").key), fanOut.captured.map { it.scopeKey })
            assertEquals(ChangeOp.UPSERT, fanOut.captured.single().op)
        }

    @Test
    fun `GIVEN a producer linked to an organization WHEN delete THEN the tombstone is fanned out to the organization scope`() =
        runTest {
            val dao = mockk<ProductTypeSyncDAO>()
            val fanOut = slot<List<persistence.changes.Change>>()
            coEvery { dao.delete(any(), any(), any(), capture(fanOut)) } returns Unit
            val service = ProductTypeService(dao, producerLinkedTo("org-1" to OrganizationProducerStatus.ACTIVE), mockk())

            val outcome =
                service.applyDelete(
                    producerAuth,
                    ClientMutation("op-2", Delete(persistence.model.EntityType.ProductType, "pt-1")),
                    Delete(persistence.model.EntityType.ProductType, "pt-1"),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(listOf(SyncScope.Organization("org-1").key), fanOut.captured.map { it.scopeKey })
            assertEquals(ChangeOp.DELETE, fanOut.captured.single().op)
        }

    @Test
    fun `GIVEN an organization scope WHEN snapshot THEN returns the catalogs of its non-terminated producers`() =
        runTest {
            val dao = mockk<ProductTypeSyncDAO>()
            coEvery { dao.getByProducerAccountId("pa-1".toId()) } returns listOf(valid)
            val organizationDAO = mockk<OrganizationSyncDAO>()
            coEvery { organizationDAO.getById("org-1".toId()) } returns
                Organization(
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
                            OrganizationProducer("pa-1".toId(), epoch, OrganizationProducerStatus.ACTIVE),
                            OrganizationProducer("pa-gone".toId(), epoch, OrganizationProducerStatus.TERMINATED),
                        ),
                )
            val service = ProductTypeService(dao, unlinkedProducers(), organizationDAO)
            val coordinator =
                AuthenticatedInfo(
                    memberId = "m-1",
                    firstName = "Co",
                    lastName = "Ordo",
                    email = "co@example.com",
                    organizationId = "org-1",
                    roles = listOf(Role.COORDINATOR),
                )

            val items = service.snapshot(coordinator, SyncScope.Organization("org-1"))

            assertEquals(listOf(ProductTypePayload(valid)), items)
            coVerify(exactly = 0) { dao.getByProducerAccountId("pa-gone".toId()) }
        }
}

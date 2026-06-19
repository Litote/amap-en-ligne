@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.SyncScope
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.MemberSubscription
import persistence.model.Organization
import persistence.model.ProductPrice
import persistence.model.SharedBasket
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class ContractSyncDAOContractTest {
    protected abstract val contractSyncDAO: ContractSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun newContractId() = UUID.randomUUID().toString()

    protected fun buildContract(
        contractId: String = newContractId(),
        organizationId: String = newOrganizationId(),
        producerAccountId: String = "producer-1",
        productPrices: List<ProductPrice> = emptyList(),
        name: String = "Test contract",
    ): Contract =
        Contract(
            contractId = contractId.toId(),
            name = name,
            organizationId = organizationId.toId(),
            producerAccountId = producerAccountId.toId(),
            productPrices = productPrices,
            minDeliveryDate = LocalDate.parse("2024-01-01"),
            maxDeliveryDate = LocalDate.parse("2024-12-31"),
            deliveryCount = 20,
            seasonYear = 2024,
        )

    protected fun buildUpsertChange(
        contract: Contract,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Contract,
            entityId = contract.contractId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = ContractPayload(contract),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        contractId: String,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Contract,
            entityId = contractId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a contract WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(contract.contractId, result.first().contractId)
        }

    @Test
    fun `GIVEN no contracts WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = contractSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple contracts for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract1 = buildContract(organizationId = orgId)
            val contract2 = buildContract(organizationId = orgId)

            contractSyncDAO.put(contract1, buildUpsertChange(contract1, orgId))
            contractSyncDAO.put(contract2, buildUpsertChange(contract2, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.contractId == contract1.contractId })
            assertTrue(result.any { it.contractId == contract2.contractId })
        }

    @Test
    fun `GIVEN contracts for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val contractA = buildContract(organizationId = orgA)
            val contractB = buildContract(organizationId = orgB)

            contractSyncDAO.put(contractA, buildUpsertChange(contractA, orgA))
            contractSyncDAO.put(contractB, buildUpsertChange(contractB, orgB))

            val result = contractSyncDAO.getByOrganizationId(orgA.toId<Organization>())
            assertEquals(1, result.size)
            assertEquals(contractA.contractId, result.first().contractId)
        }

    @Test
    fun `GIVEN an existing contract WHEN delete THEN getByOrganizationId returns empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)
            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            contractSyncDAO.delete(contract.contractId, orgId.toId(), buildDeleteChange(contract.contractId.id, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a contract WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)
            val change = buildUpsertChange(contract, orgId)

            contractSyncDAO.put(contract, change)

            val changes = changeDAO.since(SyncScope.Organization(orgId).key, null)
            assertNotNull(changes.find { it.entityId == contract.contractId.id })
        }

    @Test
    fun `GIVEN a contract WHEN put updated version THEN getByOrganizationId returns updated`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)
            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val updated = contract.copy(deliveryCount = 25)
            contractSyncDAO.put(updated, buildUpsertChange(updated, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(25, result.first().deliveryCount)
        }

    @Test
    fun `GIVEN a contract with producerAccountId and productPrices WHEN put then getByOrganizationId THEN round-trips correctly`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val prices =
                listOf(
                    ProductPrice(
                        productTypeId = "pt-vegetables",
                        basketSize = BasketSize("small"),
                        price = 15.50,
                    ),
                    ProductPrice(
                        productTypeId = "pt-fruits",
                        basketSize = null,
                        price = null,
                    ),
                )
            val contract =
                buildContract(
                    organizationId = orgId,
                    producerAccountId = "producer-round-trip",
                    productPrices = prices,
                )

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val stored = result.first()
            assertEquals("producer-round-trip", stored.producerAccountId.id)
            assertEquals(2, stored.productPrices.size)
            val vegPrice = stored.productPrices.first { it.productTypeId == "pt-vegetables" }
            assertEquals(BasketSize("small"), vegPrice.basketSize)
            assertEquals(15.50, vegPrice.price)
            val fruitPrice = stored.productPrices.first { it.productTypeId == "pt-fruits" }
            assertEquals(null, fruitPrice.basketSize)
            assertEquals(null, fruitPrice.price)
        }

    @Test
    fun `GIVEN a contract with ENDED status and deliveryTemplateId WHEN put then getByOrganizationId THEN round-trips correctly`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract =
                buildContract(organizationId = orgId).copy(
                    status = ContractStatus.ENDED,
                    deliveryTemplateId = "template-1".toId<DeliveryTemplate>(),
                )

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val stored = result.first()
            assertEquals(ContractStatus.ENDED, stored.status)
            assertEquals("template-1", stored.deliveryTemplateId?.id)
        }

    @Test
    fun `GIVEN a legacy contract without status or deliveryTemplateId WHEN read THEN defaults to IN_PREPARATION and null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val stored = result.first()
            assertEquals(ContractStatus.IN_PREPARATION, stored.status)
            assertEquals(null, stored.deliveryTemplateId)
        }

    @Test
    fun `GIVEN a contract with members having subscriptions WHEN put then getByOrganizationId THEN subscriptions round-trip correctly`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val subscription = MemberSubscription(productTypeId = "pt-veg", basketSize = BasketSize("medium"))
            val contractMember =
                persistence.model.ContractMember(
                    memberId = "member-sub-1".toId(),
                    subscriptionInstant = kotlin.time.Instant.fromEpochMilliseconds(1_700_000_000_000L),
                    status = persistence.model.MemberContractStatus.ACTIVE,
                    subscriptions = listOf(subscription),
                )
            val contract =
                buildContract(organizationId = orgId).copy(members = listOf(contractMember))

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val stored = result.first()
            assertEquals(1, stored.members.size)
            val storedMember = stored.members.first()
            assertEquals("member-sub-1", storedMember.memberId.id)
            assertEquals(1, storedMember.subscriptions.size)
            assertEquals("pt-veg", storedMember.subscriptions.first().productTypeId)
            assertEquals(BasketSize("medium"), storedMember.subscriptions.first().basketSize)
        }

    @Test
    fun `GIVEN a contract with shared baskets WHEN put then getByOrganizationId THEN shared baskets round-trip correctly`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val sharedBasket =
                SharedBasket(
                    sharedBasketId = "shared-1".toId(),
                    memberIds = listOf("member-a".toId(), "member-b".toId()),
                    anchorDeliveryId = "delivery-1".toId(),
                )
            val contract =
                buildContract(organizationId = orgId).copy(sharedBaskets = listOf(sharedBasket))

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val stored = result.first().sharedBaskets
            assertEquals(1, stored.size)
            assertEquals("shared-1", stored.first().sharedBasketId.id)
            assertEquals(listOf("member-a", "member-b"), stored.first().memberIds.map { it.id })
            assertEquals("delivery-1", stored.first().anchorDeliveryId?.id)
        }

    @Test
    fun `GIVEN a legacy contract without shared baskets WHEN read THEN defaults to empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val contract = buildContract(organizationId = orgId)

            contractSyncDAO.put(contract, buildUpsertChange(contract, orgId))

            val result = contractSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.first().sharedBaskets.isEmpty())
        }
}

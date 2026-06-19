@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BasketExchangePayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.SyncScope
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.EntityType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class BasketExchangeSyncDAOContractTest {
    protected abstract val basketExchangeSyncDAO: BasketExchangeSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun newBasketExchangeId() = UUID.randomUUID().toString()

    protected fun newRequestId() = UUID.randomUUID().toString()

    protected fun buildBasketExchange(
        basketExchangeId: String = newBasketExchangeId(),
        organizationId: String = newOrganizationId(),
        requests: List<BasketExchangeRequest> = emptyList(),
    ): BasketExchange {
        val now = Clock.System.now()
        return BasketExchange(
            basketExchangeId = basketExchangeId.toId(),
            organizationId = organizationId.toId(),
            deliveryId = UUID.randomUUID().toString().toId(),
            contractId = UUID.randomUUID().toString().toId(),
            offeringMemberId = "member-1".toId(),
            motive = "Absence for vacation",
            status = BasketExchangeStatus.OPEN,
            createdAt = now,
            requests = requests,
        )
    }

    protected fun buildRequest(
        requestId: String = newRequestId(),
        requesterMemberId: String = "requester-1",
        status: BasketExchangeRequestStatus = BasketExchangeRequestStatus.PENDING,
    ): BasketExchangeRequest {
        val now = Clock.System.now()
        return BasketExchangeRequest(
            requestId = requestId.toId(),
            requesterMemberId = requesterMemberId.toId(),
            createdAt = now,
            status = status,
        )
    }

    protected fun buildUpsertChange(
        basketExchange: BasketExchange,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.BasketExchange,
            entityId = basketExchange.basketExchangeId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = BasketExchangePayload(basketExchange),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        basketExchangeId: String,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.BasketExchange,
            entityId = basketExchangeId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a basket exchange WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange = buildBasketExchange(organizationId = orgId)

            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(exchange.basketExchangeId, result.first().basketExchangeId)
        }

    @Test
    fun `GIVEN no basket exchanges WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = basketExchangeSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN basket exchange WHEN findById THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange = buildBasketExchange(organizationId = orgId)
            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            val found = basketExchangeSyncDAO.findById(orgId.toId(), exchange.basketExchangeId)

            assertNotNull(found)
            assertEquals(exchange.basketExchangeId, found.basketExchangeId)
            assertEquals(exchange.status, found.status)
            assertEquals(exchange.motive, found.motive)
        }

    @Test
    fun `GIVEN no basket exchange WHEN findById THEN returns null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)

            val found = basketExchangeSyncDAO.findById(orgId.toId(), newBasketExchangeId().toId())

            assertNull(found)
        }

    @Test
    fun `GIVEN multiple basket exchanges for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange1 = buildBasketExchange(organizationId = orgId)
            val exchange2 = buildBasketExchange(organizationId = orgId)

            basketExchangeSyncDAO.put(exchange1, buildUpsertChange(exchange1, orgId))
            basketExchangeSyncDAO.put(exchange2, buildUpsertChange(exchange2, orgId))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.basketExchangeId == exchange1.basketExchangeId })
            assertTrue(result.any { it.basketExchangeId == exchange2.basketExchangeId })
        }

    @Test
    fun `GIVEN basket exchanges for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val exchangeA = buildBasketExchange(organizationId = orgA)
            val exchangeB = buildBasketExchange(organizationId = orgB)

            basketExchangeSyncDAO.put(exchangeA, buildUpsertChange(exchangeA, orgA))
            basketExchangeSyncDAO.put(exchangeB, buildUpsertChange(exchangeB, orgB))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgA.toId())
            assertEquals(1, result.size)
            assertEquals(exchangeA.basketExchangeId, result.first().basketExchangeId)
        }

    @Test
    fun `GIVEN an existing basket exchange WHEN delete THEN getByOrganizationId returns empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange = buildBasketExchange(organizationId = orgId)
            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            basketExchangeSyncDAO.delete(
                orgId.toId(),
                exchange.basketExchangeId,
                buildDeleteChange(exchange.basketExchangeId.id, orgId),
            )

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a basket exchange WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange = buildBasketExchange(organizationId = orgId)
            val change = buildUpsertChange(exchange, orgId)

            basketExchangeSyncDAO.put(exchange, change)

            val changes = changeDAO.since(SyncScope.Organization(orgId).key, null)
            assertNotNull(changes.find { it.entityId == exchange.basketExchangeId.id })
        }

    @Test
    fun `GIVEN a basket exchange WHEN put updated version THEN returns updated status`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val exchange = buildBasketExchange(organizationId = orgId)
            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            val updated = exchange.copy(status = BasketExchangeStatus.CANCELLED)
            basketExchangeSyncDAO.put(updated, buildUpsertChange(updated, orgId))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(BasketExchangeStatus.CANCELLED, result.first().status)
        }

    @Test
    fun `GIVEN a basket exchange with requests WHEN put THEN requests are preserved`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val request = buildRequest()
            val exchange = buildBasketExchange(organizationId = orgId, requests = listOf(request))

            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            val retrieved = result.first()
            assertEquals(1, retrieved.requests.size)
            assertEquals(request.requestId, retrieved.requests.first().requestId)
            assertEquals(request.status, retrieved.requests.first().status)
        }

    @Test
    fun `GIVEN a basket exchange with no motive WHEN put THEN motive is null`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val now = Clock.System.now()
            val exchange =
                BasketExchange(
                    basketExchangeId = newBasketExchangeId().toId(),
                    organizationId = orgId.toId(),
                    deliveryId = UUID.randomUUID().toString().toId(),
                    contractId = UUID.randomUUID().toString().toId(),
                    offeringMemberId = "member-1".toId(),
                    motive = null,
                    status = BasketExchangeStatus.OPEN,
                    createdAt = now,
                )

            basketExchangeSyncDAO.put(exchange, buildUpsertChange(exchange, orgId))

            val result = basketExchangeSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertNull(result.first().motive)
        }
}

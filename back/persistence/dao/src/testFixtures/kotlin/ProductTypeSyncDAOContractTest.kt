package persistence.dao

import id.Id
import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.model.BasketSize
import persistence.model.EntityType
import persistence.model.ProducerAccount
import persistence.model.ProductType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
abstract class ProductTypeSyncDAOContractTest {
    protected abstract val productTypeDao: ProductTypeSyncDAO
    protected abstract val changeDao: ChangeDAO

    protected fun newProducerAccountId() = UUID.randomUUID().toString().toId<ProducerAccount>()

    protected fun buildUpsertChange(pt: ProductType): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProductType,
            entityId = pt.productTypeId.id,
            scopeKey = SyncScope.ProducerAccount(pt.producerAccountId.id).key,
            op = ChangeOp.UPSERT,
            payload = ProductTypePayload(pt),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProductType,
            entityId = id.id,
            scopeKey = SyncScope.ProducerAccount(producerAccountId.id).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a product type WHEN put then getByProducerAccountId THEN returns it`() =
        runTest {
            val producerAccountId = newProducerAccountId()
            val productType =
                ProductType(
                    productTypeId = "pt-1".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("small"), BasketSize("large")),
                    name = "Vegetables",
                )

            productTypeDao.put(productType, buildUpsertChange(productType))

            val result = productTypeDao.getByProducerAccountId(producerAccountId)
            assertEquals(listOf(productType), result)
        }

    @Test
    fun `GIVEN no product types WHEN getByProducerAccountId THEN returns empty list`() =
        runTest {
            val result = productTypeDao.getByProducerAccountId(newProducerAccountId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN an existing product type WHEN delete THEN getByProducerAccountId returns empty list`() =
        runTest {
            val producerAccountId = newProducerAccountId()
            val productType =
                ProductType(
                    productTypeId = "pt-to-delete".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("medium")),
                    name = "Fruits",
                )
            productTypeDao.put(productType, buildUpsertChange(productType))

            productTypeDao.delete(
                productType.productTypeId,
                producerAccountId,
                buildDeleteChange(productType.productTypeId, producerAccountId),
            )

            val result = productTypeDao.getByProducerAccountId(producerAccountId)
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple product types for same producer WHEN put THEN getByProducerAccountId returns all`() =
        runTest {
            val producerAccountId = newProducerAccountId()
            val productType1 =
                ProductType(
                    productTypeId = "pt-a".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            val productType2 =
                ProductType(
                    productTypeId = "pt-b".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("large")),
                    name = "Fruits",
                )

            productTypeDao.put(productType1, buildUpsertChange(productType1))
            productTypeDao.put(productType2, buildUpsertChange(productType2))

            val result = productTypeDao.getByProducerAccountId(producerAccountId)
            assertEquals(2, result.size)
            assertTrue(result.containsAll(listOf(productType1, productType2)))
        }

    @Test
    fun `GIVEN product types for two producers WHEN getByProducerAccountId THEN returns only requested producer types`() =
        runTest {
            val producerA = newProducerAccountId()
            val producerB = newProducerAccountId()
            val ptA =
                ProductType(
                    productTypeId = "pt-isolation-a".toId(),
                    producerAccountId = producerA,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            val ptB =
                ProductType(
                    productTypeId = "pt-isolation-b".toId(),
                    producerAccountId = producerB,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Fruits",
                )

            productTypeDao.put(ptA, buildUpsertChange(ptA))
            productTypeDao.put(ptB, buildUpsertChange(ptB))

            val result = productTypeDao.getByProducerAccountId(producerA)
            assertEquals(listOf(ptA), result)
        }

    @Test
    fun `GIVEN two changes WHEN since with cursor THEN returns only the strictly newer one`() =
        runTest {
            val producerAccountId = newProducerAccountId()
            val pt1 =
                ProductType(
                    productTypeId = "pt-since-1".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            val pt2 =
                ProductType(
                    productTypeId = "pt-since-2".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("large")),
                    name = "Fruits",
                )
            val first = buildUpsertChange(pt1)
            productTypeDao.put(pt1, first)
            productTypeDao.put(pt2, buildUpsertChange(pt2))

            val changes = changeDao.since(SyncScope.ProducerAccount(producerAccountId.id).key, first.cursor)

            assertEquals(1, changes.size)
            assertEquals(pt2.productTypeId.id, changes.single().entityId)
        }

    @Test
    fun `GIVEN a product type WHEN put THEN since with null cursor returns it`() =
        runTest {
            val producerAccountId = newProducerAccountId()
            val pt =
                ProductType(
                    productTypeId = "pt-boot".toId(),
                    producerAccountId = producerAccountId,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            productTypeDao.put(pt, buildUpsertChange(pt))

            val changes = changeDao.since(SyncScope.ProducerAccount(producerAccountId.id).key, null)

            assertEquals(1, changes.size)
            assertEquals(pt.productTypeId.id, changes.single().entityId)
        }

    @Test
    fun `GIVEN changes for two producers WHEN since THEN returns only changes for the requested producer`() =
        runTest {
            val producerA = newProducerAccountId()
            val producerB = newProducerAccountId()
            val ptA =
                ProductType(
                    productTypeId = "pt-change-scope-a".toId(),
                    producerAccountId = producerA,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            val ptB =
                ProductType(
                    productTypeId = "pt-change-scope-b".toId(),
                    producerAccountId = producerB,
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Fruits",
                )

            productTypeDao.put(ptA, buildUpsertChange(ptA))
            productTypeDao.put(ptB, buildUpsertChange(ptB))

            val changes = changeDao.since(SyncScope.ProducerAccount(producerA.id).key, null)

            assertFalse(changes.any { it.entityId == ptB.productTypeId.id })
            assertTrue(changes.any { it.entityId == ptA.productTypeId.id })
        }
}

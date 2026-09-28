@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ProducerPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Execution(ExecutionMode.SAME_THREAD)
abstract class ProducerSyncDAOContractTest {
    protected abstract val producerSyncDAO: ProducerSyncDAO
    protected abstract val changeDAO: ChangeDAO

    protected fun newProducerAccountId() = UUID.randomUUID().toString().toId<ProducerAccount>()

    protected fun newProducerId() = UUID.randomUUID().toString().toId<Producer>()

    protected fun buildProducer(
        producerId: id.Id<Producer> = newProducerId(),
        producerAccountId: id.Id<ProducerAccount> = newProducerAccountId(),
    ): Producer {
        val now = Clock.System.now()
        // Both backends store associationInstant as epoch milliseconds; truncate so
        // the round-trip is exact. The lastUpdatedInstant fields live in JSON and
        // preserve full nanosecond precision, so they use the untruncated value.
        val associationInstant = kotlin.time.Instant.fromEpochMilliseconds(now.toEpochMilliseconds())
        return Producer(
            producerId = producerId,
            producerAccountId = producerAccountId,
            role = ProducerRole.OWNER,
            associationInstant = associationInstant,
            status = ProducerStatus.ACTIVE,
            producerPreferences =
                ProducerPreferences(
                    productionAlertsEnabled = true,
                    lastUpdatedInstant = now,
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = now,
                ),
            userSettings = buildTestUserSettings(now),
        )
    }

    protected abstract fun buildTestUserSettings(now: kotlin.time.Instant): UserSettings

    protected fun buildUpsertChange(producer: Producer): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Producer,
            entityId = producer.producerId.id,
            scopeKey = SyncScope.ProducerAccount(producer.producerAccountId.id).key,
            op = ChangeOp.UPSERT,
            payload = ProducerPayload(producer),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(producer: Producer): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Producer,
            entityId = producer.producerId.id,
            scopeKey = SyncScope.ProducerAccount(producer.producerAccountId.id).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a producer WHEN put THEN findByProducerId returns it`() =
        runTest {
            val producer = buildProducer()
            producerSyncDAO.put(producer, listOf(buildUpsertChange(producer)))

            val result = producerSyncDAO.findByProducerId(producer.producerId)
            assertEquals(producer, result)
        }

    @Test
    fun `GIVEN no producer WHEN findByProducerId THEN returns null`() =
        runTest {
            val result = producerSyncDAO.findByProducerId(newProducerId())
            assertNull(result)
        }

    @Test
    fun `GIVEN a producer WHEN put THEN getByProducerAccountId returns it`() =
        runTest {
            val accountId = newProducerAccountId()
            val producer = buildProducer(producerAccountId = accountId)
            producerSyncDAO.put(producer, listOf(buildUpsertChange(producer)))

            val result = producerSyncDAO.getByProducerAccountId(accountId)
            assertEquals(listOf(producer), result)
        }

    @Test
    fun `GIVEN no producers WHEN getByProducerAccountId THEN returns empty list`() =
        runTest {
            val result = producerSyncDAO.getByProducerAccountId(newProducerAccountId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple producers for same account WHEN getByProducerAccountId THEN returns all`() =
        runTest {
            val accountId = newProducerAccountId()
            val p1 = buildProducer(producerAccountId = accountId)
            val p2 = buildProducer(producerAccountId = accountId)
            producerSyncDAO.put(p1, listOf(buildUpsertChange(p1)))
            producerSyncDAO.put(p2, listOf(buildUpsertChange(p2)))

            val result = producerSyncDAO.getByProducerAccountId(accountId)
            assertEquals(2, result.size)
            assertTrue(result.containsAll(listOf(p1, p2)))
        }

    @Test
    fun `GIVEN producers for two accounts WHEN getByProducerAccountId THEN returns only the right account's producers`() =
        runTest {
            val accountA = newProducerAccountId()
            val accountB = newProducerAccountId()
            val pA = buildProducer(producerAccountId = accountA)
            val pB = buildProducer(producerAccountId = accountB)
            producerSyncDAO.put(pA, listOf(buildUpsertChange(pA)))
            producerSyncDAO.put(pB, listOf(buildUpsertChange(pB)))

            val result = producerSyncDAO.getByProducerAccountId(accountA)
            assertEquals(listOf(pA), result)
        }

    @Test
    fun `GIVEN an existing producer WHEN delete THEN findByProducerId returns null`() =
        runTest {
            val producer = buildProducer()
            producerSyncDAO.put(producer, listOf(buildUpsertChange(producer)))

            producerSyncDAO.delete(producer.producerId, listOf(buildDeleteChange(producer)))

            assertNull(producerSyncDAO.findByProducerId(producer.producerId))
        }

    @Test
    fun `GIVEN a producer WHEN put THEN change record is written on producer-account scope`() =
        runTest {
            val producer = buildProducer()
            val change = buildUpsertChange(producer)
            producerSyncDAO.put(producer, listOf(change))

            val changes = changeDAO.since(SyncScope.ProducerAccount(producer.producerAccountId.id).key, null)
            assertTrue(changes.any { it.entityId == producer.producerId.id })
        }
}

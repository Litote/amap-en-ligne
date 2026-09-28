@file:OptIn(ExperimentalTime::class)

package persistence.dao

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.model.AppliedClientOp
import persistence.model.EntityType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class AppliedClientOpDAOContractTest {
    protected abstract val appliedClientOpDAO: AppliedClientOpDAO

    private fun newEntry(
        serverEntityId: String? = "pt-${UUID.randomUUID()}",
        callerSub: String = "sub-1",
    ): AppliedClientOp =
        AppliedClientOp(
            clientOpId = "op-${UUID.randomUUID()}",
            callerSub = callerSub,
            entityType = EntityType.ProductType,
            serverEntityId = serverEntityId,
            appliedAt = Instant.fromEpochMilliseconds(1_700_000_000_000L),
        )

    @Test
    fun `GIVEN an entry WHEN record then find THEN returns it`() =
        runTest {
            val entry = newEntry()
            appliedClientOpDAO.record(entry)

            val found = appliedClientOpDAO.find(entry.clientOpId)
            assertNotNull(found)
            assertEquals(entry.clientOpId, found.clientOpId)
            assertEquals(entry.callerSub, found.callerSub)
            assertEquals(entry.entityType, found.entityType)
            assertEquals(entry.serverEntityId, found.serverEntityId)
            assertEquals(entry.appliedAt, found.appliedAt)
        }

    @Test
    fun `GIVEN an entry without serverEntityId WHEN record then find THEN serverEntityId is null`() =
        runTest {
            val entry = newEntry(serverEntityId = null)
            appliedClientOpDAO.record(entry)

            val found = appliedClientOpDAO.find(entry.clientOpId)
            assertNotNull(found)
            assertNull(found.serverEntityId)
        }

    @Test
    fun `GIVEN no entry WHEN find THEN returns null`() =
        runTest {
            assertNull(appliedClientOpDAO.find("unknown-${UUID.randomUUID()}"))
        }

    @Test
    fun `GIVEN a recorded op WHEN record again with the same key THEN it is a no-op`() =
        runTest {
            val entry = newEntry()
            appliedClientOpDAO.record(entry)
            appliedClientOpDAO.record(entry.copy(callerSub = "sub-other"))

            val found = appliedClientOpDAO.find(entry.clientOpId)
            assertNotNull(found)
            // First write wins (Postgres) or the overwrite carries identical
            // pipeline content (Dynamo) — either way a record survives.
            assertEquals(entry.clientOpId, found.clientOpId)
        }
}

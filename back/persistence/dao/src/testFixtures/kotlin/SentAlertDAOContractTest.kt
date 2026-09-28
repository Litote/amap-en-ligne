@file:OptIn(ExperimentalTime::class)

package persistence.dao

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.util.UUID
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class SentAlertDAOContractTest {
    protected abstract val sentAlertDAO: SentAlertDAO

    protected val sentAt: Instant = Instant.fromEpochMilliseconds(1_700_000_000_000L)

    protected fun newKey(): String = "org|delivery|member-${UUID.randomUUID()}|VOLUNTEER_SHORTAGE"

    @Test
    fun `GIVEN a new key WHEN markIfAbsent THEN returns true`() =
        runTest {
            assertTrue(sentAlertDAO.markIfAbsent(newKey(), sentAt))
        }

    @Test
    fun `GIVEN an already recorded key WHEN markIfAbsent again THEN returns false`() =
        runTest {
            val key = newKey()
            sentAlertDAO.markIfAbsent(key, sentAt)

            assertFalse(sentAlertDAO.markIfAbsent(key, sentAt))
        }

    @Test
    fun `GIVEN two distinct keys WHEN markIfAbsent THEN both are new`() =
        runTest {
            assertTrue(sentAlertDAO.markIfAbsent(newKey(), sentAt))
            assertTrue(sentAlertDAO.markIfAbsent(newKey(), sentAt))
        }
}

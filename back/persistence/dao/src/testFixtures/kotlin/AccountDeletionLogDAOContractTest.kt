@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.model.AccountDeletionLog
import persistence.model.DeletedAccountRole
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class AccountDeletionLogDAOContractTest {
    protected abstract val accountDeletionLogDAO: AccountDeletionLogDAO

    private fun newEntry(deletedRole: DeletedAccountRole = DeletedAccountRole.AMAP_MEMBER): AccountDeletionLog =
        AccountDeletionLog(
            id = UUID.randomUUID().toString().toId(),
            deletedSubHash = "hash-${UUID.randomUUID()}",
            deletedRole = deletedRole,
            deletedAt = Instant.fromEpochMilliseconds(1_700_000_000_000L),
            actorOwnerId = "owner-1".toId(),
        )

    @Test
    fun `GIVEN an entry WHEN append then findById THEN returns it`() =
        runTest {
            val entry = newEntry()
            accountDeletionLogDAO.append(entry)

            val found = accountDeletionLogDAO.findById(entry.id)
            assertNotNull(found)
            assertEquals(entry.id, found.id)
            assertEquals(entry.deletedSubHash, found.deletedSubHash)
            assertEquals(entry.deletedRole, found.deletedRole)
            assertEquals(entry.deletedAt, found.deletedAt)
            assertEquals(entry.actorOwnerId, found.actorOwnerId)
        }

    @Test
    fun `GIVEN no entry WHEN findById THEN returns null`() =
        runTest {
            val result = accountDeletionLogDAO.findById("unknown-${UUID.randomUUID()}".toId())
            assertEquals(null, result)
        }

    @Test
    fun `GIVEN multiple appends WHEN listAll THEN all are returned`() =
        runTest {
            val e1 = newEntry(deletedRole = DeletedAccountRole.OWNER)
            val e2 = newEntry(deletedRole = DeletedAccountRole.PRODUCER)
            accountDeletionLogDAO.append(e1)
            accountDeletionLogDAO.append(e2)

            val all = accountDeletionLogDAO.listAll()
            assertEquals(true, all.any { it.id == e1.id })
            assertEquals(true, all.any { it.id == e2.id })
        }
}

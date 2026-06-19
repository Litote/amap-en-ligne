package persistence.dao

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
abstract class ServerDAOContractTest {
    protected abstract val dao: ServerDAO

    protected abstract fun insertServer(
        id: String,
        name: String,
        url: String,
    )

    protected abstract fun clearAll()

    @BeforeEach
    fun clearBeforeEach() {
        clearAll()
    }

    @Test
    fun `GIVEN no servers WHEN list THEN returns empty list`() =
        runTest {
            val result = dao.list()
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a server WHEN list THEN includes it with correct fields`() =
        runTest {
            val id = "srv-${UUID.randomUUID()}"
            insertServer(id, "AMAP Île-de-France", "https://idf.amap-en-ligne.org/")

            val result = dao.list()

            val server = result.first { it.serverId.id == id }
            assertEquals("AMAP Île-de-France", server.name)
            assertEquals("https://idf.amap-en-ligne.org/", server.url)
        }
}

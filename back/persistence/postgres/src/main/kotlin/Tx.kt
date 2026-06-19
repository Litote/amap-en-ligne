package persistence.postgres

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.sql.Connection
import javax.sql.DataSource

internal suspend fun <R> DataSource.tx(
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    block: (Connection) -> R,
): R =
    withContext(dispatcher) {
        connection.use { conn ->
            conn.autoCommit = false
            try {
                val result = block(conn)
                conn.commit()
                result
            } catch (e: Throwable) {
                conn.rollback()
                throw e
            }
        }
    }

internal suspend fun <R> DataSource.query(
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    block: (Connection) -> R,
): R =
    withContext(dispatcher) {
        connection.use { conn -> block(conn) }
    }

package persistence.postgres

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.sql.Connection
import javax.sql.DataSource

internal suspend fun <R> DataSource.tx(block: (Connection) -> R): R =
    withContext(Dispatchers.IO) {
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

internal suspend fun <R> DataSource.query(block: (Connection) -> R): R =
    withContext(Dispatchers.IO) {
        connection.use { conn -> block(conn) }
    }

@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import org.koin.core.annotation.Single
import persistence.dao.SentAlertDAO
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [SentAlertDAO::class])
internal class SentAlertPostgresDAO(
    private val client: PostgresClient,
) : SentAlertDAO {
    override suspend fun markIfAbsent(
        key: String,
        sentAt: Instant,
    ): Boolean =
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO sent_alert(alert_key, sent_at)
                    VALUES (?, ?)
                    ON CONFLICT (alert_key) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, key)
                    stmt.setLong(2, sentAt.toEpochMilliseconds())
                    stmt.executeUpdate() == 1
                }
        }

    override suspend fun purgeBefore(instant: Instant) {
        client.dataSource.tx { conn ->
            conn.prepareStatement("DELETE FROM sent_alert WHERE sent_at < ?").use { stmt ->
                stmt.setLong(1, instant.toEpochMilliseconds())
                stmt.executeUpdate()
            }
        }
    }
}

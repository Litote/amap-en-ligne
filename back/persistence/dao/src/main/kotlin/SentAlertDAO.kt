@file:OptIn(ExperimentalTime::class)

package persistence.dao

import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Idempotency log of the alerts sent by scheduled jobs (volunteer shortage alerts), so a
 * job run twice — or overlapping runs — never sends the same alert twice.
 */
interface SentAlertDAO {
    /**
     * Records [key] as sent at [sentAt]. Returns `true` when the key was new (the caller
     * may send the alert) and `false` when it was already recorded (the alert must be skipped).
     */
    suspend fun markIfAbsent(
        key: String,
        sentAt: Instant,
    ): Boolean

    /** Forgets the keys recorded before [instant] (no-op where the store expires them itself). */
    suspend fun purgeBefore(instant: Instant)
}

package persistence.changes

import java.util.concurrent.ThreadLocalRandom
import java.util.concurrent.atomic.AtomicLong

/**
 * Monotonic, lexicographically-sortable cursor generator.
 *
 * Layout: `{epochMillis:13}{sequence:04x}{random:08x}` — 25 chars.
 * - `epochMillis` provides coarse time ordering.
 * - `sequence` breaks ties within the same millisecond inside one JVM.
 * - `random` makes collisions across concurrent JVMs vanishingly unlikely.
 *
 * The format is opaque to clients; they only compare cursors by lexicographic
 * order. If strict cross-process monotonicity ever becomes a requirement,
 * replace this with a proper ULID implementation without changing callers.
 */
object Cursor {
    private val sequence = AtomicLong(0)

    fun next(): String {
        val millis = System.currentTimeMillis()
        val seq = sequence.incrementAndGet() and 0xFFFF
        val rnd = ThreadLocalRandom.current().nextLong() and 0xFFFFFFFFL
        return "%013d%04x%08x".format(millis, seq, rnd)
    }
}

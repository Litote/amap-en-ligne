package persistence.dao

import persistence.changes.Change

/**
 * Read access to the change feed used by the offline-first synchronisation
 * API. Writes are emitted atomically with their entity mutation by the
 * corresponding entity DAO and therefore never go through this interface.
 */
interface ChangeDAO {
    suspend fun countSince(
        scopeKey: String,
        cursor: String?,
        limit: Int = DEFAULT_INCREMENTAL_LIMIT + 1,
    ): Int

    suspend fun since(
        scopeKey: String,
        cursor: String?,
    ): List<Change>

    companion object {
        const val DEFAULT_INCREMENTAL_LIMIT: Int = 200
    }
}

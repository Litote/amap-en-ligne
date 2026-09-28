package persistence.dao

import id.Id
import persistence.model.AccountDeletionLog

interface AccountDeletionLogDAO {
    /** Appends an immutable audit record. */
    suspend fun append(entry: AccountDeletionLog)

    /** Returns all records (test / admin reporting use only). */
    suspend fun listAll(): List<AccountDeletionLog>

    /** Lookup by id — used by tests. */
    suspend fun findById(id: Id<AccountDeletionLog>): AccountDeletionLog?
}

package persistence.dao

import persistence.model.AppliedClientOp

interface AppliedClientOpDAO {
    /**
     * Best-effort idempotency record write. Recording the same
     * [AppliedClientOp.clientOpId] twice is a no-op (first write wins on
     * Postgres, deterministic overwrite on Dynamo) — never an error.
     */
    suspend fun record(entry: AppliedClientOp)

    /** Point lookup by client op id; `null` when the op was never applied. */
    suspend fun find(clientOpId: String): AppliedClientOp?
}

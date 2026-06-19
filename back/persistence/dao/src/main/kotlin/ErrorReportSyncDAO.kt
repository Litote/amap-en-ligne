package persistence.dao

import persistence.changes.Change
import persistence.model.ErrorReport

interface ErrorReportSyncDAO {
    /** Returns all error reports (used for the instance-owner bootstrap snapshot). */
    suspend fun listAll(): List<ErrorReport>

    /** Atomically writes the error report and its change record on the instance-owner scope. */
    suspend fun put(
        errorReport: ErrorReport,
        change: Change,
    )
}

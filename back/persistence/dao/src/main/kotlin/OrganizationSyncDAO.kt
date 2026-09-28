package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Organization

interface OrganizationSyncDAO {
    suspend fun getById(organizationId: Id<Organization>): Organization?

    /** Returns every organization. Used by OWNER instance-wide snapshots. */
    suspend fun listAll(): List<Organization>

    /**
     * Atomically writes the organization and its change record, plus [fanOutChanges] (derived
     * projections on other scopes, e.g. producers' schedules) in the same transaction.
     */
    suspend fun put(
        organization: Organization,
        change: Change,
        fanOutChanges: List<Change> = emptyList(),
    )

    /** Atomically deletes the organization and records the corresponding tombstone. */
    suspend fun delete(
        organizationId: Id<Organization>,
        change: Change,
    )
}

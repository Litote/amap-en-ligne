package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Contract
import persistence.model.Organization

interface ContractSyncDAO {
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Contract>

    /**
     * Atomically writes the contract and its change record, plus [fanOutChanges] (derived
     * projections on other scopes, e.g. producers' schedules) in the same transaction.
     */
    suspend fun put(
        contract: Contract,
        change: Change,
        fanOutChanges: List<Change> = emptyList(),
    )

    /** Atomically deletes the contract and records the corresponding tombstone. */
    suspend fun delete(
        contractId: Id<Contract>,
        organizationId: Id<Organization>,
        change: Change,
        fanOutChanges: List<Change> = emptyList(),
    )
}

package persistence.dao

import persistence.changes.Change
import persistence.model.OrganizationRequest

interface OrganizationRequestSyncDAO {
    suspend fun listAll(): List<OrganizationRequest>

    suspend fun put(
        request: OrganizationRequest,
        change: Change,
    )
}

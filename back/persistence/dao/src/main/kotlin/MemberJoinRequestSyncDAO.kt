package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.MemberJoinRequest
import persistence.model.Organization

interface MemberJoinRequestSyncDAO {
    suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberJoinRequest>

    suspend fun put(
        request: MemberJoinRequest,
        change: Change,
    )
}

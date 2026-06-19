@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.Id
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

interface MemberJoinRequestDAO {
    suspend fun create(request: MemberJoinRequest)

    suspend fun existsPendingByEmailAndOrganization(
        email: String,
        organizationId: Id<Organization>,
    ): Boolean

    suspend fun listByOrganization(organizationId: Id<Organization>): List<MemberJoinRequest>

    suspend fun listByOrganizationAndStatus(
        organizationId: Id<Organization>,
        status: MemberJoinRequestStatus,
    ): List<MemberJoinRequest>

    suspend fun findById(requestId: Id<MemberJoinRequest>): MemberJoinRequest?

    suspend fun updateStatus(
        requestId: Id<MemberJoinRequest>,
        status: MemberJoinRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    )
}

@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.Id
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

interface OrganizationRequestDAO {
    suspend fun create(request: OrganizationRequest)

    suspend fun existsByOrganizationName(
        name: String,
        excludedStatuses: Set<OrganizationRequestStatus> = emptySet(),
    ): OrganizationRequestStatus?

    suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<OrganizationRequestStatus> = emptySet(),
    ): OrganizationRequestStatus?

    suspend fun listAll(): List<OrganizationRequest>

    suspend fun listByStatus(status: OrganizationRequestStatus): List<OrganizationRequest>

    suspend fun findById(requestId: Id<OrganizationRequest>): OrganizationRequest?

    suspend fun updateStatus(
        requestId: Id<OrganizationRequest>,
        status: OrganizationRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    )
}

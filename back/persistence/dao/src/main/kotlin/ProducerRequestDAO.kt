@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.Id
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

interface ProducerRequestDAO {
    suspend fun create(request: ProducerRequest)

    suspend fun existsByProducerName(
        name: String,
        excludedStatuses: Set<ProducerRequestStatus> = emptySet(),
    ): ProducerRequestStatus?

    suspend fun existsByAdminEmail(
        email: String,
        excludedStatuses: Set<ProducerRequestStatus> = emptySet(),
    ): ProducerRequestStatus?

    suspend fun listAll(): List<ProducerRequest>

    suspend fun listByStatus(status: ProducerRequestStatus): List<ProducerRequest>

    suspend fun findById(requestId: Id<ProducerRequest>): ProducerRequest?

    suspend fun updateStatus(
        requestId: Id<ProducerRequest>,
        status: ProducerRequestStatus,
        reviewedAt: Instant,
        reviewComment: String?,
    )
}

package persistence.dao

import persistence.changes.Change
import persistence.model.ProducerRequest

interface ProducerRequestSyncDAO {
    suspend fun listAll(): List<ProducerRequest>

    suspend fun put(
        request: ProducerRequest,
        change: Change,
    )
}

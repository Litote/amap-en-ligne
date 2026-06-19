package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Producer
import persistence.model.ProducerAccount

interface ProducerSyncDAO {
    /** Atomically writes the producer row and its change records on the producer-account scope. */
    suspend fun put(
        producer: Producer,
        changes: List<Change>,
    )

    /** Looks up the Producer by its auth subject (= producerId). Used by AuthorizedScopeResolver. */
    suspend fun findByProducerId(producerId: Id<Producer>): Producer?

    /** Returns all producers associated with a given producer account. */
    suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<Producer>

    /** Atomically deletes the producer row and writes the tombstone change records. */
    suspend fun delete(
        producerId: Id<Producer>,
        changes: List<Change>,
    )
}

package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.ProducerAccount
import persistence.model.ProductType

interface ProductTypeSyncDAO {
    suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<ProductType>

    /** Atomically writes the product type and its change record. */
    suspend fun put(
        productType: ProductType,
        change: Change,
    ) = put(productType, change, emptyList())

    /**
     * Atomically writes the product type, its change record and [fanOutChanges] — the same
     * change recorded on other scopes (the organizations the producer is linked to).
     */
    suspend fun put(
        productType: ProductType,
        change: Change,
        fanOutChanges: List<Change>,
    )

    /** Atomically deletes the product type and records the corresponding tombstone. */
    suspend fun delete(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
        change: Change,
    ) = delete(id, producerAccountId, change, emptyList())

    /** Atomically deletes the product type and records the tombstone on its own scope and on every [fanOutChanges] scope. */
    suspend fun delete(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
        change: Change,
        fanOutChanges: List<Change>,
    )
}

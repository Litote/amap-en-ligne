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
    )

    /** Atomically deletes the product type and records the corresponding tombstone. */
    suspend fun delete(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
        change: Change,
    )
}

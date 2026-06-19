package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.BasketExchange
import persistence.model.Organization

interface BasketExchangeSyncDAO {
    /** Returns all basket exchanges for the given organization. */
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<BasketExchange>

    /** Returns a single basket exchange by organization + id, or null if absent. */
    suspend fun findById(
        organizationId: Id<Organization>,
        basketExchangeId: Id<BasketExchange>,
    ): BasketExchange?

    /** Atomically writes the basket exchange and its change record. */
    suspend fun put(
        basketExchange: BasketExchange,
        change: Change,
    )

    /**
     * Atomically deletes the basket exchange and records the corresponding tombstone.
     * Reserved for future administrative hard-deletes; V1 cancellation goes through
     * an Upsert with status=CANCELLED.
     */
    suspend fun delete(
        organizationId: Id<Organization>,
        basketExchangeId: Id<BasketExchange>,
        change: Change,
    )
}

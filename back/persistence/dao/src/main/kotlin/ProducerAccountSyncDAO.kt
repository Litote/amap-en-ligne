package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Organization
import persistence.model.ProducerAccount

interface ProducerAccountSyncDAO {
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<ProducerAccount>

    /** Returns every ProducerAccount on the instance. Used by OWNER instance-wide snapshots. */
    suspend fun listAll(): List<ProducerAccount>

    /** Returns the ProducerAccount with the given id, or null. */
    suspend fun findById(producerAccountId: Id<ProducerAccount>): ProducerAccount?

    /**
     * Atomically flips [activeStatus] on the producer row and writes the
     * [changes] tombstones / upsert Change records. Used by OWNER suspend /
     * reactivate flows (see `ProducerAccountService`).
     */
    suspend fun updateActiveStatus(
        producerAccountId: Id<ProducerAccount>,
        activeStatus: Boolean,
        changes: List<Change>,
    )

    /** Atomically writes the producer account and its scope change records. */
    suspend fun put(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
        changes: List<Change>,
    )

    /** Atomically removes the producer from the organization and records the scope diff. */
    suspend fun delete(
        producerAccountId: Id<ProducerAccount>,
        organizationId: Id<Organization>,
        changes: List<Change>,
    )

    /** Creates the ProducerAccount and its organization link atomically, without writing a Change record. Used during first activation. */
    suspend fun createInitial(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
    )

    /** Creates a standalone ProducerAccount without any organization link and without writing a Change record. */
    suspend fun createStandalone(producerAccount: ProducerAccount)

    /**
     * Atomically updates the producer account profile fields (name, contactEmail, address, website,
     * lastUpdatedInstant) and writes the [changes] records across all linked scopes.
     * Does not touch organization association rows.
     */
    suspend fun updateProfile(
        producerAccount: ProducerAccount,
        changes: List<Change>,
    )

    /** Returns active ProducerAccounts whose name or contactEmail matches [query], excluding those already ACTIVE or SUSPENDED in [organizationId]. */
    suspend fun search(
        organizationId: Id<Organization>,
        query: String,
    ): List<ProducerAccount>
}

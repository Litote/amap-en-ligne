@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.AccountStatus
import persistence.model.Member
import persistence.model.Owner
import kotlin.time.ExperimentalTime

interface OwnerSyncDAO {
    /** Returns all owners on this instance. */
    suspend fun listAll(): List<Owner>

    /** Returns the owner with the given [ownerId], or null if not found. */
    suspend fun findById(ownerId: Id<Owner>): Owner?

    /**
     * Atomically writes the owner row and its change record.
     * Used for inserts and updates (upsert semantics).
     */
    suspend fun put(
        owner: Owner,
        change: Change,
    )

    /**
     * Atomically transitions [accountStatus] and writes its change record.
     * Used for suspension/reactivation without a full upsert.
     */
    suspend fun updateStatus(
        ownerId: Id<Owner>,
        accountStatus: AccountStatus,
        change: Change,
    )

    /** Returns true if an owner row with the given [email] already exists. */
    suspend fun existsByEmail(email: String): Boolean

    /** Returns true if an owner row with the given [sub] already exists. */
    suspend fun existsBySub(sub: String): Boolean

    /** Returns the owner row whose [sub] matches, or null. */
    suspend fun findBySub(sub: String): Owner?

    /**
     * Atomically deletes the owner row and writes its DELETE tombstone Change.
     * Used by the OWNER lifecycle "Supprimer de l'instance" action.
     */
    suspend fun delete(
        ownerId: Id<Owner>,
        change: Change,
    )

    /**
     * Atomically promotes a user to OWNER by:
     * 1. Deleting all [membersToRevoke] rows.
     * 2. Writing all [memberChanges] tombstones.
     * 2. Inserting the new [owner] row with [ownerChange].
     *
     * All writes happen in a single atomic transaction (TransactWriteItems / Postgres BEGIN-COMMIT).
     */
    suspend fun promoteToOwner(
        owner: Owner,
        ownerChange: Change,
        membersToRevoke: List<Member>,
        memberChanges: List<Change>,
    )
}

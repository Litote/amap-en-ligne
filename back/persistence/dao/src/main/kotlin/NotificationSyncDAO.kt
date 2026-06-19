package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Notification

/**
 * Sync DAO for [Notification]. Notifications live on a private per-recipient scope
 * (`member:{id}` today; `owner:{id}` / `producer-account:{id}` later — see ADR-005).
 *
 * Every write atomically persists the entity row and its scope [Change] record, like
 * every other synced entity.
 */
interface NotificationSyncDAO {
    /** All notifications addressed to [recipientScope] (e.g. `member:42`). */
    suspend fun getByRecipientScope(recipientScope: String): List<Notification>

    suspend fun findById(
        recipientScope: String,
        notificationId: Id<Notification>,
    ): Notification?

    /** Atomically writes the notification and its change record. */
    suspend fun put(
        notification: Notification,
        change: Change,
    )

    /** Atomically deletes (archives) the notification and records the tombstone. */
    suspend fun delete(
        recipientScope: String,
        notificationId: Id<Notification>,
        change: Change,
    )
}

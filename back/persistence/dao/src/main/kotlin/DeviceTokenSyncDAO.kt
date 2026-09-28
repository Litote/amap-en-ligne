package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.DeviceToken

/**
 * Sync DAO for [DeviceToken]. Device tokens live on a private per-recipient scope
 * (`member:{sub}` / `owner:{sub}` / `producer-account:{id}` — see ADR-005), the same
 * family as `Notification`.
 *
 * Every write atomically persists the entity row and its scope [Change] record, like
 * every other synced entity.
 */
interface DeviceTokenSyncDAO {
    /** All device tokens registered for [recipientScope] (e.g. `member:42`). */
    suspend fun getByRecipientScope(recipientScope: String): List<DeviceToken>

    suspend fun findById(
        recipientScope: String,
        deviceTokenId: Id<DeviceToken>,
    ): DeviceToken?

    /** Atomically writes the device token and its change record. */
    suspend fun put(
        deviceToken: DeviceToken,
        change: Change,
    )

    /** Atomically deletes the device token and records the tombstone. */
    suspend fun delete(
        recipientScope: String,
        deviceTokenId: Id<DeviceToken>,
        change: Change,
    )
}

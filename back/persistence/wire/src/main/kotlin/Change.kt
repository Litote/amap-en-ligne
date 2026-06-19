package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import persistence.model.EntityType

/**
 * A change record describing the most recent mutation of a single domain
 * entity (e.g. `ProductType`).
 *
 * Change records live in a dedicated DynamoDB table and are written
 * atomically with the entity mutation they describe, via a single
 * `TransactWriteItems`. A client synchronising offline-first reads these
 * records to reconcile its local cache with the server state.
 *
 * At most one record exists per `(scopeKey, entityType, entityId)`
 * tuple: a subsequent mutation of the same entity overwrites the previous
 * change (the `cursor` moves forward). This keeps the table bounded to the
 * number of live entities plus delete tombstones.
 */
@Serializable
data class Change(
    /** Lexicographically-sortable ULID produced at write time. */
    val cursor: String,
    /** Domain entity type, used as discriminator. */
    @SerialName("entity_type")
    val entityType: EntityType,
    /** Opaque entity identifier as stored in the main entity table. */
    @SerialName("entity_id")
    val entityId: String,
    /** Visibility scope owning the entity state in the sync feed. */
    @SerialName("scope_key")
    val scopeKey: String,
    val op: ChangeOp,
    /**
     * Typed entity state when [op] is [ChangeOp.UPSERT];
     * `null` when [op] is [ChangeOp.DELETE] (tombstone).
     */
    val payload: EntityPayload? = null,
    /** Epoch milliseconds at which the change was produced. Debug metadata. */
    @SerialName("produced_at")
    val producedAt: Long,
)

@Serializable
enum class ChangeOp {
    UPSERT,
    DELETE,
}

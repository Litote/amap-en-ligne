package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import persistence.model.EntityType

/**
 * The mutation a client wants the server to apply, expressed as a discriminated
 * union: an [Upsert] carries the typed [EntityPayload] (whose discriminator
 * implies the target entity type) ; a [Delete] carries the [EntityType] and
 * the server-allocated id of the row to remove.
 *
 * For upserts, the entity id (real or `tmp_*` for creations) lives **inside**
 * the [EntityPayload]'s domain object, so it is not duplicated at the
 * [ClientMutation] level any more.
 */
@Serializable
sealed interface MutationOp

@Serializable
@SerialName("Upsert")
data class Upsert(
    val payload: EntityPayload,
) : MutationOp

@Serializable
@SerialName("Delete")
data class Delete(
    @SerialName("entity_type")
    val entityType: EntityType,
    @SerialName("entity_id")
    val entityId: String,
) : MutationOp

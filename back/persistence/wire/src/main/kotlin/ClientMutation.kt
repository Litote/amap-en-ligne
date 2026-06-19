package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * A pending mutation emitted by the client and submitted via `POST /v1/sync`
 * to be persisted server-side. The client tracks these locally while offline
 * and flushes them on the next sync.
 *
 * [clientOpId] is the client-chosen idempotency key. The current server does
 * not yet dedupe on retry; this field is reserved for that use and is also
 * the join key the client uses to correlate this mutation with its
 * [MutationOutcome] in the response.
 *
 * [op] is a discriminated union ([Upsert] / [Delete]). For an [Upsert],
 * the entity id (real or `tmp_*` for creations) is carried inside the
 * [EntityPayload]'s domain object; the server allocates a real id when a
 * `tmp_*` is detected and returns the mapping in
 * [MutationOutcome.serverEntityId].
 */
@Serializable
data class ClientMutation(
    @SerialName("client_op_id")
    val clientOpId: String,
    val op: MutationOp,
) {
    companion object {
        const val TMP_ID_PREFIX: String = "tmp_"
    }
}

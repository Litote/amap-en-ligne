@file:OptIn(ExperimentalTime::class)

package persistence.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Idempotency record for an APPLIED sync mutation, keyed by the client-chosen
 * `client_op_id`. When the same mutation is resent (dropped response, offline
 * retry), the sync pipeline short-circuits and replays the stored outcome —
 * including the [serverEntityId] originally allocated for a `tmp_*` creation —
 * instead of re-applying the write.
 *
 * Not a synced entity: it never appears on the wire and has no [EntityType].
 * Only APPLIED outcomes are recorded — REJECTED ones are deterministic and
 * side-effect-free to re-evaluate, and the client never resends a mutation
 * once it has received any outcome for it.
 *
 * [callerSub] pins the record to the authenticated caller (JWT-sub-derived
 * id); a lookup by a different caller ignores the record so a foreign
 * clientOpId can never leak another caller's allocated id.
 */
@Serializable
data class AppliedClientOp(
    @SerialName("client_op_id") val clientOpId: String,
    @SerialName("caller_sub") val callerSub: String,
    @SerialName("entity_type") val entityType: EntityType,
    @SerialName("server_entity_id") val serverEntityId: String? = null,
    @SerialName("applied_at") val appliedAt: Instant,
)

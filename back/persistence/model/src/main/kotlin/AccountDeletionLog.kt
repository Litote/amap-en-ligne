@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * The kind of account that was deleted. Used by audit consumers / future
 * compliance reports.
 */
enum class DeletedAccountRole {
    OWNER,
    PRODUCER,
    AMAP_MEMBER,
}

/**
 * Privacy-preserving audit record for account deletions. Stores only
 * non-identifying data:
 *  - [deletedSubHash] is `SHA-256(sub)` so the original sub is not retained.
 *  - No name, email, phone, address, or org affiliation.
 *  - [actorId] (the auth `sub` of whoever performed the action — an instance Owner or an
 *    organization Admin, see [actorRole]) is kept verbatim: the actor is
 *    not the subject of the right-to-erasure here.
 */
@Serializable
data class AccountDeletionLog(
    val id: Id<AccountDeletionLog>,
    @SerialName("deleted_sub_hash") val deletedSubHash: String,
    @SerialName("deleted_role") val deletedRole: DeletedAccountRole,
    @SerialName("deleted_at") val deletedAt: Instant,
    @SerialName("actor_id") val actorId: String,
    @SerialName("actor_role") val actorRole: DeletionActorRole,
)

/** Who performed an account deletion: an instance Owner or the Admin of the member's organization. */
enum class DeletionActorRole {
    OWNER,
    ADMIN,
}

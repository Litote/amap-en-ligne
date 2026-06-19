package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Server-side outcome for a single [ClientMutation], correlated with the
 * client's mutation via [clientOpId].
 *
 * On [MutationStatus.APPLIED]:
 *  - The mutation has been committed atomically with its corresponding
 *    [Change] record. The client must consider the local mutation flushed.
 *  - For an UPSERT submitted with a temporary id ([ClientMutation.TMP_ID_PREFIX]),
 *    [serverEntityId] holds the real id allocated by the server. The client
 *    must rewrite its local row to use this id.
 *  - For all other cases, [serverEntityId] equals [ClientMutation.entityId].
 *
 * On [MutationStatus.REJECTED]:
 *  - Nothing was written. [error] explains why and the client should surface
 *    the failure to the user (or retry after fixing the input).
 */
@Serializable
data class MutationOutcome(
    @SerialName("client_op_id")
    val clientOpId: String,
    val status: MutationStatus,
    @SerialName("server_entity_id")
    val serverEntityId: String? = null,
    val error: MutationError? = null,
)

@Serializable
enum class MutationStatus {
    APPLIED,
    REJECTED,
}

@Serializable
data class MutationError(
    val code: MutationErrorCode,
    val message: String,
)

@Serializable
enum class MutationErrorCode {
    /** The targeted entity does not exist (or no longer exists). */
    NOT_FOUND,

    /** The mutation crosses a tenant boundary the caller does not own. */
    FORBIDDEN,

    /** The payload is missing, malformed, or fails type validation. */
    INVALID_PAYLOAD,

    /** Reserved: a domain-level uniqueness constraint was violated. */
    UNIQUE_VIOLATION,

    /** Reserved: optimistic-concurrency conflict (stale write). */
    CONFLICT,

    /**
     * Granting OWNER role blocked because the target user already has a Member or Producer row.
     * An AMAP-role user cannot also be OWNER.
     */
    OWNER_EXCLUSIVE,

    /**
     * Granting PRODUCER role blocked because the target user already has a Member row or is OWNER.
     * Symmetric to [OWNER_EXCLUSIVE].
     */
    PRODUCER_EXCLUSIVE,

    /**
     * Granting an AMAP role (ADMIN/COORDINATOR/VOLUNTEER) blocked because the target user is
     * currently OWNER or PRODUCER.
     */
    MIXED_ROLES,

    /** Removing ADMIN from the last admin of an organization is not allowed. */
    LAST_ADMIN,

    /** Revoking the last OWNER of the instance is not allowed. */
    LAST_OWNER,

    /**
     * Removing the last user with PRODUCER role from a producer organisation
     * is not allowed (the producer org would have nobody to represent it).
     */
    LAST_PRODUCER,

    /**
     * The caller targeted their own account for a destructive lifecycle
     * action (suspend / reactivate / delete). Self-action is forbidden to
     * avoid lock-out.
     */
    SELF_ACTION_FORBIDDEN,

    /**
     * A delivery in status CONFIRMED has at least one DeliveryContract whose
     * coordinators list is empty. The payload is rejected so the caller can
     * either assign a coordinator first, or move the delivery back to PLANNED.
     */
    MISSING_COORDINATOR,

    /**
     * A new member subscription or a new delivery link targets a contract whose
     * max_delivery_date is in the past. Existing entries remain editable.
     */
    CONTRACT_ENDED,

    /** A contract member subscription is empty or does not match any contract product price. */
    INVALID_SUBSCRIPTION,

    /**
     * A contract shared basket is invalid: fewer than two members, a member that is not a
     * contract member, a member appearing in two shared baskets, or members whose subscriptions
     * are not identical.
     */
    INVALID_SHARED_BASKET,
}

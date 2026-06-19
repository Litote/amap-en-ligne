package email

/**
 * Identifies the role of a user whose account lifecycle changes — used by
 * email templates to tailor copy ("Votre compte AMAP ..." vs "Votre rôle de
 * Producteur ...").
 */
enum class AccountLifecycleRole {
    OWNER,
    PRODUCER,
    AMAP_MEMBER,
}

/**
 * Identifies the user impacted by a lifecycle action. Carries enough PII to
 * render the user-facing email but is **never** shared with other Owners in
 * the broadcast notifications (per RGPD — see [AccountLifecycleEmailPort]).
 */
data class AccountLifecycleTarget(
    val sub: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val role: AccountLifecycleRole,
)

/**
 * Lifecycle events that warrant notifying *other* Owners. Carries no PII of
 * the impacted user — only an opaque event description (RGPD audit notice).
 */
enum class OwnersBroadcastEvent {
    ACCOUNT_SUSPENDED,
    ACCOUNT_REACTIVATED,
    ACCOUNT_DELETED,
}

/**
 * Account lifecycle email port. Two channels:
 *
 *  - **Target user**: receives a clearly addressed email when their own
 *    account is suspended / reactivated / deleted. Carries first name, last
 *    name and the actor (an Owner email) so they can react / appeal.
 *  - **Other Owners** (broadcast): receive a privacy-preserving notification
 *    for audit. The deleted user's identity is intentionally not shared —
 *    only the event kind, the date and the actor.
 *
 * All implementations are stubs today; the real email template + delivery
 * channel is out of scope for the current cycle. Adapters log structured
 * lines so the action is traceable in dev.
 */
interface AccountLifecycleEmailPort {
    suspend fun notifyAccountSuspended(target: AccountLifecycleTarget)

    suspend fun notifyAccountReactivated(target: AccountLifecycleTarget)

    suspend fun notifyAccountDeleted(target: AccountLifecycleTarget)

    /**
     * Notify all *other* active Owners of a lifecycle event. The
     * implementation is responsible for resolving the list of recipients.
     * Crucially, the broadcast payload must not include PII of the impacted
     * user — for deletion in particular this is the only outgoing artefact
     * referencing the action (see audit log for the durable trace).
     */
    suspend fun notifyOwnersOfLifecycleEvent(
        event: OwnersBroadcastEvent,
        actorOwnerEmail: String,
        impactedRole: AccountLifecycleRole,
    )
}

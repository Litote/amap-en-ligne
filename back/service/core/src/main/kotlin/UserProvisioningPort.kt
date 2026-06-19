package core

import authentication.Role

interface UserProvisioningPort {
    /**
     * Creates an ADMIN user in the auth provider.
     * Returns the subject (user id) assigned by the auth provider.
     */
    suspend fun createAdminUser(
        email: String,
        password: String,
    ): String

    /**
     * Creates an OWNER user in the auth provider.
     * Returns the subject (user id) assigned by the auth provider.
     */
    suspend fun createOwnerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String

    /**
     * Creates a PRODUCER user in the auth provider.
     * Returns the subject (user id) assigned by the auth provider.
     * The caller uses this sub as both the auth identity and the [ProducerAccount] id.
     */
    suspend fun createProducerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String

    suspend fun createMemberUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        organizationId: String,
        roles: Set<Role>,
    ): String

    /**
     * Disables the user's authentication in the auth provider — sessions are
     * invalidated and subsequent sign-in attempts must fail until [unbanUser]
     * is called. Idempotent. Used by the OWNER lifecycle "Suspendre le compte"
     * action across all role types (Owner / Producer / AMAP).
     *
     * Adapter implementations:
     * - GoTrue: `PUT /admin/users/{sub}` with `{ "ban_duration": "876000h" }`
     *   (≈100 years, effectively permanent until reset).
     * - Cognito: `adminDisableUser`.
     */
    suspend fun banUser(sub: String)

    /**
     * Re-enables a previously banned user. Idempotent.
     *
     * - GoTrue: `PUT /admin/users/{sub}` with `{ "ban_duration": "none" }`.
     * - Cognito: `adminEnableUser`.
     */
    suspend fun unbanUser(sub: String)

    /**
     * Permanently removes the user from the auth provider. Idempotent —
     * absent users return success. Sessions are invalidated as a side
     * effect.
     *
     * - GoTrue: `DELETE /admin/users/{sub}`.
     * - Cognito: `adminDeleteUser`.
     */
    suspend fun deleteUser(sub: String)

    /**
     * Returns the auth subjects of every PRODUCER user tied to [producerAccountId].
     * Since `sub == producerAccountId` by invariant for both providers, this resolves
     * to at most one sub — the user whose sub equals [producerAccountId] — found by
     * direct lookup rather than a full scan.
     *
     * Used by the OWNER producer-deletion flow to delete every auth user attached to
     * a producer account before the entity is marked inactive.
     *
     * - GoTrue: `GET /admin/users/{producerAccountId}` — 200 → `[producerAccountId]`, 404 → `[]`.
     * - Cognito: `listUsers(filter = "sub = \"$producerAccountId\"")` — found → `[producerAccountId]`, else `[]`.
     *
     * Returns an empty list if no auth user matches.
     */
    suspend fun listAuthSubsByProducerAccount(producerAccountId: String): List<String>

    /**
     * Returns the `producerAccountId` of the PRODUCER auth user identified by [email],
     * or `null` when no such user exists or the user is not a producer.
     *
     * Since `sub == producerAccountId` by invariant for both providers, this is equivalent
     * to returning the user's `sub` after confirming the PRODUCER role.
     *
     * Used to enforce PRODUCER role exclusivity before granting an AMAP role or promoting
     * to OWNER.
     *
     * - GoTrue: scans `GET /admin/users`, matches [email] + `app_metadata.roles` contains
     *   `PRODUCER`, returns `id` (= sub = producerAccountId).
     * - Cognito: `listUsers(filter = "email = X")`, confirms PRODUCER group, returns `sub`.
     */
    suspend fun findProducerAccountIdByEmail(email: String): String?
}

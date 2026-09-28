@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class AccountStatus {
    ACTIVE,
    SUSPENDED,
}

/**
 * Instance-level owner. Presence of a row in this table materialises the OWNER role.
 * There is no [roles] field — the role is implicit.
 *
 * After the sub/id unification, [ownerId] equals the auth-provider subject (sub).
 * The [sub] field has been removed — callers that previously read [sub] should use
 * [ownerId] instead.
 */
@Serializable
data class Owner(
    @SerialName("owner_id") val ownerId: Id<Owner>,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    val email: String,
    val phone: String? = null,
    @SerialName("account_status") val accountStatus: AccountStatus = AccountStatus.ACTIVE,
    @SerialName("registered_at") val registeredAt: Instant,
    @SerialName("updated_at") val updatedAt: Instant,
    @SerialName("user_preferences") val userPreferences: UserPreferences =
        UserPreferences(
            emailNotificationsEnabled = true,
            pushNotificationsEnabled = false,
            lastUpdatedInstant = Instant.fromEpochMilliseconds(0L),
        ),
)

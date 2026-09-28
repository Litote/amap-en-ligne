@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Producer user entity associated with a producer account for production management with embedded preferences.
 */
@Serializable
data class Producer(
    @SerialName("producer_id") val producerId: Id<Producer>,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    val role: ProducerRole,
    @SerialName("association_instant") val associationInstant: Instant,
    val status: ProducerStatus,
    @SerialName("producer_preferences") val producerPreferences: ProducerPreferences,
    // User properties integrated
    @SerialName("user_preferences") val userPreferences: UserPreferences,
    @SerialName("user_settings") val userSettings: UserSettings,
)

@Serializable
enum class ProducerRole {
    OWNER,
    MANAGER,
    WORKER,
}

@Serializable
enum class ProducerStatus {
    ACTIVE,
    INACTIVE,
    SUSPENDED,
}

/**
 * Producer notification preferences (mandatory for all producers).
 */
@Serializable
data class ProducerPreferences(
    @SerialName("production_alerts_enabled") val productionAlertsEnabled: Boolean,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
)

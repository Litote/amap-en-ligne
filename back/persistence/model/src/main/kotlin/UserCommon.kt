@file:OptIn(ExperimentalTime::class)

package persistence.model

import i18n.Language
import id.Id
import kotlinx.datetime.TimeZone
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Basic user preferences and configuration settings (mandatory for all users) - shared between Member and Producer.
 */
@Serializable
data class UserSettings(
    val language: Language,
    val timezone: TimeZone,
    @SerialName("server_id")
    val serverId: Id<Server>,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
)

/**
 * Basic user communication preferences for all users (mandatory for all users) - shared between Member and Producer.
 */
@Serializable
data class UserPreferences(
    @SerialName("email_notifications_enabled") val emailNotificationsEnabled: Boolean,
    @SerialName("push_notifications_enabled") val pushNotificationsEnabled: Boolean,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
)

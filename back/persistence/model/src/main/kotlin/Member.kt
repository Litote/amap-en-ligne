@file:OptIn(ExperimentalTime::class)

package persistence.model

import authentication.Role
import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Lifecycle status for an AMAP member.
 *
 * Replaces the legacy [Member.activeStatus] boolean.
 * [PENDING_INVITATION] and [EXPIRED_INVITATION] have been removed: those
 * states now live exclusively on [MemberInvitation] and are no longer
 * stored on the Member row.
 */
@Serializable
enum class MemberAccountStatus {
    ACTIVE,
    SUSPENDED,
}

/**
 * Member with embedded contracts, registrations, and settings.
 *
 * After the sub/id unification, [memberId] equals the auth-provider subject (sub)
 * for all account-backed members. The [sub] field has been removed — callers that
 * previously read [sub] should use [memberId] instead.
 *
 * The PII fields ([firstName], [lastName], [email], [phone]) and [accountStatus]
 * are nullable for rows that have not yet been fully activated.
 */
@Serializable
data class Member(
    @SerialName("member_id")
    val memberId: Id<Member>,
    @SerialName("organization_id")
    val organizationId: Id<Organization>,
    val roles: Set<Role> = setOf(Role.VOLUNTEER),
    @SerialName("active_status") val activeStatus: Boolean,
    @SerialName("first_name") val firstName: String? = null,
    @SerialName("last_name") val lastName: String? = null,
    val email: String? = null,
    val phone: String? = null,
    @SerialName("account_status") val accountStatus: MemberAccountStatus? = null,
    val contracts: List<MemberContract> = emptyList(),
    val registrations: List<MemberRegistration> = emptyList(),
    @SerialName("member_settings") val memberSettings: MemberSettings,
    @SerialName("member_preferences") val memberPreferences: MemberPreferences,
    // User properties integrated
    @SerialName("user_preferences") val userPreferences: UserPreferences,
    @SerialName("user_settings") val userSettings: UserSettings,
)

/**
 * Member commitment to a specific contract.
 */
@Serializable
data class MemberContract(
    @SerialName("contract_id") val contractId: Id<Contract>,
    @SerialName("subscription_instant") val subscriptionInstant: Instant,
    val status: MemberContractStatus,
)

@Serializable
enum class MemberContractStatus {
    ACTIVE,
    SUSPENDED,
    COMPLETED,
    CANCELLED,
    NOT_PRESENT,
}

/**
 * Configuration settings specific to  members (mandatory for all members).
 */
@Serializable
data class MemberSettings(
    @SerialName("delivery_reminders") val deliveryReminders: DeliveryReminders,
    @SerialName("accessibility_options") val accessibilityOptions: AccessibilityOptions,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
)

@Serializable
data class DeliveryReminders(
    @SerialName("days_before") val daysBefore: Int,
    @SerialName("reminder_time") val reminderTime: String,
)

@Serializable
data class AccessibilityOptions(
    @SerialName("high_contrast") val highContrast: Boolean,
    @SerialName("large_text") val largeText: Boolean,
    @SerialName("screen_reader") val screenReader: Boolean,
)

/**
 * Notification preferences specific to  members (mandatory for all members).
 */
@Serializable
data class MemberPreferences(
    @SerialName("delivery_reminders_enabled") val deliveryRemindersEnabled: Boolean,
    @SerialName("volunteer_alerts_enabled") val volunteerAlertsEnabled: Boolean,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
    // Rappels d'inscription
    @SerialName("reminder_24h_enabled") val reminder24hEnabled: Boolean = true,
    @SerialName("reminder_2h_enabled") val reminder2hEnabled: Boolean = true,
    @SerialName("reminder_30min_enabled") val reminder30minEnabled: Boolean = false,
    // Alertes d'urgence
    @SerialName("urgent_need_alerts_enabled") val urgentNeedAlertsEnabled: Boolean = true,
    @SerialName("incomplete_slot_reminders_enabled") val incompleteSlotRemindersEnabled: Boolean = false,
    @SerialName("planning_changes_alerts_enabled") val planningChangesAlertsEnabled: Boolean = true,
)

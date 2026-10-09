package core

import authentication.AuthenticatedInfo
import authentication.Role
import persistence.changes.EntityPayload
import persistence.changes.MemberPayload
import persistence.changes.OrganizationPayload
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.Organization
import persistence.model.UserPreferences
import kotlin.time.Instant

/**
 * The organization scope is shared by every member, but a plain member (no COORDINATOR,
 * ADMIN or OWNER role) must not receive the other members' contact details:
 * - other `Member` rows are reduced to a public profile — name, roles, status; the phone is
 *   kept for coordinators only (members call them from the delivery cards); email,
 *   subscriptions, registrations, preferences and registration date are dropped;
 * - the volunteer registrations embedded in the `Organization` lose their `member_email`,
 *   except the caller's own.
 *
 * Applied by `DataService` to the bootstrap snapshots and to the incremental changes (the
 * stored `Change` rows stay complete), and reverted by [restoreRegistrationEmails] when such
 * a member writes the organization back (self-registration), so masked fields never
 * overwrite the stored ones.
 */
object MemberContactRedaction {
    private val PRIVILEGED_ROLES = setOf(Role.COORDINATOR, Role.ADMIN, Role.OWNER)
    private val NEUTRAL_INSTANT = Instant.fromEpochMilliseconds(0)

    /** Whether [auth] only gets the public profile of the other members. */
    fun appliesTo(auth: AuthenticatedInfo): Boolean = auth.roles.none { it in PRIVILEGED_ROLES }

    /** [payload] as served to the plain member [callerId]. */
    fun redact(
        payload: EntityPayload,
        callerId: String,
    ): EntityPayload =
        when (payload) {
            is MemberPayload -> if (payload.member.memberId.id == callerId) payload else MemberPayload(publicProfile(payload.member))
            is OrganizationPayload -> OrganizationPayload(redactRegistrations(payload.organization, callerId))
            else -> payload
        }

    internal fun publicProfile(member: Member): Member =
        member.copy(
            email = null,
            phone = if (Role.COORDINATOR in member.roles) member.phone else null,
            contracts = emptyList(),
            registrations = emptyList(),
            memberPreferences =
                MemberPreferences(
                    deliveryRemindersEnabled = false,
                    volunteerAlertsEnabled = false,
                    lastUpdatedInstant = NEUTRAL_INSTANT,
                    urgentNeedAlertsEnabled = false,
                    incompleteSlotRemindersEnabled = false,
                    planningChangesAlertsEnabled = false,
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = false,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = NEUTRAL_INSTANT,
                ),
            userSettings = member.userSettings.copy(lastUpdatedInstant = NEUTRAL_INSTANT),
            registeredAt = null,
        )

    internal fun redactRegistrations(
        organization: Organization,
        callerId: String,
    ): Organization =
        organization.mapRegistrations { registration ->
            if (registration.memberId.id == callerId) registration else registration.copy(memberEmail = "")
        }

    /**
     * [incoming] (written by a plain member) with every masked registration email taken back
     * from [persisted], matched by member: the member only sent back what they were served.
     */
    fun restoreRegistrationEmails(
        persisted: Organization?,
        incoming: Organization,
    ): Organization {
        if (persisted == null) return incoming
        val storedEmails =
            persisted.deliveries
                .flatMap { delivery -> delivery.contracts.flatMap { link -> link.slots.flatMap { it.registrations } } }
                .filter { it.memberEmail.isNotBlank() }
                .associate { it.memberId to it.memberEmail }
        return incoming.mapRegistrations { registration ->
            val stored = storedEmails[registration.memberId]
            if (registration.memberEmail.isBlank() && stored != null) registration.copy(memberEmail = stored) else registration
        }
    }

    private fun Organization.mapRegistrations(transform: (MemberRegistration) -> MemberRegistration): Organization =
        copy(
            deliveries =
                deliveries.map { delivery ->
                    delivery.copy(
                        contracts =
                            delivery.contracts.map { link ->
                                link.copy(
                                    slots = link.slots.map { slot -> slot.copy(registrations = slot.registrations.map(transform)) },
                                )
                            },
                    )
                },
        )
}

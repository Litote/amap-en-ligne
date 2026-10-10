package core

import authentication.AuthenticatedInfo
import authentication.Role
import id.Id
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import persistence.changes.BasketExchangePayload
import persistence.changes.ContractPayload
import persistence.changes.EntityPayload
import persistence.changes.MemberPayload
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.Contract
import persistence.model.DeliveryContract
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.RegistrationStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.time.Instant

/**
 * The organization scope is shared by every member, but a plain member (no COORDINATOR,
 * ADMIN or OWNER role) only receives what their screens need about the others:
 * - other `Member` rows are a public profile — name, roles, status; the phone is kept for
 *   coordinators only (members call them from the delivery cards); email, subscriptions,
 *   registrations, preferences and registration date are dropped;
 * - the volunteer registrations of the others lose their email and registration date, and
 *   their cancellations (unregistered / marked absent) are dropped; on past deliveries they
 *   are anonymous ([ANONYMOUS_MEMBER_ID], no name) — the counters stay right but nobody's
 *   attendance history can be read. Registrations of the link's coordinators keep their
 *   identity (a public role) and only lose the email;
 * - the coordinators' preparation notes are dropped;
 * - `Contract.members` only keeps the caller's own subscription;
 * - non-ACTIVE (suspended, deleted) members are not served; the others' `user_settings` are
 *   neutralised;
 * - producers are served without their contact details (email, address, website),
 *   preferences or login users;
 * - basket exchanges are served only when OPEN (available offers) or when the caller is the
 *   offerer or one of the requesters — the all-members overview is a coordinator screen;
 * - the organization carries [Organization.participationCountsBySeason] instead, so the
 *   (anonymous) ranking is still computed client-side.
 *
 * Applied by `DataService` to the bootstrap snapshots and the incremental changes (stored
 * rows stay complete). When such a member writes the organization back (self-registration),
 * `OrganizationService` only keeps their own registrations from it, so masked values never
 * overwrite the stored ones.
 */
object PlainMemberRedaction {
    /** Member id of an anonymised past registration. */
    const val ANONYMOUS_MEMBER_ID = "anonymous"

    /**
     * Prefix of the organization-scope cursors issued to a plain member: a cursor tells which
     * view (masked or full) the client's cache holds. When it no longer matches the caller's
     * view — a cache synced before the masking was deployed, a role change — `DataService`
     * answers one bootstrap in the right view, then diffs as usual. Clients never parse
     * cursors (opaque), so the prefix is invisible to them.
     */
    const val CURSOR_MARK = "pm."

    /** [cursor] (a change-log cursor) as issued for the given view. */
    fun cursorFor(
        cursor: String,
        masked: Boolean,
    ): String = if (masked) CURSOR_MARK + cursor else cursor

    /** Whether [cursor] was issued for the masked view. */
    fun isMaskedViewCursor(cursor: String): Boolean = cursor.startsWith(CURSOR_MARK)

    /** The change-log cursor behind a client [cursor]. */
    fun changeLogCursor(cursor: String): String = cursor.removePrefix(CURSOR_MARK)

    private val PRIVILEGED_ROLES = setOf(Role.COORDINATOR, Role.ADMIN, Role.OWNER)
    private val NEUTRAL_INSTANT = Instant.fromEpochMilliseconds(0)

    /** What a plain member's served organization payloads depend on. */
    class Context(
        val callerId: String,
        val now: Instant,
        /** The organization's members (for the anonymous participation counts). */
        val members: List<Member>,
        /** The organization's contracts (season of each delivery link). */
        val contracts: List<Contract>,
    )

    /** Whether [auth] only gets the plain-member view of the organization scope. */
    fun appliesTo(auth: AuthenticatedInfo): Boolean = auth.roles.none { it in PRIVILEGED_ROLES }

    /** Whether redacting [payload] needs the organization's members and contracts. */
    fun needsContext(payload: EntityPayload): Boolean = payload is OrganizationPayload

    /**
     * [payload] as served to the plain member [callerId], or null when it is not served at all
     * (an incremental change then becomes a tombstone so the cache drops it). [context] is
     * required for an [OrganizationPayload] (see [needsContext]).
     */
    fun redact(
        payload: EntityPayload,
        callerId: String,
        context: Context? = null,
    ): EntityPayload? =
        when (payload) {
            is MemberPayload -> {
                val member = payload.member
                when {
                    member.memberId.id == callerId -> payload
                    member.accountStatus != MemberAccountStatus.ACTIVE -> null
                    else -> MemberPayload(publicProfile(member))
                }
            }

            is ProducerAccountPayload -> {
                ProducerAccountPayload(publicProducer(payload.producerAccount))
            }

            is BasketExchangePayload -> {
                payload.takeIf { isVisibleExchange(it.basketExchange, callerId) }
            }

            is ContractPayload -> {
                ContractPayload(payload.contract.copy(members = payload.contract.members.filter { it.memberId.id == callerId }))
            }

            is OrganizationPayload -> {
                val ctx = requireNotNull(context) { "an organization payload needs a redaction context" }
                val today = ctx.now.toLocalDateTime(payload.organization.timezone).date
                OrganizationPayload(
                    redactOrganization(payload.organization, callerId, today).copy(
                        participationCountsBySeason = participationCountsBySeason(payload.organization, ctx.members, ctx.contracts),
                    ),
                )
            }

            else -> {
                payload
            }
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
            userSettings =
                UserSettings(
                    language = "",
                    timezone = TimeZone.UTC,
                    serverId = Id(""),
                    lastUpdatedInstant = NEUTRAL_INSTANT,
                ),
            registeredAt = null,
        )

    internal fun publicProducer(producer: ProducerAccount): ProducerAccount =
        producer.copy(
            contactEmail = null,
            address = null,
            website = null,
            users = emptyList(),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = false,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = NEUTRAL_INSTANT,
                ),
        )

    /** An available offer, or an exchange the caller takes part in. */
    internal fun isVisibleExchange(
        exchange: BasketExchange,
        callerId: String,
    ): Boolean =
        exchange.status == BasketExchangeStatus.OPEN ||
            exchange.offeringMemberId.id == callerId ||
            exchange.requests.any { it.requesterMemberId.id == callerId }

    /** [organization] as a plain member sees it, without [Organization.participationCountsBySeason]. */
    internal fun redactOrganization(
        organization: Organization,
        callerId: String,
        today: LocalDate,
    ): Organization =
        organization.copy(
            deliveries =
                organization.deliveries.map { delivery ->
                    val past = delivery.scheduledDate.date < today
                    delivery.copy(
                        contracts =
                            delivery.contracts.map { link ->
                                link.copy(
                                    preparationNotes = null,
                                    slots =
                                        link.slots.map { slot ->
                                            slot.copy(
                                                registrations =
                                                    ownOf(slot, callerId) + maskOthers(othersOf(slot, callerId), link, past),
                                            )
                                        },
                                )
                            },
                    )
                },
        )

    /**
     * For every season year of [contracts], the present-registration counts (CONFIRMED or
     * COMPLETED, on that season's contracts) of the ACTIVE members — one anonymous entry per
     * member, the caller included. Mirrors the front ranking (`memberRankIn`).
     */
    internal fun participationCountsBySeason(
        organization: Organization,
        members: List<Member>,
        contracts: List<Contract>,
    ): Map<Int, List<Int>> {
        val activeMembers = members.filter { it.accountStatus == MemberAccountStatus.ACTIVE }.map { it.memberId }
        val seasonByContract = contracts.associate { it.contractId to it.seasonYear }
        return seasonByContract.values.toSet().associateWith { season ->
            val counts = mutableMapOf<Id<Member>, Int>()
            organization.deliveries
                .flatMap { it.contracts }
                .filter { seasonByContract[it.contractId] == season }
                .flatMap { link -> link.slots.flatMap { it.registrations } }
                .filter { it.status == RegistrationStatus.CONFIRMED || it.status == RegistrationStatus.COMPLETED }
                .forEach { counts[it.memberId] = (counts[it.memberId] ?: 0) + 1 }
            activeMembers.map { counts[it] ?: 0 }.sortedDescending()
        }
    }

    private fun ownOf(
        slot: MemberSlot,
        callerId: String,
    ) = slot.registrations.filter { it.memberId.id == callerId }

    private fun othersOf(
        slot: MemberSlot,
        callerId: String,
    ) = slot.registrations.filter { it.memberId.id != callerId }

    private fun maskOthers(
        others: List<MemberRegistration>,
        link: DeliveryContract,
        past: Boolean,
    ): List<MemberRegistration> =
        others.mapNotNull { registration ->
            when {
                registration.memberId in link.coordinators -> {
                    registration.copy(memberEmail = "")
                }

                registration.status == RegistrationStatus.CANCELLED -> {
                    null
                }

                past -> {
                    registration.copy(
                        memberId = Id(ANONYMOUS_MEMBER_ID),
                        displayName = "",
                        memberEmail = "",
                        registrationInstant = NEUTRAL_INSTANT,
                    )
                }

                else -> {
                    registration.copy(memberEmail = "", registrationInstant = NEUTRAL_INSTANT)
                }
            }
        }
}

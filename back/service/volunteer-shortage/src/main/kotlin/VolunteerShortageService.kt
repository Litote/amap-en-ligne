@file:OptIn(ExperimentalTime::class)

package volunteershortage

import core.toFrenchLongDate
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.toInstant
import notificationpublisher.NotificationContact
import notificationpublisher.NotificationContent
import notificationpublisher.NotificationPublisher
import notificationpublisher.optedNotificationChannels
import notificationpublisher.resolveCopy
import org.koin.core.annotation.Single
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.SentAlertDAO
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitationStatus
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Scheduled job sending the volunteer shortage alerts to the members who opted in
 * (`MemberPreferences.incompleteSlotRemindersEnabled` / `urgentNeedAlertsEnabled`).
 *
 * For every active delivery still short of volunteers, the organization's active members who
 * are neither registered on it nor coordinating it get:
 * - [AlertKind.SHORTAGE] [SHORTAGE_LEAD] before the delivery;
 * - [AlertKind.URGENT_NEED] [URGENT_NEED_LEAD] before the delivery, if it is still short.
 *
 * The staffing rule mirrors the front "N/M bénévoles" counter: only the slots of the main
 * contracts count (every contract when none is main), cancelled slots are ignored and the
 * delivery's coordinators never count as volunteers.
 *
 * Idempotent: each (organization, delivery, member, kind) alert is recorded in [SentAlertDAO]
 * before being published, so overlapping or repeated runs never send it twice. An alert whose
 * due time was missed by more than the run's `lookback` (job down) is dropped rather than sent late.
 */
@Single(createdAtStart = true)
class VolunteerShortageService(
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val memberInvitationSyncDAO: MemberInvitationSyncDAO,
    private val sentAlertDAO: SentAlertDAO,
    private val notificationPublisher: NotificationPublisher,
) {
    /**
     * Sends the alerts due at [now]. [lookback] is the tolerance on the due time, so a delayed
     * or skipped tick still sends the alert — keep it above the scheduling interval.
     */
    suspend fun run(
        now: Instant,
        lookback: Duration = DEFAULT_LOOKBACK,
    ) {
        runCatching { sentAlertDAO.purgeBefore(now - RETENTION) }
            .onFailure { logger.warn(it) { "failed to purge sent alerts" } }
        for (organization in organizationSyncDAO.listAll()) {
            if (!organization.activeStatus) continue
            runCatching { processOrganization(organization, now, lookback) }
                .onFailure { logger.warn(it) { "volunteer shortage alerts failed for ${organization.organizationId.id}" } }
        }
    }

    private suspend fun processOrganization(
        organization: Organization,
        now: Instant,
        lookback: Duration,
    ) {
        val dueAlerts =
            organization.deliveries
                .filter { it.status.isActive() }
                .flatMap { delivery ->
                    val start = delivery.scheduledDate.toInstant(organization.timezone)
                    AlertKind.entries
                        .filter { kind -> isDue(start - kind.lead, start, now, lookback) }
                        .map { kind -> delivery to kind }
                }
        if (dueAlerts.isEmpty()) return

        val contracts = contractSyncDAO.getByOrganizationId(organization.organizationId)
        val members = memberSyncDAO.getByOrganizationId(organization.organizationId)
        val pendingEmails =
            memberInvitationSyncDAO
                .listByOrganizationId(organization.organizationId)
                .filter { it.status == MemberInvitationStatus.PENDING_ACTIVATION }
                .map { it.email.lowercase() }
                .toSet()
        val activeMembers =
            members.filter { member ->
                member.accountStatus == MemberAccountStatus.ACTIVE &&
                    member.email?.lowercase() !in pendingEmails
            }

        for ((delivery, kind) in dueAlerts) {
            if (isPendingContractActivation(delivery, contracts)) continue
            val missing = missingVolunteers(delivery, contracts)
            if (missing <= 0) continue
            val busyMemberIds = deliveryCoordinatorIds(delivery) + registeredMemberIds(delivery)
            activeMembers
                .filter { it.memberId.id !in busyMemberIds && kind.isEnabledFor(it) }
                .forEach { member -> alert(organization, delivery, member, kind, missing, now) }
        }
    }

    private fun isDue(
        dueAt: Instant,
        start: Instant,
        now: Instant,
        lookback: Duration,
    ): Boolean = dueAt <= now && dueAt > now - lookback && start > now

    private suspend fun alert(
        organization: Organization,
        delivery: Delivery,
        member: Member,
        kind: AlertKind,
        missing: Int,
        now: Instant,
    ) {
        val key = "${organization.organizationId.id}|${delivery.deliveryId.id}|${member.memberId.id}|${kind.name}"
        if (!sentAlertDAO.markIfAbsent(key, now)) return
        val date = frenchDateLabel(delivery.scheduledDate)
        val copy = organization.notificationOverrides.resolveCopy(kind.category, kind.title, kind.body(date, missing))
        notificationPublisher.publish(
            recipientScope = SyncScope.Member(member.memberId.id).key,
            type = kind.type,
            category = kind.category,
            content =
                NotificationContent(
                    title = copy.title,
                    body = copy.body,
                    deepLink = PLANNING_DEEP_LINK,
                    relatedEntityId = delivery.deliveryId.id,
                ),
            contact = NotificationContact(email = member.email, organizationName = organization.name),
            channels = member.optedNotificationChannels(),
        )
    }

    internal enum class AlertKind(
        val lead: Duration,
        val category: NotificationCategory,
        val type: NotificationType,
        val title: String,
    ) {
        SHORTAGE(SHORTAGE_LEAD, NotificationCategory.VOLUNTEER_SHORTAGE, NotificationType.REMINDER, "Bénévoles recherchés"),
        URGENT_NEED(URGENT_NEED_LEAD, NotificationCategory.VOLUNTEER_URGENT_NEED, NotificationType.URGENT, "Besoin urgent de bénévoles"),
        ;

        fun isEnabledFor(member: Member): Boolean =
            when (this) {
                SHORTAGE -> member.memberPreferences.incompleteSlotRemindersEnabled
                URGENT_NEED -> member.memberPreferences.urgentNeedAlertsEnabled
            }

        fun body(
            date: String,
            missing: Int,
        ): String {
            val volunteers = if (missing > 1) "$missing bénévoles" else "1 bénévole"
            return when (this) {
                SHORTAGE -> "Il manque $volunteers pour la livraison du $date. Inscrivez-vous sur le planning !"
                URGENT_NEED -> "La livraison du $date manque encore de $volunteers. Pouvez-vous aider ?"
            }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

internal val SHORTAGE_LEAD = 3.days
internal val URGENT_NEED_LEAD = 24.hours
internal val DEFAULT_LOOKBACK = 30.minutes
private val RETENTION = 30.days
private const val PLANNING_DEEP_LINK = "/planning"

/** A delivery whose linked contracts are all still being prepared is hidden from plain members. */
internal fun isPendingContractActivation(
    delivery: Delivery,
    contracts: List<Contract>,
): Boolean {
    val linked = delivery.contracts.mapNotNull { link -> contracts.find { it.contractId == link.contractId } }
    return linked.isNotEmpty() && linked.all { it.status == ContractStatus.IN_PREPARATION }
}

/**
 * Volunteers still missing on [delivery]: required minus active non-coordinator registrations,
 * over the non-cancelled slots of its main contracts (every contract when none is main).
 */
internal fun missingVolunteers(
    delivery: Delivery,
    contracts: List<Contract>,
): Int {
    val coordinatorIds = deliveryCoordinatorIds(delivery)
    val slots =
        volunteerCountingContracts(delivery, contracts)
            .flatMap { it.slots }
            .filter { it.status != SlotStatus.CANCELLED }
    val required = slots.sumOf { it.requiredVolunteers }
    val current =
        slots.sumOf { slot ->
            slot.registrations.count { it.status != RegistrationStatus.CANCELLED && it.memberId.id !in coordinatorIds }
        }
    return required - current
}

private fun volunteerCountingContracts(
    delivery: Delivery,
    contracts: List<Contract>,
): List<DeliveryContract> {
    val mainIds = contracts.filter { it.isMainContract }.map { it.contractId }.toSet()
    val mains = delivery.contracts.filter { it.contractId in mainIds }
    return mains.ifEmpty { delivery.contracts }
}

private fun deliveryCoordinatorIds(delivery: Delivery): Set<String> =
    delivery.contracts
        .flatMap { it.coordinators }
        .map { it.id }
        .toSet()

private fun registeredMemberIds(delivery: Delivery): Set<String> =
    delivery.contracts
        .flatMap { it.slots }
        .flatMap { it.registrations }
        .filter { it.status != RegistrationStatus.CANCELLED }
        .map { it.memberId.id }
        .toSet()

private fun frenchDateLabel(dateTime: LocalDateTime): String = dateTime.date.toFrenchLongDate()

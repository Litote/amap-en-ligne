package organization

import core.ProducerScheduleProjection
import id.Id
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.toLocalDateTime
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Organization
import kotlin.time.Instant

/**
 * Scheduled job closing past deliveries: every still-active delivery (PLANNED, CONFIRMED,
 * IN_PROGRESS) whose scheduled day is before today in the organization's timezone is marked
 * COMPLETED — what the coordinator's « ARCHIVER » does, so a forgotten distribution never
 * stays open. Only the status changes: unrecorded registrations are left as they are, and
 * presences / collection can still be recorded afterwards (a completed delivery stays
 * editable). CANCELLED deliveries are untouched.
 *
 * Triggered with the volunteer shortage alerts (JVM poll loop, Lambda scheduled handler).
 * Idempotent: a run with nothing to close writes nothing.
 */
@Single
class DeliveryAutoCloseService(
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
) {
    suspend fun run(now: Instant) {
        for (organization in organizationSyncDAO.listAll()) {
            try {
                closePastDeliveries(organization.organizationId, now)
            } catch (e: Exception) {
                logger.error(e) { "Auto-close failed for organization ${organization.organizationId.id}" }
            }
        }
    }

    private suspend fun closePastDeliveries(
        organizationId: Id<Organization>,
        now: Instant,
    ) {
        // Re-read right before writing to narrow the window with a concurrent coordinator edit.
        val persisted = organizationSyncDAO.getById(organizationId) ?: return
        val today = now.toLocalDateTime(persisted.timezone).date
        val toClose =
            persisted.deliveries
                .filter { it.status.isActive() && it.scheduledDate.date < today }
                .map { it.deliveryId }
                .toSet()
        if (toClose.isEmpty()) return

        val closed =
            persisted.copy(
                deliveries =
                    persisted.deliveries.map {
                        if (it.deliveryId in toClose) it.copy(status = DeliveryStatus.COMPLETED) else it
                    },
                lastUpdatedInstant = now,
            )
        val contracts = contractSyncDAO.getByOrganizationId(organizationId)
        organizationSyncDAO.put(
            closed,
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Organization,
                entityId = organizationId.id,
                scopeKey = SyncScope.Organization(organizationId.id).key,
                op = ChangeOp.UPSERT,
                payload = OrganizationPayload(closed),
                producedAt = now.toEpochMilliseconds(),
            ),
            ProducerScheduleProjection.changes(persisted, contracts, closed, contracts),
        )
        logger.info { "Auto-closed ${toClose.size} past delivery(ies) of organization ${organizationId.id}" }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

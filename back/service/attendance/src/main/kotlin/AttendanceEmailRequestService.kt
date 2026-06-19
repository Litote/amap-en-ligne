@file:OptIn(ExperimentalTime::class)

package attendance

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.AttendanceEmailPort
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.AttendanceEmailRequestPayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.AttendanceEmailRequest
import persistence.model.EntityType
import persistence.model.Organization
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

/**
 * EntityTypeService for [AttendanceEmailRequest].
 *
 * Scope: organization:{organizationId}
 *
 * Only COORDINATOR, ADMIN, and OWNER callers may submit an upsert.
 * The server sets [AttendanceEmailRequest.sentAt] and sends the email as a best-effort
 * post-persist side-effect. Delete is always FORBIDDEN.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
internal class AttendanceEmailRequestService(
    private val attendanceEmailRequestSyncDAO: AttendanceEmailRequestSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val basketExchangeSyncDAO: BasketExchangeSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val attendanceEmailPort: AttendanceEmailPort,
) : EntityTypeService<AttendanceEmailRequestPayload>(EntityType.AttendanceEmailRequest) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: AttendanceEmailRequestPayload,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")

        requireAnyRole(auth, ALLOWED_ROLES, mutation, "only COORDINATOR, ADMIN, or OWNER may send attendance emails")
            ?.let { return it }

        val incoming = payload.attendanceEmailRequest

        if (incoming.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }

        val org =
            organizationSyncDAO.getById(incoming.organizationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "organization not found")

        val delivery =
            org.deliveries.firstOrNull { it.deliveryId.id == incoming.deliveryId }
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "delivery not found: ${incoming.deliveryId}")

        val now = Clock.System.now()
        val realId =
            if (incoming.attendanceEmailRequestId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
                generateId<AttendanceEmailRequest>()
            } else {
                incoming.attendanceEmailRequestId
            }

        val persisted =
            incoming.copy(
                attendanceEmailRequestId = realId,
                sentAt = now,
            )

        val change =
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.AttendanceEmailRequest,
                entityId = realId.id,
                scopeKey = SyncScope.Organization(organizationId).key,
                op = ChangeOp.UPSERT,
                payload = AttendanceEmailRequestPayload(persisted),
                producedAt = System.currentTimeMillis(),
            )

        attendanceEmailRequestSyncDAO.put(persisted, change)

        runCatching {
            val exchanges = basketExchangeSyncDAO.getByOrganizationId(incoming.organizationId)
            val members = memberSyncDAO.getByOrganizationId(incoming.organizationId)
            attendanceEmailPort.sendAttendanceSheets(org, delivery, exchanges, members, persisted.recipientEmail)
        }.onFailure { e ->
            logger.error(e) { "Attendance email send failed for delivery ${persisted.deliveryId}" }
        }

        return applied(mutation, realId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome =
        rejected(
            mutation,
            MutationErrorCode.FORBIDDEN,
            "attendance email requests cannot be deleted",
        )

    override suspend fun snapshot(auth: AuthenticatedInfo): List<AttendanceEmailRequestPayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return attendanceEmailRequestSyncDAO
            .getByOrganizationId(organizationId.toId<Organization>())
            .map { AttendanceEmailRequestPayload(it) }
    }

    private companion object {
        private val ALLOWED_ROLES = setOf(Role.COORDINATOR, Role.ADMIN, Role.OWNER)
        private val logger = KotlinLogging.logger {}
    }
}

@file:OptIn(ExperimentalTime::class)

package organizationrequest

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.ActivationEmailPort
import email.RejectionEmailPort
import id.generateId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationRequestPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class OrganizationRequestService(
    private val organizationRequestSyncDAO: OrganizationRequestSyncDAO,
    private val organizationRequestDAO: OrganizationRequestDAO,
    private val organizationDAO: OrganizationDAO,
    private val activationTokenDAO: ActivationTokenDAO,
    private val activationEmailPort: ActivationEmailPort,
    private val rejectionEmailPort: RejectionEmailPort,
) : EntityTypeService<OrganizationRequestPayload>(EntityType.OrganizationRequest) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: OrganizationRequestPayload,
    ): MutationOutcome {
        logger.info {
            "OrganizationRequest upsert: requestId=${payload.organizationRequest.requestId.id} status=${payload.organizationRequest.status} caller=${auth.roles}"
        }
        if (!auth.roles.any { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing owner role")
        }
        val newRequest = payload.organizationRequest
        val existing =
            organizationRequestDAO.findById(newRequest.requestId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "organization request not found")

        if (existing.status == OrganizationRequestStatus.APPROVED) {
            return handleResend(mutation, existing, newRequest.resendRequestedAt)
        }

        if (existing.status != OrganizationRequestStatus.PENDING_VALIDATION) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "request is already processed")
        }
        val newStatus = newRequest.status
        if (newStatus !in listOf(OrganizationRequestStatus.APPROVED, OrganizationRequestStatus.REJECTED)) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invalid state transition")
        }
        val now = Clock.System.now()
        val updatedRequest =
            existing.copy(
                status = newStatus,
                reviewedAt = now,
                reviewComment = newRequest.reviewComment,
            )
        return if (newStatus == OrganizationRequestStatus.APPROVED) {
            val organization =
                Organization(
                    organizationId = generateId(),
                    name = existing.organizationName,
                    contactEmail = existing.adminEmail,
                    activeStatus = true,
                    timezone = existing.timezone,
                    defaultLanguage = existing.defaultLanguage,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                )
            organizationDAO.create(organization)
            val activationToken =
                ActivationToken(
                    token = UUID.randomUUID().toString(),
                    requestId = existing.requestId,
                    adminEmail = existing.adminEmail,
                    organizationId = organization.organizationId,
                    createdAt = now,
                    expiresAt = now + 72.hours,
                )
            activationTokenDAO.create(activationToken)
            val finalRequest = updatedRequest.copy(organizationId = organization.organizationId)
            activationEmailPort.scheduleActivationEmail(activationToken, finalRequest)
            logger.info {
                "Organization ${organization.organizationId.id} created for request ${existing.requestId.id} — activation token generated for ${existing.adminEmail}"
            }
            organizationRequestSyncDAO.put(finalRequest, buildChange(finalRequest))
            applied(mutation, finalRequest.requestId.id)
        } else {
            rejectionEmailPort.sendRejectionEmail(updatedRequest, updatedRequest.reviewComment)
            logger.info { "Rejection email scheduled for ${existing.adminEmail} (request ${existing.requestId.id})" }
            organizationRequestSyncDAO.put(updatedRequest, buildChange(updatedRequest))
            applied(mutation, updatedRequest.requestId.id)
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "delete not allowed for organization requests")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<OrganizationRequestPayload> {
        if (!auth.roles.any { it == Role.OWNER }) return emptyList()
        return organizationRequestSyncDAO.listAll().map { OrganizationRequestPayload(it) }
    }

    private suspend fun handleResend(
        mutation: ClientMutation,
        existing: OrganizationRequest,
        resendRequestedAt: Instant?,
    ): MutationOutcome {
        if (resendRequestedAt == null) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "request is already processed")
        }
        val persistedResendRequestedAt = existing.resendRequestedAt
        if (persistedResendRequestedAt != null && resendRequestedAt < persistedResendRequestedAt) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "resend_requested_at must move forward")
        }
        if (persistedResendRequestedAt == resendRequestedAt) {
            return applied(mutation, existing.requestId.id)
        }
        val organizationId =
            existing.organizationId
                ?: return rejected(mutation, MutationErrorCode.CONFLICT, "no organization associated with this request")
        val now = Clock.System.now()
        val updated = existing.copy(resendRequestedAt = resendRequestedAt)
        activationTokenDAO.invalidateByOrganizationRequestId(existing.requestId, now)
        val token =
            ActivationToken(
                token = UUID.randomUUID().toString(),
                requestId = existing.requestId,
                adminEmail = existing.adminEmail,
                organizationId = organizationId,
                createdAt = now,
                expiresAt = now + 72.hours,
            )
        activationTokenDAO.create(token)
        activationEmailPort.scheduleActivationEmail(token, updated)
        organizationRequestSyncDAO.put(updated, buildChange(updated))
        return applied(mutation, updated.requestId.id)
    }

    private fun buildChange(request: OrganizationRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.OrganizationRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OrganizationRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

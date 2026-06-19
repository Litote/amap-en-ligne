@file:OptIn(ExperimentalTime::class)

package producerrequest

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import email.ProducerActivationEmailPort
import email.ProducerRequestRejectionEmailPort
import id.generateId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.ProducerRequestPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.EntityType
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProducerRequestService(
    private val producerRequestSyncDAO: ProducerRequestSyncDAO,
    private val producerRequestDAO: ProducerRequestDAO,
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val activationTokenDAO: ActivationTokenDAO,
    private val producerActivationEmailPort: ProducerActivationEmailPort,
    private val producerRequestRejectionEmailPort: ProducerRequestRejectionEmailPort,
) : EntityTypeService<ProducerRequestPayload>(EntityType.ProducerRequest) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerRequestPayload,
    ): MutationOutcome {
        if (!auth.roles.any { it == Role.OWNER }) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing owner role")
        }
        val newRequest = payload.producerRequest
        val existing =
            producerRequestDAO.findById(newRequest.requestId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "producer request not found")

        if (existing.status == ProducerRequestStatus.APPROVED) {
            return handleResend(mutation, existing, newRequest.resendRequestedAt)
        }

        if (existing.status != ProducerRequestStatus.PENDING_VALIDATION) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "request is already processed")
        }
        val newStatus = newRequest.status
        if (newStatus !in listOf(ProducerRequestStatus.APPROVED, ProducerRequestStatus.REJECTED)) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "invalid state transition")
        }
        val now = Clock.System.now()
        val updatedRequest =
            existing.copy(
                status = newStatus,
                reviewedAt = now,
                reviewComment = newRequest.reviewComment,
            )
        if (newStatus == ProducerRequestStatus.APPROVED) {
            val producerAccount =
                ProducerAccount(
                    producerAccountId = generateId(),
                    name = existing.producerName,
                    contactEmail = existing.adminEmail,
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    organizations = emptyList(),
                    products = emptyList(),
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED,
                )
            producerAccountSyncDAO.createStandalone(producerAccount)
            val activationToken =
                ActivationToken(
                    token = UUID.randomUUID().toString(),
                    kind = ActivationKind.PRODUCER,
                    producerRequestId = existing.requestId,
                    adminEmail = existing.adminEmail,
                    producerAccountId = producerAccount.producerAccountId,
                    createdAt = now,
                    expiresAt = now + 72.hours,
                )
            activationTokenDAO.create(activationToken)
            producerActivationEmailPort.sendProducerActivationEmail(updatedRequest, activationToken)
            val finalRequest = updatedRequest.copy(producerAccountId = producerAccount.producerAccountId)
            producerRequestSyncDAO.put(finalRequest, buildChange(finalRequest))
            return applied(mutation, finalRequest.requestId.id)
        } else {
            producerRequestRejectionEmailPort.sendRejectionEmail(updatedRequest, updatedRequest.reviewComment)
            producerRequestSyncDAO.put(updatedRequest, buildChange(updatedRequest))
            return applied(mutation, updatedRequest.requestId.id)
        }
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "delete not allowed for producer requests")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ProducerRequestPayload> {
        if (!auth.roles.any { it == Role.OWNER }) return emptyList()
        return producerRequestSyncDAO.listAll().map(::ProducerRequestPayload)
    }

    private suspend fun handleResend(
        mutation: ClientMutation,
        existing: ProducerRequest,
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
        val producerAccountId =
            existing.producerAccountId
                ?: return rejected(mutation, MutationErrorCode.CONFLICT, "no producer account associated with this request")
        val now = Clock.System.now()
        val updated = existing.copy(resendRequestedAt = resendRequestedAt)
        activationTokenDAO.invalidateByProducerRequestId(existing.requestId, now)
        val token =
            ActivationToken(
                token = UUID.randomUUID().toString(),
                kind = ActivationKind.PRODUCER,
                producerRequestId = existing.requestId,
                adminEmail = existing.adminEmail,
                producerAccountId = producerAccountId,
                createdAt = now,
                expiresAt = now + 72.hours,
            )
        activationTokenDAO.create(token)
        producerActivationEmailPort.sendProducerActivationEmail(updated, token)
        producerRequestSyncDAO.put(updated, buildChange(updated))
        return applied(mutation, updated.requestId.id)
    }

    private fun buildChange(request: ProducerRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProducerRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = ProducerRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )
}

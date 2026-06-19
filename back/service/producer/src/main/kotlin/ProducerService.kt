@file:OptIn(ExperimentalTime::class)

package producer

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.ProducerPayload
import persistence.changes.SyncScope
import persistence.dao.ProducerSyncDAO
import persistence.model.EntityType
import persistence.model.Producer
import persistence.model.ProducerAccount
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProducerService(
    private val producerSyncDAO: ProducerSyncDAO,
) : EntityTypeService<ProducerPayload>(EntityType.Producer) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerPayload,
    ): MutationOutcome {
        if (!auth.roles.contains(Role.PRODUCER)) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only producers can update their own profile")
        }
        val incoming = payload.producer
        if (incoming.producerId.id != auth.memberId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "cannot update another producer's profile")
        }
        val existing =
            producerSyncDAO.findByProducerId(incoming.producerId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "producer not found")
        if (incoming.producerAccountId != existing.producerAccountId || incoming.role != existing.role) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "producerAccountId and role are immutable")
        }
        val updated =
            existing.copy(
                producerPreferences = incoming.producerPreferences,
                userPreferences = incoming.userPreferences,
                userSettings = incoming.userSettings,
            )
        producerSyncDAO.put(updated, listOf(buildChange(updated, ChangeOp.UPSERT)))
        return applied(mutation, updated.producerId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "producer deletion not supported through sync")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ProducerPayload> {
        if (!auth.roles.contains(Role.PRODUCER)) return emptyList()
        val producerAccountId = auth.producerAccountId?.toId<ProducerAccount>() ?: return emptyList()
        return producerSyncDAO.getByProducerAccountId(producerAccountId).map(::ProducerPayload)
    }

    private fun buildChange(
        producer: Producer,
        op: ChangeOp,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Producer,
            entityId = producer.producerId.id,
            scopeKey = SyncScope.ProducerAccount(producer.producerAccountId.id).key,
            op = op,
            payload = if (op == ChangeOp.UPSERT) ProducerPayload(producer) else null,
            producedAt = System.currentTimeMillis(),
        )
}

package produceraccount

import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.ProducerAccount

/**
 * Builds the [Change] records for [ProducerAccount] mutations:
 *  - [buildUpsertChanges]: fan-out on every org scope the producer is (or will be) visible in,
 *    plus the `instance-owner` scope.
 *  - [buildDeleteChanges]: DELETE on the removed org scope, UPSERT on the remaining org scopes
 *    (the producer is still linked to those), and a DELETE/UPSERT on `instance-owner` depending
 *    on whether any org link remains.
 *  - [buildStatusChangeChanges]: UPSERT on every currently-linked org scope plus `instance-owner`
 *    (used for suspend/reactivate, delete, and profile updates).
 *
 * Private helpers [producerUpsertChange] and [producerDeleteChange] factor the repeated
 * [Change] constructor pattern so each public method stays declarative.
 */
@Single
class ProducerAccountChangeFactory {
    fun buildUpsertChanges(
        organizationId: String,
        producerAccount: ProducerAccount,
    ): List<Change> {
        val visibleOrganizationIds =
            (producerAccount.organizations.map { it.organizationId.id } + organizationId)
                .distinct()
        return buildList {
            visibleOrganizationIds.forEach { visibleOrganizationId ->
                add(producerUpsertChange(producerAccount, SyncScope.Organization(visibleOrganizationId).key))
            }
            add(producerUpsertChange(producerAccount, SyncScope.InstanceOwner.key))
        }
    }

    fun buildDeleteChanges(
        deletedOrganizationId: String,
        existingProducer: ProducerAccount,
    ): List<Change> =
        buildList {
            add(producerDeleteChange(existingProducer.producerAccountId.id, SyncScope.Organization(deletedOrganizationId).key))
            existingProducer.organizations
                .map { it.organizationId.id }
                .distinct()
                .forEach { organizationId ->
                    add(producerUpsertChange(existingProducer, SyncScope.Organization(organizationId).key))
                }
            // OWNER instance-wide feed: upsert the remaining producer state if
            // any organizations remain, delete tombstone otherwise.
            if (existingProducer.organizations.isEmpty()) {
                add(producerDeleteChange(existingProducer.producerAccountId.id, SyncScope.InstanceOwner.key))
            } else {
                add(producerUpsertChange(existingProducer, SyncScope.InstanceOwner.key))
            }
        }

    fun buildStatusChangeChanges(producer: ProducerAccount): List<Change> =
        buildList {
            producer.organizations
                .map { it.organizationId.id }
                .distinct()
                .forEach { organizationId ->
                    add(producerUpsertChange(producer, SyncScope.Organization(organizationId).key))
                }
            add(producerUpsertChange(producer, SyncScope.InstanceOwner.key))
        }

    private fun producerUpsertChange(
        producer: ProducerAccount,
        scopeKey: String,
    ) = Change(
        cursor = Cursor.next(),
        entityType = EntityType.ProducerAccount,
        entityId = producer.producerAccountId.id,
        scopeKey = scopeKey,
        op = ChangeOp.UPSERT,
        payload = ProducerAccountPayload(producer),
        producedAt = System.currentTimeMillis(),
    )

    private fun producerDeleteChange(
        producerAccountId: String,
        scopeKey: String,
    ) = Change(
        cursor = Cursor.next(),
        entityType = EntityType.ProducerAccount,
        entityId = producerAccountId,
        scopeKey = scopeKey,
        op = ChangeOp.DELETE,
        payload = null,
        producedAt = System.currentTimeMillis(),
    )
}

package core

import id.Id
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ProducerSchedulePayload
import persistence.changes.SyncScope
import persistence.model.Contract
import persistence.model.EntityType
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerSchedule
import persistence.model.ProducerScheduleContract
import persistence.model.ProducerScheduleDelivery

/**
 * Builds the derived [ProducerSchedule] projection and the [Change]s that keep the producers'
 * `producer-account:{id}` feeds up to date.
 *
 * Writers of the source data ([Organization] upserts, [Contract] writes, producer unlinks)
 * call [changes] with the state before/after their write and append the result to the same
 * atomic write, so a producer's schedule changes exactly when its content does — volunteer
 * registrations, coordinator changes and member data never reach it.
 */
object ProducerScheduleProjection {
    /**
     * The schedule of [organization] for [producerAccountId], or `null` when the producer is
     * not (or no longer) linked to it (no link, or link `TERMINATED`).
     */
    fun build(
        organization: Organization,
        contracts: List<Contract>,
        producerAccountId: Id<ProducerAccount>,
    ): ProducerSchedule? {
        val link = organization.producers.firstOrNull { it.producerAccountId == producerAccountId }
        if (link == null || link.status == OrganizationProducerStatus.TERMINATED) return null
        val producerContracts =
            contracts
                .filter { it.organizationId == organization.organizationId && it.producerAccountId == producerAccountId }
                .associateBy { it.contractId }
        val producerProducts =
            organization.products
                .filter { it.producerAccountId == producerAccountId }
                .map { it.productTypeId }
                .toSet()
        val deliveries =
            organization.deliveries
                .mapNotNull { delivery ->
                    val linked =
                        delivery.contracts.mapNotNull { link ->
                            producerContracts[link.contractId]?.let { contract ->
                                ProducerScheduleContract(
                                    contractId = link.contractId,
                                    contractName = contract.name,
                                    basketQuantity = link.basketQuantity,
                                    status = link.status,
                                    contractStatus = contract.status,
                                )
                            }
                        }
                    if (linked.isEmpty()) {
                        null
                    } else {
                        ProducerScheduleDelivery(
                            deliveryId = delivery.deliveryId,
                            scheduledDate = delivery.scheduledDate,
                            status = delivery.status,
                            contracts = linked,
                            basketDescriptions = delivery.basketDescriptions.filter { it.productTypeId in producerProducts },
                        )
                    }
                }.sortedBy { it.scheduledDate }
        return ProducerSchedule(
            organizationId = organization.organizationId,
            producerAccountId = producerAccountId,
            organizationName = organization.name,
            deliveries = deliveries,
        )
    }

    /**
     * The part of an organization a schedule depends on. When it is equal before and after a
     * write, no schedule can change, so callers skip loading contracts (volunteer registrations
     * — the most frequent organization writes — never pay for the projection).
     */
    fun relevantPart(organization: Organization?): Any? =
        organization?.let { org ->
            listOf(
                org.name,
                org.producers,
                org.products.map { it.producerAccountId to it.productTypeId },
                org.deliveries.map { delivery ->
                    listOf(
                        delivery.deliveryId,
                        delivery.scheduledDate,
                        delivery.status,
                        delivery.contracts.map { Triple(it.contractId, it.basketQuantity, it.status) },
                        delivery.basketDescriptions,
                    )
                },
            )
        }

    /**
     * `UPSERT`/`DELETE` changes for every producer whose schedule of the organization differs
     * between the before and after states (null organization = absent).
     */
    fun changes(
        before: Organization?,
        contractsBefore: List<Contract>,
        after: Organization?,
        contractsAfter: List<Contract>,
    ): List<Change> {
        val organizationId = (after ?: before)?.organizationId ?: return emptyList()
        val producers =
            listOfNotNull(before, after).flatMap { org -> org.producers.map { it.producerAccountId } } +
                (contractsBefore + contractsAfter).map { it.producerAccountId }
        return producers.distinct().mapNotNull { producerAccountId ->
            val old = before?.let { build(it, contractsBefore, producerAccountId) }
            val new = after?.let { build(it, contractsAfter, producerAccountId) }
            when {
                old == new -> null
                new == null -> change(producerAccountId, organizationId, null)
                else -> change(producerAccountId, organizationId, new)
            }
        }
    }

    private fun change(
        producerAccountId: Id<ProducerAccount>,
        organizationId: Id<Organization>,
        schedule: ProducerSchedule?,
    ) = Change(
        cursor = Cursor.next(),
        entityType = EntityType.ProducerSchedule,
        entityId = organizationId.id,
        scopeKey = SyncScope.ProducerAccount(producerAccountId.id).key,
        op = if (schedule == null) ChangeOp.DELETE else ChangeOp.UPSERT,
        payload = schedule?.let { ProducerSchedulePayload(it) },
        producedAt = System.currentTimeMillis(),
    )
}

package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import core.BasketComposition
import core.EntityTypeService
import core.ProducerScheduleProjection
import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerSchedulePayload
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketDeliveryDescription
import persistence.model.Delivery
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.Product
import persistence.model.ProductType

/**
 * [persistence.model.ProducerSchedule] feed: the deliveries of each linked AMAP that concern a
 * producer, on its private `producer-account:{id}` scope.
 *
 * The projection is derived, never stored: this service serves the bootstrap snapshot (built
 * from the organizations and contracts), while incremental updates are fanned out by the
 * writers of the source data (`OrganizationService`, `ContractService`) through
 * [ProducerScheduleProjection].
 *
 * The only client write is the producer's basket composition: an upsert of its schedule whose
 * [persistence.model.ProducerScheduleDelivery.basketDescriptions] differ is written back into the
 * organization (see [applyUpsert]); everything else in the payload is ignored. Deleting is
 * forbidden.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProducerScheduleService(
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val productTypeDAO: ProductTypeSyncDAO,
) : EntityTypeService<ProducerSchedulePayload>(EntityType.ProducerSchedule) {
    /**
     * A producer edits the composition of **its own** products on the deliveries carrying one
     * of its contracts. The new compositions replace the stored ones of its products (those of
     * other producers are never touched; a description missing from the producer's copy is
     * kept), under the same rules as the coordinator editor ([BasketComposition]): newest items
     * win, new components need a name. The components' icons join the organization catalog,
     * and the organization plus the producers' schedules are written in one transaction.
     */
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProducerSchedulePayload,
    ): MutationOutcome {
        val schedule = payload.producerSchedule
        val producerAccountId = auth.producerAccountId
        if (Role.PRODUCER !in auth.roles || producerAccountId == null || schedule.producerAccountId.id != producerAccountId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "a producer may only edit its own schedule")
        }
        val organization =
            organizationSyncDAO.getById(schedule.organizationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "organization not found: ${schedule.organizationId.id}")
        val contracts = contractSyncDAO.getByOrganizationId(organization.organizationId)
        val before =
            ProducerScheduleProjection.build(organization, contracts, schedule.producerAccountId)
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "producer not linked to this organization")
        val ownProducts =
            organization.products
                .filter {
                    it.producerAccountId == schedule.producerAccountId
                }.associateBy { it.productTypeId }
        val scheduled = before.deliveries.associateBy { it.deliveryId }

        var updated = organization
        for (incoming in schedule.deliveries) {
            val current = scheduled[incoming.deliveryId]
            if (current == null) {
                return rejected(mutation, MutationErrorCode.FORBIDDEN, "delivery ${incoming.deliveryId.id} carries none of your contracts")
            }
            if (incoming.basketDescriptions == current.basketDescriptions) continue
            compositionError(incoming.basketDescriptions, current.basketDescriptions, ownProducts, current.status)?.let {
                return rejected(mutation, it.first, it.second)
            }
            updated = updated.withProducerComposition(incoming.deliveryId, incoming.basketDescriptions, ownProducts.keys)
        }
        val merged = BasketComposition.keepNewestItems(organization, updated)
        if (merged == organization) return applied(mutation, organization.organizationId.id)

        val final =
            merged.copy(
                itemTypes =
                    BasketComposition.mergedItemTypes(
                        merged.itemTypes,
                        merged.deliveries.flatMap { it.basketDescriptions },
                        productTypeDAO.getByProducerAccountId(schedule.producerAccountId),
                    ),
            )
        organizationSyncDAO.put(
            final,
            organizationChange(final),
            ProducerScheduleProjection.changes(organization, contracts, final, contracts),
        )
        return applied(mutation, final.organizationId.id)
    }

    /** Why the producer may not write [incoming] over [current] — (code, message) — or null. */
    private fun compositionError(
        incoming: List<BasketDeliveryDescription>,
        current: List<BasketDeliveryDescription>,
        ownProducts: Map<Id<ProductType>, Product>,
        status: DeliveryStatus,
    ): Pair<MutationErrorCode, String>? {
        incoming.firstOrNull { it.productTypeId !in ownProducts }?.let {
            return MutationErrorCode.FORBIDDEN to "product ${it.productTypeId.id} is not yours"
        }
        if (status == DeliveryStatus.COMPLETED || status == DeliveryStatus.CANCELLED) {
            return MutationErrorCode.INVALID_PAYLOAD to "the delivery is ${status.name.lowercase()}"
        }
        incoming
            .firstOrNull { description ->
                val sizes = ownProducts[description.productTypeId]?.supportedBasketSizes.orEmpty()
                sizes.isNotEmpty() && sizes.none { it.name == description.basketSizeName }
            }?.let { return MutationErrorCode.INVALID_PAYLOAD to "unknown basket size ${it.basketSizeName}" }
        BasketComposition.itemsError(current, incoming, "delivery")?.let { return MutationErrorCode.INVALID_PAYLOAD to it }
        return null
    }

    /**
     * This organization with the producer's [descriptions] on [deliveryId]: they replace the
     * stored descriptions with the same product and basket size; the other descriptions (other
     * producers', or of its products that its copy lacks) stay as stored.
     */
    private fun Organization.withProducerComposition(
        deliveryId: Id<Delivery>,
        descriptions: List<BasketDeliveryDescription>,
        ownProducts: Set<Id<ProductType>>,
    ): Organization {
        val incoming = descriptions.filter { it.productTypeId in ownProducts }.associateBy { it.productTypeId to it.basketSizeName }
        return copy(
            deliveries =
                deliveries.map { delivery ->
                    if (delivery.deliveryId != deliveryId) {
                        delivery
                    } else {
                        val stored = delivery.basketDescriptions.map { incoming[it.productTypeId to it.basketSizeName] ?: it }
                        val storedKeys = delivery.basketDescriptions.map { it.productTypeId to it.basketSizeName }.toSet()
                        delivery.copy(basketDescriptions = stored + incoming.filterKeys { it !in storedKeys }.values)
                    }
                },
        )
    }

    private fun organizationChange(organization: Organization): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Organization,
            entityId = organization.organizationId.id,
            scopeKey = SyncScope.Organization(organization.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = OrganizationPayload(organization),
            producedAt = System.currentTimeMillis(),
        )

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "producer schedules are read-only")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ProducerSchedulePayload> = emptyList()

    /**
     * Only the producer's own feed carries schedules. Organizations are found through their
     * producer links (full scan, acceptable at current volume — same as the producer search),
     * which also covers links written before the producer account mirrored them.
     */
    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<ProducerSchedulePayload> {
        if (scope !is SyncScope.ProducerAccount) return emptyList()
        val producerAccountId = scope.producerAccountId.toId<ProducerAccount>()
        return organizationSyncDAO
            .listAll()
            .filter { organization -> organization.producers.any { it.producerAccountId == producerAccountId } }
            .mapNotNull { organization ->
                val contracts = contractSyncDAO.getByOrganizationId(organization.organizationId)
                ProducerScheduleProjection.build(organization, contracts, producerAccountId)
            }.map { ProducerSchedulePayload(it) }
    }
}

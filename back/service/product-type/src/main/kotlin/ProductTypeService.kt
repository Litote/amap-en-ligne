package producttype

import authentication.AuthenticatedInfo
import core.EntityTypeService
import id.Id
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.dao.ProductTypeSyncDAO
import persistence.model.EntityType
import persistence.model.ProducerAccount
import persistence.model.ProductType

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ProductTypeService(
    val productTypeDAO: ProductTypeSyncDAO,
) : EntityTypeService<ProductTypePayload>(EntityType.ProductType) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ProductTypePayload,
    ): MutationOutcome = applyProductTypeUpsert(auth, mutation, payload.productType)

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = applyProductTypeDelete(auth, mutation, op.entityId)

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ProductTypePayload> =
        productTypeDAO
            .getByProducerAccountId(auth.producerAccountId?.toId() ?: error("no producer account Id"))
            .map { ProductTypePayload(it) }

    private suspend fun applyProductTypeUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        productType: ProductType,
    ): MutationOutcome {
        val tenantId =
            auth.producerAccountId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing producer account id")
        if (productType.producerAccountId.id != tenantId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "producer_account_id mismatch")
        }
        val realId: Id<ProductType> =
            if (productType.productTypeId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
                generateId()
            } else {
                productType.productTypeId
            }
        val entity = productType.copy(productTypeId = realId)
        productTypeDAO.put(entity, buildUpsertChange(tenantId, entity))
        return applied(mutation, realId.id)
    }

    private suspend fun applyProductTypeDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        entityId: String,
    ): MutationOutcome {
        val tenantId =
            auth.producerAccountId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing producer account id")
        if (entityId.startsWith(ClientMutation.TMP_ID_PREFIX)) {
            return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, "cannot delete a temporary id")
        }
        val productTypeId: Id<ProductType> = entityId.toId()
        val producerAccountId: Id<ProducerAccount> = tenantId.toId()
        productTypeDAO.delete(
            productTypeId,
            producerAccountId,
            buildDeleteChange(tenantId, productTypeId),
        )
        return applied(mutation, entityId)
    }

    private fun buildUpsertChange(
        producerAccountId: String,
        product: ProductType,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProductType,
            entityId = product.productTypeId.id,
            scopeKey = SyncScope.ProducerAccount(producerAccountId).key,
            op = ChangeOp.UPSERT,
            payload = ProductTypePayload(product),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        producerAccountId: String,
        productTypeId: Id<ProductType>,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProductType,
            entityId = productTypeId.id,
            scopeKey = SyncScope.ProducerAccount(producerAccountId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )
}

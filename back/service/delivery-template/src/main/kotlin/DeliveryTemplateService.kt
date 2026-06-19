package deliverytemplate

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
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.model.DeliveryTemplate
import persistence.model.EntityType

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class DeliveryTemplateService(
    val deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO,
) : EntityTypeService<DeliveryTemplatePayload>(EntityType.DeliveryTemplate) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: DeliveryTemplatePayload,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        requireAnyRole(auth, ALLOWED_ROLES, mutation, "only OWNER, ADMIN, or COORDINATOR may manage delivery templates")
            ?.let { return it }
        if (payload.deliveryTemplate.organizationId.id != organizationId) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "organization_id mismatch")
        }
        deliveryTemplateSyncDAO.put(
            payload.deliveryTemplate,
            buildUpsertChange(organizationId, payload.deliveryTemplate),
        )
        return applied(mutation, payload.deliveryTemplate.deliveryTemplateId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val organizationId =
            auth.organizationId
                ?: return rejected(mutation, MutationErrorCode.FORBIDDEN, "missing organization id")
        requireAnyRole(auth, ALLOWED_ROLES, mutation, "only OWNER, ADMIN, or COORDINATOR may manage delivery templates")
            ?.let { return it }
        deliveryTemplateSyncDAO.delete(
            op.entityId.toId(),
            organizationId.toId(),
            buildDeleteChange(organizationId, op.entityId),
        )
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<DeliveryTemplatePayload> {
        val organizationId = auth.organizationId ?: return emptyList()
        return deliveryTemplateSyncDAO
            .getByOrganizationId(organizationId.toId())
            .map { DeliveryTemplatePayload(it) }
    }

    private companion object {
        private val ALLOWED_ROLES = setOf(Role.OWNER, Role.ADMIN, Role.COORDINATOR)
    }

    private fun buildUpsertChange(
        organizationId: String,
        deliveryTemplate: DeliveryTemplate,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeliveryTemplate,
            entityId = deliveryTemplate.deliveryTemplateId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = DeliveryTemplatePayload(deliveryTemplate),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        organizationId: String,
        entityId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeliveryTemplate,
            entityId = entityId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )
}

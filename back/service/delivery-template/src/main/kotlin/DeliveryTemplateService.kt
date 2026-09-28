package deliverytemplate

import authentication.AuthenticatedInfo
import authentication.Role
import core.EntityTypeService
import id.generateId
import id.toId
import kotlinx.datetime.toLocalDateTime
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
import persistence.dao.OrganizationSyncDAO
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import kotlin.time.Clock

@Single(createdAtStart = true, binds = [EntityTypeService::class])
class DeliveryTemplateService(
    val deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
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
        payload.deliveryTemplate.validationError()?.let {
            return rejected(mutation, MutationErrorCode.INVALID_PAYLOAD, it)
        }
        val template = withRealId(organizationId, payload.deliveryTemplate)
        deliveryTemplateSyncDAO.put(template, buildUpsertChange(organizationId, template))
        return applied(mutation, template.deliveryTemplateId.id)
    }

    /**
     * Allocates a real id for a `tmp_*` creation. A template already stored under a
     * `tmp_*` id (created before ids were allocated server-side) keeps it, so editing
     * it does not duplicate it.
     */
    private suspend fun withRealId(
        organizationId: String,
        template: DeliveryTemplate,
    ): DeliveryTemplate {
        val id = template.deliveryTemplateId
        if (!id.id.startsWith(ClientMutation.TMP_ID_PREFIX)) return template
        val alreadyStored =
            deliveryTemplateSyncDAO
                .getByOrganizationId(organizationId.toId())
                .any { it.deliveryTemplateId == id }
        return if (alreadyStored) template else template.copy(deliveryTemplateId = generateId())
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
        // Mirrors the admin list screen: a template still used by a future delivery
        // cannot be deleted (its slot times would silently fall back to the defaults).
        if (usedByFutureDelivery(organizationId, op.entityId)) {
            return rejected(mutation, MutationErrorCode.CONFLICT, "delivery template is used by future deliveries")
        }
        deliveryTemplateSyncDAO.delete(
            op.entityId.toId(),
            organizationId.toId(),
            buildDeleteChange(organizationId, op.entityId),
        )
        return applied(mutation, op.entityId)
    }

    private suspend fun usedByFutureDelivery(
        organizationId: String,
        deliveryTemplateId: String,
    ): Boolean {
        val organization = organizationSyncDAO.getById(organizationId.toId()) ?: return false
        val now = Clock.System.now().toLocalDateTime(organization.timezone)
        return organization.deliveries.any { it.deliveryTemplateId?.id == deliveryTemplateId && it.scheduledDate > now }
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

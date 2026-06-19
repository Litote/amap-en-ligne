@file:OptIn(ExperimentalTime::class)

package notification

import authentication.AuthenticatedInfo
import core.AuthorizedScopeResolver
import core.EntityTypeService
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.DeviceTokenPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.DeviceTokenSyncDAO
import persistence.model.DeviceToken
import persistence.model.EntityType
import kotlin.time.ExperimentalTime

/**
 * EntityTypeService for [DeviceToken] (ADR-005).
 *
 * Device tokens are client-authored on the caller's **own** private feed
 * (`member:{sub}`, `owner:{sub}`, or `producer-account:{id}`): the client upserts one when
 * it obtains/refreshes a push registration token and deletes it on logout. Ownership is
 * checked against [AuthorizedScopeResolver], so a single recipient-agnostic service serves
 * every recipient kind.
 *
 * The server deduplicates by `(recipientScope, token)`: re-registering an already known
 * token refreshes the existing row (and reports its canonical id) instead of creating a
 * duplicate, which also keeps the persistence-level unique constraint safe.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class DeviceTokenService(
    private val deviceTokenSyncDAO: DeviceTokenSyncDAO,
    private val authorizedScopeResolver: AuthorizedScopeResolver,
) : EntityTypeService<DeviceTokenPayload>(EntityType.DeviceToken) {
    /** Private recipient-feed scope keys the caller owns (member / owner / producer-account). */
    private suspend fun ownedFeedScopes(auth: AuthenticatedInfo): Set<String> =
        authorizedScopeResolver
            .resolve(auth)
            .first
            .filter { it is SyncScope.Member || it is SyncScope.Owner || it is SyncScope.ProducerAccount }
            .map { it.key }
            .toSet()

    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: DeviceTokenPayload,
    ): MutationOutcome {
        val incoming = payload.deviceToken
        if (incoming.recipientScope !in ownedFeedScopes(auth)) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "recipient_scope is not one of the caller's feeds")
        }
        // Deduplicate by token: a re-registered token reuses its existing row (and id).
        val existingByToken =
            deviceTokenSyncDAO
                .getByRecipientScope(incoming.recipientScope)
                .firstOrNull { it.token == incoming.token }
        val targetId =
            when {
                existingByToken != null -> existingByToken.deviceTokenId
                incoming.deviceTokenId.id.startsWith(ClientMutation.TMP_ID_PREFIX) -> generateId()
                else -> incoming.deviceTokenId
            }
        val toPersist =
            incoming.copy(
                deviceTokenId = targetId,
                createdAt = existingByToken?.createdAt ?: incoming.createdAt,
            )
        deviceTokenSyncDAO.put(toPersist, upsertChange(toPersist))
        return applied(mutation, targetId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val deviceTokenId = op.entityId.toId<DeviceToken>()
        // The delete op carries only the id; locate it across the caller's own feeds.
        val ownerScope =
            ownedFeedScopes(auth).firstOrNull { scopeKey ->
                deviceTokenSyncDAO.findById(scopeKey, deviceTokenId) != null
            } ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "device token not found")
        deviceTokenSyncDAO.delete(ownerScope, deviceTokenId, deleteChange(ownerScope, op.entityId))
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<DeviceTokenPayload> =
        ownedFeedScopes(auth).flatMap { scopeKey ->
            deviceTokenSyncDAO.getByRecipientScope(scopeKey).map(::DeviceTokenPayload)
        }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<DeviceTokenPayload> =
        when (scope) {
            is SyncScope.Member,
            is SyncScope.Owner,
            is SyncScope.ProducerAccount,
            -> {
                if (scope.key in ownedFeedScopes(auth)) {
                    deviceTokenSyncDAO.getByRecipientScope(scope.key).map(::DeviceTokenPayload)
                } else {
                    emptyList()
                }
            }

            is SyncScope.Organization,
            SyncScope.InstanceOwner,
            -> {
                emptyList()
            }
        }

    private fun upsertChange(deviceToken: DeviceToken): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeviceToken,
            entityId = deviceToken.deviceTokenId.id,
            scopeKey = deviceToken.recipientScope,
            op = ChangeOp.UPSERT,
            payload = DeviceTokenPayload(deviceToken),
            producedAt = System.currentTimeMillis(),
        )

    private fun deleteChange(
        recipientScope: String,
        deviceTokenId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeviceToken,
            entityId = deviceTokenId,
            scopeKey = recipientScope,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )
}

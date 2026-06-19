@file:OptIn(ExperimentalTime::class)

package notification

import authentication.AuthenticatedInfo
import core.AuthorizedScopeResolver
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
import persistence.changes.NotificationPayload
import persistence.changes.SyncScope
import persistence.dao.NotificationSyncDAO
import persistence.model.EntityType
import persistence.model.Notification
import kotlin.time.ExperimentalTime

/**
 * EntityTypeService for [Notification] (ADR-005).
 *
 * Notifications are server-authoritative: clients may only mark them read
 * ([Notification.readAt]) or archive them ([applyDelete]). Creation and content edits by
 * the client are rejected — those happen server-side via [NotificationPublisher].
 *
 * Recipient-scope agnostic: a notification lives on one of the caller's authorized
 * private feeds (`member:{sub}`, `owner:{sub}`, or `producer-account:{id}`). Ownership is
 * checked against [AuthorizedScopeResolver] so the same service serves every recipient kind.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class NotificationService(
    private val notificationSyncDAO: NotificationSyncDAO,
    private val authorizedScopeResolver: AuthorizedScopeResolver,
) : EntityTypeService<NotificationPayload>(EntityType.Notification) {
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
        payload: NotificationPayload,
    ): MutationOutcome {
        val incoming = payload.notification
        if (incoming.recipientScope !in ownedFeedScopes(auth)) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "recipient_scope is not one of the caller's feeds")
        }
        if (incoming.notificationId.id.startsWith(ClientMutation.TMP_ID_PREFIX)) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "clients cannot create notifications")
        }
        val existing =
            notificationSyncDAO.findById(incoming.recipientScope, incoming.notificationId)
                ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "notification not found")
        // The only client-permitted change is the read marker. Everything else is immutable.
        if (existing.copy(readAt = incoming.readAt) != incoming) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "only read_at may be changed by the client")
        }
        notificationSyncDAO.put(incoming, upsertChange(incoming))
        return applied(mutation, incoming.notificationId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome {
        val notificationId = op.entityId.toId<Notification>()
        // The delete op carries only the id; locate it across the caller's own feeds.
        val ownerScope =
            ownedFeedScopes(auth).firstOrNull { scopeKey ->
                notificationSyncDAO.findById(scopeKey, notificationId) != null
            } ?: return rejected(mutation, MutationErrorCode.NOT_FOUND, "notification not found")
        notificationSyncDAO.delete(ownerScope, notificationId, deleteChange(ownerScope, op.entityId))
        return applied(mutation, op.entityId)
    }

    override suspend fun snapshot(auth: AuthenticatedInfo): List<NotificationPayload> =
        ownedFeedScopes(auth).flatMap { scopeKey ->
            notificationSyncDAO.getByRecipientScope(scopeKey).map(::NotificationPayload)
        }

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<NotificationPayload> =
        when (scope) {
            is SyncScope.Member,
            is SyncScope.Owner,
            is SyncScope.ProducerAccount,
            -> {
                if (scope.key in ownedFeedScopes(auth)) {
                    notificationSyncDAO.getByRecipientScope(scope.key).map(::NotificationPayload)
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

    private fun upsertChange(notification: Notification): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Notification,
            entityId = notification.notificationId.id,
            scopeKey = notification.recipientScope,
            op = ChangeOp.UPSERT,
            payload = NotificationPayload(notification),
            producedAt = System.currentTimeMillis(),
        )

    private fun deleteChange(
        recipientScope: String,
        notificationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Notification,
            entityId = notificationId,
            scopeKey = recipientScope,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )
}

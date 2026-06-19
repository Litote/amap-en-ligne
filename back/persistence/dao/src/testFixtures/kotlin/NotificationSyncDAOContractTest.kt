@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.NotificationPayload
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class NotificationSyncDAOContractTest {
    protected abstract val notificationSyncDAO: NotificationSyncDAO
    protected abstract val changeDAO: ChangeDAO

    private fun newMemberId() = UUID.randomUUID().toString()

    private fun newNotificationId() = UUID.randomUUID().toString()

    private fun recipientScope(memberId: String) = SyncScope.Member(memberId).key

    private fun buildNotification(
        notificationId: String = newNotificationId(),
        recipientScope: String,
        readAt: Instant? = null,
    ): Notification =
        Notification(
            notificationId = notificationId.toId(),
            recipientScope = recipientScope,
            type = NotificationType.INFO,
            category = NotificationCategory.GENERIC,
            title = "Title",
            body = "Body",
            deepLink = null,
            relatedEntityId = null,
            createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
            readAt = readAt,
        )

    private fun buildUpsertChange(notification: Notification): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.Notification,
            entityId = notification.notificationId.id,
            scopeKey = notification.recipientScope,
            op = ChangeOp.UPSERT,
            payload = NotificationPayload(notification),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        notificationId: String,
        recipientScope: String,
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

    @Test
    fun `GIVEN a notification WHEN put then getByRecipientScope THEN returns it`() =
        runTest {
            val scope = recipientScope(newMemberId())
            val notification = buildNotification(recipientScope = scope)

            notificationSyncDAO.put(notification, buildUpsertChange(notification))

            val result = notificationSyncDAO.getByRecipientScope(scope)
            assertEquals(1, result.size)
            assertEquals(notification.notificationId, result.first().notificationId)
        }

    @Test
    fun `GIVEN no notifications WHEN getByRecipientScope THEN returns empty list`() =
        runTest {
            val result = notificationSyncDAO.getByRecipientScope(recipientScope(newMemberId()))
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN notifications for two recipients WHEN getByRecipientScope THEN returns only the right ones`() =
        runTest {
            val scopeA = recipientScope(newMemberId())
            val scopeB = recipientScope(newMemberId())
            val notifA = buildNotification(recipientScope = scopeA)
            val notifB = buildNotification(recipientScope = scopeB)

            notificationSyncDAO.put(notifA, buildUpsertChange(notifA))
            notificationSyncDAO.put(notifB, buildUpsertChange(notifB))

            val result = notificationSyncDAO.getByRecipientScope(scopeA)
            assertEquals(1, result.size)
            assertEquals(notifA.notificationId, result.first().notificationId)
        }

    @Test
    fun `GIVEN a notification WHEN findById THEN returns it`() =
        runTest {
            val scope = recipientScope(newMemberId())
            val notification = buildNotification(recipientScope = scope)
            notificationSyncDAO.put(notification, buildUpsertChange(notification))

            val found = notificationSyncDAO.findById(scope, notification.notificationId)
            assertNotNull(found)
            assertNull(found.readAt)
        }

    @Test
    fun `GIVEN a notification WHEN put with readAt THEN read state is persisted`() =
        runTest {
            val scope = recipientScope(newMemberId())
            val notification = buildNotification(recipientScope = scope)
            notificationSyncDAO.put(notification, buildUpsertChange(notification))

            val readInstant = Instant.fromEpochMilliseconds(1_700_000_500_000)
            val updated = notification.copy(readAt = readInstant)
            notificationSyncDAO.put(updated, buildUpsertChange(updated))

            val found = notificationSyncDAO.findById(scope, notification.notificationId)
            assertEquals(readInstant, found?.readAt)
        }

    @Test
    fun `GIVEN an existing notification WHEN delete THEN getByRecipientScope returns empty`() =
        runTest {
            val scope = recipientScope(newMemberId())
            val notification = buildNotification(recipientScope = scope)
            notificationSyncDAO.put(notification, buildUpsertChange(notification))

            notificationSyncDAO.delete(scope, notification.notificationId, buildDeleteChange(notification.notificationId.id, scope))

            assertTrue(notificationSyncDAO.getByRecipientScope(scope).isEmpty())
        }

    @Test
    fun `GIVEN a notification WHEN put THEN change is recorded on the recipient scope`() =
        runTest {
            val scope = recipientScope(newMemberId())
            val notification = buildNotification(recipientScope = scope)
            val change = buildUpsertChange(notification)

            notificationSyncDAO.put(notification, change)

            val changes = changeDAO.since(scope, null)
            assertNotNull(changes.find { it.entityId == notification.notificationId.id })
        }
}

@file:OptIn(ExperimentalTime::class)

package deploy.jvm

import id.toId
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class FcmPushPayloadTest {
    private fun notification(
        deepLink: String? = null,
        relatedEntityId: String? = null,
    ) = Notification(
        notificationId = "n-1".toId(),
        recipientScope = "member:sub-1",
        type = NotificationType.INFO,
        category = NotificationCategory.BASKET_EXCHANGE_ACCEPTED,
        title = "T",
        body = "B",
        deepLink = deepLink,
        relatedEntityId = relatedEntityId,
        createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
        readAt = null,
    )

    @Test
    fun `GIVEN a notification with deep link and related entity WHEN building the data payload THEN all keys present`() {
        val data = pushDataPayload(notification(deepLink = "app://x", relatedEntityId = "ex-1"))
        assertEquals("n-1", data["notification_id"])
        assertEquals("BASKET_EXCHANGE_ACCEPTED", data["category"])
        assertEquals("app://x", data["deep_link"])
        assertEquals("ex-1", data["related_entity_id"])
    }

    @Test
    fun `GIVEN null deep link and related entity WHEN building the data payload THEN optional keys omitted`() {
        val data = pushDataPayload(notification())
        assertEquals("n-1", data["notification_id"])
        assertEquals("BASKET_EXCHANGE_ACCEPTED", data["category"])
        assertFalse(data.containsKey("deep_link"))
        assertFalse(data.containsKey("related_entity_id"))
    }
}

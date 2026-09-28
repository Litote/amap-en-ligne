@file:OptIn(ExperimentalTime::class)

package deploy.lambda

import id.toId
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import persistence.model.DevicePlatform
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class SnsPushMessageTest {
    private fun notification(
        deepLink: String? = "app://x",
        relatedEntityId: String? = "ex-1",
    ) = Notification(
        notificationId = "n-1".toId(),
        recipientScope = "member:sub-1",
        type = NotificationType.INFO,
        category = NotificationCategory.BASKET_EXCHANGE_ACCEPTED,
        title = "Titre",
        body = "Corps",
        deepLink = deepLink,
        relatedEntityId = relatedEntityId,
        createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
        readAt = null,
    )

    @Test
    fun `GIVEN ANDROID WHEN building message THEN GCM key holds nested notification + data JSON`() {
        val payload = snsPushMessage(DevicePlatform.ANDROID, notification())!!
        val outer = Json.parseToJsonElement(payload).jsonObject
        assertEquals("Corps", outer["default"]!!.jsonPrimitive.content)

        // The GCM value is itself a JSON string.
        val gcm = Json.parseToJsonElement(outer["GCM"]!!.jsonPrimitive.content).jsonObject
        assertEquals("Titre", gcm["notification"]!!.jsonObject["title"]!!.jsonPrimitive.content)
        assertEquals("Corps", gcm["notification"]!!.jsonObject["body"]!!.jsonPrimitive.content)
        val data = gcm["data"]!!.jsonObject
        assertEquals("n-1", data["notification_id"]!!.jsonPrimitive.content)
        assertEquals("BASKET_EXCHANGE_ACCEPTED", data["category"]!!.jsonPrimitive.content)
        assertEquals("app://x", data["deep_link"]!!.jsonPrimitive.content)
        assertEquals("ex-1", data["related_entity_id"]!!.jsonPrimitive.content)
    }

    @Test
    fun `GIVEN IOS WHEN building message THEN APNS key holds aps alert`() {
        val payload = snsPushMessage(DevicePlatform.IOS, notification(deepLink = null, relatedEntityId = null))!!
        val outer = Json.parseToJsonElement(payload).jsonObject
        val apns = Json.parseToJsonElement(outer["APNS"]!!.jsonPrimitive.content).jsonObject
        val alert = apns["aps"]!!.jsonObject["alert"]!!.jsonObject
        assertEquals("Titre", alert["title"]!!.jsonPrimitive.content)
        assertEquals("Corps", alert["body"]!!.jsonPrimitive.content)
        // Optional data keys omitted when null.
        assertNull(apns["deep_link"])
    }

    @Test
    fun `GIVEN WEB WHEN building message THEN null (unsupported)`() {
        assertNull(snsPushMessage(DevicePlatform.WEB, notification()))
    }
}

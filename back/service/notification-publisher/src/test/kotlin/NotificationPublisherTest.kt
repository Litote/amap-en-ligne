@file:OptIn(ExperimentalTime::class)

package notificationpublisher

import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.dao.DeviceTokenSyncDAO
import persistence.dao.NotificationSyncDAO
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class NotificationPublisherTest {
    private val notificationSyncDAO = mockk<NotificationSyncDAO>(relaxed = true)
    private val deviceTokenSyncDAO = mockk<DeviceTokenSyncDAO>(relaxed = true)

    private val recipientScope = "member:sub-1"

    private fun device(token: String) =
        DeviceToken(
            deviceTokenId = "dev-$token".toId(),
            recipientScope = recipientScope,
            platform = DevicePlatform.ANDROID,
            token = token,
            createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
            lastSeenAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
        )

    /** Capturing sender to assert what the dispatcher receives. */
    private class CapturingSender(
        override val channel: NotificationChannel,
    ) : NotificationChannelSender {
        var lastContact: NotificationContact? = null

        override suspend fun send(
            notification: Notification,
            contact: NotificationContact,
        ) {
            lastContact = contact
        }
    }

    private fun publisher(senders: List<NotificationChannelSender>) =
        NotificationPublisher(notificationSyncDAO, deviceTokenSyncDAO, NotificationDispatcher(senders))

    @Test
    fun `GIVEN PUSH channel WHEN publish THEN devices are resolved and passed to the push sender`() =
        runTest {
            coEvery { deviceTokenSyncDAO.getByRecipientScope(recipientScope) } returns listOf(device("t1"), device("t2"))
            val pushSender = CapturingSender(NotificationChannel.PUSH)

            publisher(listOf(pushSender)).publish(
                recipientScope = recipientScope,
                type = NotificationType.INFO,
                category = NotificationCategory.GENERIC,
                content = NotificationContent(title = "T", body = "B"),
                channels = setOf(NotificationChannel.PUSH),
            )

            val devices = pushSender.lastContact?.devices.orEmpty()
            assertEquals(listOf("t1", "t2"), devices.map { it.token })
        }

    @Test
    fun `GIVEN only EMAIL channel WHEN publish THEN device feed is not resolved`() =
        runTest {
            val emailSender = CapturingSender(NotificationChannel.EMAIL)

            publisher(listOf(emailSender)).publish(
                recipientScope = recipientScope,
                type = NotificationType.INFO,
                category = NotificationCategory.GENERIC,
                content = NotificationContent(title = "T", body = "B"),
                contact = NotificationContact(email = "m@example.com"),
                channels = setOf(NotificationChannel.EMAIL),
            )

            assertTrue(
                emailSender.lastContact
                    ?.devices
                    .orEmpty()
                    .isEmpty(),
            )
            io.mockk.coVerify(exactly = 0) { deviceTokenSyncDAO.getByRecipientScope(any()) }
        }
}

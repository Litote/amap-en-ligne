package deploy.jvm

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.AndroidConfig
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingException
import com.google.firebase.messaging.Message
import com.google.firebase.messaging.MessagingErrorCode
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import notificationpublisher.NotificationChannelSender
import notificationpublisher.NotificationContact
import org.koin.core.annotation.Single
import persistence.model.Notification
import persistence.model.NotificationChannel
import properties.Properties
import java.io.FileInputStream
import com.google.firebase.messaging.Notification as FcmNotification

/**
 * Real push transport for the JVM deployment (ADR-005): Firebase Cloud Messaging HTTP v1,
 * called directly via the Firebase Admin SDK — **no AWS dependency** (the Lambda deployment
 * uses SNS Mobile Push instead).
 *
 * Credentials are resolved from `FCM_CREDENTIALS_FILE` (a service-account JSON path) or, when
 * absent, the standard Application Default Credentials (`GOOGLE_APPLICATION_CREDENTIALS`). When
 * no credentials are configured (e.g. local dev), the sender disables itself and `send` no-ops
 * — transport is best-effort, the in-app feed remains the durable record.
 *
 * The device tokens are resolved upstream by `NotificationPublisher` and arrive in
 * [NotificationContact.devices], so this sender stays a pure transport. A device token is the
 * app installation's Firebase Installation ID, sent as the FCM `fid` target ([fcmPushMessage]).
 */
@Single(createdAtStart = true, binds = [NotificationChannelSender::class])
internal class FcmPushNotificationChannelSender(
    properties: Properties,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : NotificationChannelSender {
    override val channel: NotificationChannel = NotificationChannel.PUSH

    private val messaging: FirebaseMessaging? = initMessaging(properties)

    override suspend fun send(
        notification: Notification,
        contact: NotificationContact,
    ) {
        val messaging =
            messaging ?: run {
                logger.debug { "FCM not configured; skipping push for ${notification.notificationId.id}" }
                return
            }
        if (contact.devices.isEmpty()) return
        withContext(dispatcher) {
            contact.devices.forEach { device ->
                try {
                    messaging.send(fcmPushMessage(device.token, notification))
                } catch (e: FirebaseMessagingException) {
                    if (e.messagingErrorCode == MessagingErrorCode.UNREGISTERED) {
                        logger.info { "stale FCM installation for device ${device.deviceTokenId.id}; will be pruned on next refresh" }
                    } else {
                        logger.warn(e) { "FCM push failed for device ${device.deviceTokenId.id}" }
                    }
                }
            }
        }
    }

    private fun initMessaging(properties: Properties): FirebaseMessaging? =
        try {
            val credentialsPath = properties.propertyOrNull("FCM_CREDENTIALS_FILE")
            val credentials =
                if (credentialsPath != null) {
                    FileInputStream(credentialsPath).use { GoogleCredentials.fromStream(it) }
                } else {
                    GoogleCredentials.getApplicationDefault()
                }
            val options = FirebaseOptions.builder().setCredentials(credentials).build()
            val app =
                FirebaseApp.getApps().firstOrNull { it.name == FirebaseApp.DEFAULT_APP_NAME }
                    ?: FirebaseApp.initializeApp(options)
            logger.info { "FCM push transport initialised" }
            FirebaseMessaging.getInstance(app)
        } catch (e: Exception) {
            logger.warn {
                "FCM push disabled: could not initialise Firebase " +
                    "(set FCM_CREDENTIALS_FILE or GOOGLE_APPLICATION_CREDENTIALS to enable)"
            }
            null
        }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

/**
 * The FCM message for one device, targeted at its Firebase Installation ID ([fid]) — the
 * registration `token` target is deprecated. Pure function — unit-tested.
 */
internal fun fcmPushMessage(
    fid: String,
    notification: Notification,
): Message =
    Message
        .builder()
        .setFid(fid)
        .setNotification(
            FcmNotification
                .builder()
                .setTitle(notification.title)
                .setBody(notification.body)
                .build(),
        ).apply { pushDataPayload(notification).forEach { (key, value) -> putData(key, value) } }
        .setAndroidConfig(
            AndroidConfig
                .builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .build(),
        ).build()

/**
 * Data payload carried alongside the notification so the client can route the tap
 * (deep link / related entity) and group by category. Pure function — unit-tested.
 */
internal fun pushDataPayload(notification: Notification): Map<String, String> =
    buildMap {
        put("notification_id", notification.notificationId.id)
        put("category", notification.category.name)
        notification.deepLink?.let { put("deep_link", it) }
        notification.relatedEntityId?.let { put("related_entity_id", it) }
    }

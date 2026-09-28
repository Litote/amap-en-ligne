package deploy.lambda

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.sns.SnsClient
import aws.sdk.kotlin.services.sns.model.CreatePlatformEndpointRequest
import aws.sdk.kotlin.services.sns.model.EndpointDisabledException
import aws.sdk.kotlin.services.sns.model.InvalidParameterException
import aws.sdk.kotlin.services.sns.model.PublishRequest
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import notificationpublisher.NotificationChannelSender
import notificationpublisher.NotificationContact
import org.koin.core.annotation.Single
import persistence.model.DevicePlatform
import persistence.model.Notification
import persistence.model.NotificationChannel
import properties.Properties

/**
 * Real push transport for the Lambda deployment (ADR-005): **AWS SNS Mobile Push** — native
 * AWS, no third-party SDK. For each device token we look up (or create) a platform endpoint on
 * the FCM (Android) / APNs (iOS) Platform Application, then publish a platform-shaped message.
 *
 * Platform Application ARNs come from env (`SNS_PLATFORM_APP_ARN_ANDROID`,
 * `SNS_PLATFORM_APP_ARN_IOS`); a platform with no configured ARN is skipped, so the sender
 * disables itself cleanly when push is not provisioned. Device tokens are resolved upstream by
 * `NotificationPublisher` and arrive in [NotificationContact.devices].
 */
@Single(createdAtStart = true, binds = [NotificationChannelSender::class])
internal class SnsPushNotificationChannelSender(
    private val properties: Properties,
) : NotificationChannelSender {
    override val channel: NotificationChannel = NotificationChannel.PUSH

    private val androidArn: String? = properties.propertyOrNull("SNS_PLATFORM_APP_ARN_ANDROID")
    private val iosArn: String? = properties.propertyOrNull("SNS_PLATFORM_APP_ARN_IOS")

    private val snsClient: SnsClient by lazy {
        SnsClient {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }
    }

    override suspend fun send(
        notification: Notification,
        contact: NotificationContact,
    ) {
        contact.devices.forEach { device ->
            val platformArn = platformApplicationArn(device.platform)
            if (platformArn == null) {
                logger.debug { "no SNS platform application configured for ${device.platform}; skipping" }
                return@forEach
            }
            val message = snsPushMessage(device.platform, notification) ?: return@forEach
            try {
                val endpointArn = ensureEndpoint(platformArn, device.token)
                snsClient.publish(
                    PublishRequest {
                        this.targetArn = endpointArn
                        this.message = message
                        this.messageStructure = "json"
                    },
                )
            } catch (e: EndpointDisabledException) {
                logger.info { "disabled SNS endpoint for device ${device.deviceTokenId.id}; will be pruned on next refresh" }
            } catch (e: Exception) {
                logger.warn(e) { "SNS push failed for device ${device.deviceTokenId.id}" }
            }
        }
    }

    /** Idempotently resolves the SNS platform endpoint ARN for [token]. */
    private suspend fun ensureEndpoint(
        platformApplicationArn: String,
        token: String,
    ): String =
        try {
            snsClient
                .createPlatformEndpoint(
                    CreatePlatformEndpointRequest {
                        this.platformApplicationArn = platformApplicationArn
                        this.token = token
                    },
                ).endpointArn ?: error("SNS returned no endpoint ARN")
        } catch (e: InvalidParameterException) {
            // SNS rejects re-registration of an existing token but includes the existing ARN.
            existingEndpointArn(e.message)
                ?: throw e
        }

    private fun platformApplicationArn(platform: DevicePlatform): String? =
        when (platform) {
            DevicePlatform.ANDROID -> androidArn
            DevicePlatform.IOS -> iosArn
            DevicePlatform.WEB -> null
        }

    private companion object {
        private val logger = KotlinLogging.logger {}
        private val EXISTING_ARN_REGEX = Regex("""Endpoint (arn:aws:sns:\S+?) already exists""")

        fun existingEndpointArn(message: String?): String? = message?.let { EXISTING_ARN_REGEX.find(it)?.groupValues?.get(1) }
    }
}

/**
 * Builds the `MessageStructure=json` SNS payload for a platform. Returns null for unsupported
 * platforms. Pure function — unit-tested.
 *
 * The platform-specific value (`GCM` / `APNS`) is itself a JSON string, as SNS requires.
 */
internal fun snsPushMessage(
    platform: DevicePlatform,
    notification: Notification,
): String? {
    fun dataFields(builder: kotlinx.serialization.json.JsonObjectBuilder) =
        with(builder) {
            put("notification_id", notification.notificationId.id)
            put("category", notification.category.name)
            notification.deepLink?.let { put("deep_link", it) }
            notification.relatedEntityId?.let { put("related_entity_id", it) }
        }

    val inner: JsonObject =
        when (platform) {
            DevicePlatform.ANDROID -> {
                buildJsonObject {
                    putJsonObject("notification") {
                        put("title", notification.title)
                        put("body", notification.body)
                    }
                    putJsonObject("data") { dataFields(this) }
                }
            }

            DevicePlatform.IOS -> {
                buildJsonObject {
                    putJsonObject("aps") {
                        putJsonObject("alert") {
                            put("title", notification.title)
                            put("body", notification.body)
                        }
                    }
                    dataFields(this)
                }
            }

            DevicePlatform.WEB -> {
                return null
            }
        }

    val key = if (platform == DevicePlatform.ANDROID) "GCM" else "APNS"
    return buildJsonObject {
        put("default", notification.body)
        put(key, inner.toString())
    }.toString()
}

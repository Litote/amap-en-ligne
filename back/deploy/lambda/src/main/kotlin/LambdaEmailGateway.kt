package deploy.lambda

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.sns.SnsClient
import aws.sdk.kotlin.services.sns.model.PublishRequest
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import email.delivery.EmailGateway
import email.delivery.withInstanceBranding
import instanceconfig.InstanceConfig
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.serialization.encodeToString
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import properties.Properties
import serialization.json

/**
 * Shared outbound email gateway for the Lambda deployment. Renders nothing
 * itself: it publishes a fully-built [EmailMessage] onto the email SNS topic,
 * where the dedicated [ActivationEmailLambda] consumes it and sends via SES.
 *
 * This keeps the synchronous request path free of SES latency and IAM scope:
 * the main Lambda only needs `sns:Publish` on the topic, the email-sending
 * Lambda owns the SES permission. The email content (and its tests) live in
 * [EmailTemplates].
 */
@Single(binds = [EmailGateway::class])
internal class LambdaEmailGateway(
    private val properties: Properties,
    instanceConfig: InstanceConfig,
) : EmailGateway {
    private val topicArn: String = properties.property("ACTIVATION_EMAIL_SNS_TOPIC_ARN", "")
    private val webBaseUrl: String = properties.property("INSTANCE_WEB_URL", instanceConfig.apiUrl).trimEnd('/')
    private val instanceUrl: String = instanceConfig.apiUrl.trimEnd('/')
    private val snsClient: SnsClient =
        SnsClient {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }

    /** Builds the public activation URL for a freshly issued activation token. */
    override fun activationUrl(token: String): String = "$webBaseUrl/activate?token=$token"

    /**
     * Publishes a ready-to-send email onto the SNS topic for asynchronous
     * delivery. **Best-effort**: a publish failure is logged and swallowed so it
     * never rolls back the already-committed sync mutation that triggered it.
     */
    override suspend fun deliver(message: EmailMessage) {
        val branded = message.withInstanceBranding(instanceUrl)
        runCatching {
            snsClient.publish(
                PublishRequest {
                    topicArn = this@LambdaEmailGateway.topicArn
                    this.message = json.encodeToString(branded)
                },
            )
        }.onSuccess {
            logger.info { "Published email to SNS topic for ${branded.to}" }
        }.onFailure { error ->
            logger.warn(error) { "Best-effort email to ${branded.to} failed: ${branded.subject}" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

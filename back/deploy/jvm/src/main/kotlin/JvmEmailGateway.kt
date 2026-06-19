package deploy.jvm

import email.delivery.EmailGateway
import email.delivery.withInstanceBranding
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import properties.Properties

/**
 * Outbound [EmailGateway] for the JVM deployment. Renders the activation URL,
 * applies instance branding and delivers the [EmailMessage] over SMTP via the
 * dumb [EmailSender] transport, **best-effort**: a transport failure is logged
 * and swallowed so it never rolls back the already-committed sync mutation that
 * triggered the notification. Mirrors `LambdaEmailGateway` on the Lambda side.
 */
@Single(binds = [EmailGateway::class])
internal class JvmEmailGateway(
    private val emailSender: EmailSender,
    properties: Properties,
) : EmailGateway {
    private val baseUrl: String =
        properties
            .property("INSTANCE_WEB_URL", properties.property("INSTANCE_API_URL", "http://localhost:8080/"))
            .trimEnd('/')
    private val instanceUrl: String = properties.property("INSTANCE_API_URL", "").trimEnd('/')

    override fun activationUrl(token: String): String = "$baseUrl/activate?token=$token"

    override suspend fun deliver(message: EmailMessage) {
        val branded = message.withInstanceBranding(instanceUrl)
        runCatching {
            emailSender.sendNotificationEmail(branded.to, branded.subject, branded.body)
        }.onFailure { error ->
            logger.warn(error) { "Best-effort email to ${branded.to} failed: ${branded.subject}" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

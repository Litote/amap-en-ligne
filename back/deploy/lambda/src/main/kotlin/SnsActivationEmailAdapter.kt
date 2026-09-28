@file:OptIn(ExperimentalTime::class)

package deploy.lambda
import email.ActivationEmailPort
import email.EmailTemplates
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.model.ActivationToken
import persistence.model.EmailMessage
import persistence.model.OrganizationRequest
import kotlin.time.ExperimentalTime

/**
 * Sends the organization-admin activation email by publishing a rendered
 * [EmailMessage] onto the email SNS topic (consumed by [ActivationEmailLambda]).
 */
@Single(createdAtStart = true, binds = [ActivationEmailPort::class])
internal class SnsActivationEmailAdapter(
    private val gateway: LambdaEmailGateway,
) : ActivationEmailPort {
    override suspend fun scheduleActivationEmail(
        token: ActivationToken,
        request: OrganizationRequest,
    ) {
        logger.info { "Scheduling activation email for ${request.adminEmail} (request ${request.requestId.id})" }
        val content =
            EmailTemplates.organizationActivation(
                request = request,
                activationUrl = gateway.activationUrl(token.token),
                expiresAt = token.expiresAt,
            )
        gateway.deliver(EmailMessage(to = request.adminEmail, subject = content.subject, body = content.body))
        logger.info { "Activation email published to SNS for ${request.adminEmail}" }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

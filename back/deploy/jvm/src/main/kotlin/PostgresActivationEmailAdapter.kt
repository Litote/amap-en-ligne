package deploy.jvm

import email.ActivationEmailPort
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.model.ActivationToken
import persistence.model.OrganizationRequest

@Single(createdAtStart = true, binds = [ActivationEmailPort::class])
internal class PostgresActivationEmailAdapter : ActivationEmailPort {
    override suspend fun scheduleActivationEmail(
        token: ActivationToken,
        request: OrganizationRequest,
    ) {
        logger.debug { "Activation token ${token.token} stored; cron will send email to ${token.adminEmail}" }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

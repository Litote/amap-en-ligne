@file:OptIn(ExperimentalTime::class)

package deploy.lambda

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.runBlocking
import persistence.model.EmailMessage
import properties.Properties
import serialization.json
import kotlin.time.ExperimentalTime

/**
 * SNS-triggered Lambda that delivers transactional emails. It decodes the
 * generic [EmailMessage] envelope published by the main Lambda's email
 * adapters (via [LambdaEmailGateway]) and hands it to SES.
 */
internal class ActivationEmailLambda(
    private val emailSender: SesEmailSender = SesEmailSender(Properties.Instance),
) {
    fun handleRequest(input: String): String {
        val event = json.decodeFromString<SnsEvent>(input)
        logger.info { "Received SNS event with ${event.records.size} record(s)" }
        runBlocking {
            for (record in event.records) {
                val message = json.decodeFromString<EmailMessage>(record.sns.message)
                logger.info { "Sending email to ${message.to} — subject: ${message.subject}" }
                runCatching { emailSender.send(message) }
                    .onSuccess { logger.info { "Email sent via SES to ${message.to}" } }
                    .onFailure { error -> logger.error(error) { "SES delivery failed for ${message.to}" } }
            }
        }
        return ""
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

package persistence.model

import kotlinx.serialization.Serializable

/**
 * Generic transactional email payload exchanged over the email SNS topic.
 *
 * The producing side (the main Lambda's email adapters) renders the subject
 * and body up-front, so the consuming side ([deploy.lambda.ActivationEmailLambda])
 * stays a dumb transport: it only needs to know the recipient, subject and
 * body to hand the message to SES. This keeps email content (and its tests)
 * in the synchronous request path while the actual delivery stays decoupled
 * and asynchronous.
 */
@Serializable
data class EmailMessage(
    val to: String,
    val subject: String,
    val body: String,
)

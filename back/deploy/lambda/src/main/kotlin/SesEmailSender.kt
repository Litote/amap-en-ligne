@file:OptIn(ExperimentalTime::class)

package deploy.lambda

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.sesv2.SesV2Client
import aws.sdk.kotlin.services.sesv2.model.Body
import aws.sdk.kotlin.services.sesv2.model.Content
import aws.sdk.kotlin.services.sesv2.model.Destination
import aws.sdk.kotlin.services.sesv2.model.EmailContent
import aws.sdk.kotlin.services.sesv2.model.Message
import aws.sdk.kotlin.services.sesv2.model.SendEmailRequest
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import persistence.model.EmailMessage
import properties.Properties
import kotlin.time.ExperimentalTime

/**
 * Dumb SES transport: sends a fully-rendered [EmailMessage] (recipient,
 * subject, body) via Amazon SES. All content is built upstream by
 * [EmailTemplates]; this class only knows the from-address and how to call SES.
 */
internal class SesEmailSender(
    private val properties: Properties,
) {
    private val fromEmail: String = properties.property("SES_FROM_EMAIL", "noreply@amap-en-ligne.fr")
    private val sesClient: SesV2Client =
        SesV2Client {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }

    suspend fun send(message: EmailMessage) {
        sesClient.sendEmail(
            SendEmailRequest {
                fromEmailAddress = fromEmail
                destination =
                    Destination {
                        toAddresses = listOf(message.to)
                    }
                content =
                    EmailContent {
                        simple =
                            Message {
                                subject =
                                    Content {
                                        data = message.subject
                                        charset = "UTF-8"
                                    }
                                this.body =
                                    Body {
                                        text =
                                            Content {
                                                data = message.body
                                                charset = "UTF-8"
                                            }
                                    }
                            }
                    }
            },
        )
    }
}

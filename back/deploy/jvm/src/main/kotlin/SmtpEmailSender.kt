package deploy.jvm

import io.github.oshai.kotlinlogging.KotlinLogging
import jakarta.mail.Session
import jakarta.mail.Transport
import jakarta.mail.internet.InternetAddress
import jakarta.mail.internet.MimeMessage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.annotation.Single
import properties.Properties
import java.util.Date
import java.util.Properties as JavaProperties

@Single(createdAtStart = true, binds = [EmailSender::class])
internal class SmtpEmailSender(
    private val properties: Properties,
) : EmailSender {
    private val smtpHost: String = properties.property("SMTP_HOST", "localhost")
    private val smtpPort: String = properties.intProperty("SMTP_PORT", 1025).toString()
    private val smtpUsername: String? = properties.propertyOrNull("SMTP_USERNAME")
    private val smtpPassword: String? = properties.propertyOrNull("SMTP_PASSWORD")
    private val fromEmail: String = properties.property("SMTP_FROM_EMAIL", "noreply@amap-en-ligne.fr")
    private val tlsEnabled: Boolean = properties.booleanProperty("SMTP_TLS", false)

    override suspend fun sendNotificationEmail(
        to: String,
        subject: String,
        body: String,
    ) {
        withContext(Dispatchers.IO) {
            val props =
                JavaProperties().apply {
                    put("mail.smtp.host", smtpHost)
                    put("mail.smtp.port", smtpPort)
                    if (tlsEnabled) {
                        put("mail.smtp.starttls.enable", "true")
                    }
                }
            val session =
                if (smtpUsername != null && smtpPassword != null) {
                    val username = smtpUsername
                    val password = smtpPassword
                    props["mail.smtp.auth"] = "true"
                    Session.getInstance(
                        props,
                        object : jakarta.mail.Authenticator() {
                            override fun getPasswordAuthentication() = jakarta.mail.PasswordAuthentication(username, password)
                        },
                    )
                } else {
                    Session.getInstance(props)
                }

            val mime = MimeMessage(session)
            mime.setFrom(InternetAddress(fromEmail))
            mime.setRecipients(jakarta.mail.Message.RecipientType.TO, InternetAddress.parse(to))
            // Branding (subject prefix + instance footer) is applied upstream in JvmEmailGateway;
            // this transport stays dumb and sends the message verbatim.
            mime.subject = subject
            mime.sentDate = Date()
            mime.setText(body, "UTF-8", "plain")
            mime.setHeader("Content-Transfer-Encoding", "8bit")

            Transport.send(mime)
            logger.info { "Notification email sent to $to" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

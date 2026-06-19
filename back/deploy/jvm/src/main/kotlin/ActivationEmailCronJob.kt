@file:OptIn(ExperimentalTime::class)

package deploy.jvm

import email.EmailTemplates
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.annotation.Single
import persistence.model.EmailMessage
import javax.sql.DataSource
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single
internal class ActivationEmailCronJob(
    private val dataSource: DataSource,
    private val gateway: JvmEmailGateway,
) {
    private data class PendingActivationEmail(
        val token: String,
        val adminEmail: String,
        val adminFirstName: String,
        val adminLastName: String,
        val organizationName: String,
        val expiresAt: Instant,
    )

    suspend fun processPending() {
        val pending = fetchPending()
        for (row in pending) {
            try {
                val activationUrl = gateway.activationUrl(row.token)
                val content =
                    EmailTemplates.organizationActivationForCronJob(
                        adminFirstName = row.adminFirstName,
                        adminLastName = row.adminLastName,
                        organizationName = row.organizationName,
                        activationUrl = activationUrl,
                        expiresAt = row.expiresAt,
                    )
                gateway.deliver(EmailMessage(to = row.adminEmail, subject = content.subject, body = content.body))
                markEmailSent(row.token)
                logger.info { "Activation email sent to ${row.adminEmail} (token=${row.token})" }
            } catch (e: Throwable) {
                logger.error(e) { "Failed to send activation email to ${row.adminEmail} (token=${row.token})" }
            }
        }
    }

    private suspend fun fetchPending(): List<PendingActivationEmail> =
        withContext(Dispatchers.IO) {
            dataSource.connection.use { conn ->
                conn
                    .prepareStatement(
                        """
                        SELECT at.token, at.admin_email, at.expires_at,
                               r.admin_first_name, r.admin_last_name, r.organization_name
                        FROM activation_token at
                        JOIN organization_request r ON r.request_id = at.request_id
                        WHERE at.email_sent = false
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.executeQuery().use { rs ->
                            buildList {
                                while (rs.next()) {
                                    add(
                                        PendingActivationEmail(
                                            token = rs.getString("token"),
                                            adminEmail = rs.getString("admin_email"),
                                            adminFirstName = rs.getString("admin_first_name"),
                                            adminLastName = rs.getString("admin_last_name"),
                                            organizationName = rs.getString("organization_name"),
                                            expiresAt = Instant.fromEpochMilliseconds(rs.getLong("expires_at")),
                                        ),
                                    )
                                }
                            }
                        }
                    }
            }
        }

    private suspend fun markEmailSent(token: String) =
        withContext(Dispatchers.IO) {
            dataSource.connection.use { conn ->
                conn.autoCommit = false
                try {
                    conn
                        .prepareStatement(
                            "UPDATE activation_token SET email_sent = true WHERE token = ?",
                        ).use { stmt ->
                            stmt.setString(1, token)
                            stmt.executeUpdate()
                        }
                    conn.commit()
                } catch (e: Throwable) {
                    conn.rollback()
                    throw e
                }
            }
        }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

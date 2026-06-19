package email.delivery

import persistence.model.EmailMessage

/**
 * Outbound email gateway shared by every email-port adapter. Each deployment
 * provides one implementation (SMTP on the JVM server, SNS → SES on Lambda) and
 * owns any transport branding. Delivery is **best-effort**: a transport failure
 * is logged and swallowed so it never rolls back the already-committed sync
 * mutation that triggered the email. The rendered content (and its tests) live
 * in `EmailTemplates`.
 */
interface EmailGateway {
    /** Builds the public activation URL for a freshly issued activation token. */
    fun activationUrl(token: String): String

    /** Delivers a fully-rendered email, best-effort. */
    suspend fun deliver(message: EmailMessage)
}

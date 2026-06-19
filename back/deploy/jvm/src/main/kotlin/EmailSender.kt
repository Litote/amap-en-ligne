package deploy.jvm

internal interface EmailSender {
    /** Generic plain-text email used by the SMTP transport. */
    suspend fun sendNotificationEmail(
        to: String,
        subject: String,
        body: String,
    )
}

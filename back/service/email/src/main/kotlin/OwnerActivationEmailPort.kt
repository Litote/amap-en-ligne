package email

import persistence.model.ActivationToken
import persistence.model.OwnerInvitation

fun interface OwnerActivationEmailPort {
    /** Sends the activation email to the newly invited owner. */
    suspend fun sendOwnerActivationEmail(
        invitation: OwnerInvitation,
        token: ActivationToken,
    )
}

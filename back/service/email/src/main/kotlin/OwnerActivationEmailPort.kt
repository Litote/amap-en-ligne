package email

import persistence.model.ActivationToken
import persistence.model.OwnerInvitation

interface OwnerActivationEmailPort {
    /** Sends the activation email to the newly invited owner. */
    suspend fun sendOwnerActivationEmail(
        invitation: OwnerInvitation,
        token: ActivationToken,
    )
}

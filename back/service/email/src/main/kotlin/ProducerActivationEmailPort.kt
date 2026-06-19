package email

import persistence.model.ActivationToken
import persistence.model.ProducerRequest

fun interface ProducerActivationEmailPort {
    suspend fun sendProducerActivationEmail(
        request: ProducerRequest,
        token: ActivationToken,
    )
}

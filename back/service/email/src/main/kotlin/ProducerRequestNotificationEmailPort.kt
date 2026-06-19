package email

import persistence.model.ProducerRequest

fun interface ProducerRequestNotificationEmailPort {
    suspend fun notifyOwners(request: ProducerRequest)
}

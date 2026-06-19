package email

import persistence.model.ProducerRequest

interface ProducerRequestNotificationEmailPort {
    suspend fun notifyOwners(request: ProducerRequest)
}

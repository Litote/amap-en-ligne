package email

import persistence.model.ProducerRequest

interface ProducerRequestRejectionEmailPort {
    suspend fun sendRejectionEmail(
        request: ProducerRequest,
        reviewComment: String?,
    )
}

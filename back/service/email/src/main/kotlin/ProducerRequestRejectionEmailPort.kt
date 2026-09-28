package email

import persistence.model.ProducerRequest

fun interface ProducerRequestRejectionEmailPort {
    suspend fun sendRejectionEmail(
        request: ProducerRequest,
        reviewComment: String?,
    )
}

package persistence.model

import kotlinx.serialization.Serializable

@Serializable
data class ActivateRequest(
    val token: String,
    val password: String,
)

@file:OptIn(ExperimentalTime::class)

package http

import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Error response following RFC9457 standard
 */
@Serializable
data class ErrorResponse(
    val type: String,
    val title: String,
    val status: Int,
    val detail: String,
    val instance: String,
    val timestamp: Instant,
    val error: ErrorDetails,
)

/**
 * Error details for enhanced error information
 */
@Serializable
data class ErrorDetails(
    val code: String,
    val details: Map<String, String>? = null,
)

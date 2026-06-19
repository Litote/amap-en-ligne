@file:OptIn(ExperimentalTime::class)

package http

import org.koin.core.annotation.Single
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true)
class HttpService {
    fun internalServerError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/technical",
            title = "Internal Server Error",
            status = 500,
            detail = "Internal Server Error",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "Internal Server Error",
                    details = mapOf("reason" to "Internal Server Error"),
                ),
        )

    fun expiredTokenError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/unauthorized",
            title = "Unauthorized",
            status = 401,
            detail = "expired authentication token",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "EXPIRED_AUTH_TOKEN",
                    details = mapOf("reason" to "Token expired"),
                ),
        )

    fun invalidTokenError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/unauthorized",
            title = "Unauthorized",
            status = 401,
            detail = "no authentication token provided",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "INVALID_AUTH_TOKEN",
                    details = mapOf("reason" to "Token expired"),
                ),
        )

    fun conflictError(
        instance: String,
        field: String,
        existingStatus: String? = null,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/conflict",
            title = "Conflict",
            status = 409,
            detail = "a resource with the same value already exists",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "CONFLICT",
                    details =
                        buildMap {
                            put("field", field)
                            existingStatus?.let { put("existing_status", it) }
                        },
                ),
        )

    fun forbiddenError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/forbidden",
            title = "Forbidden",
            status = 403,
            detail = "insufficient permissions",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "FORBIDDEN",
                    details = mapOf("reason" to "Admin role required"),
                ),
        )

    fun notFoundError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/not-found",
            title = "Not Found",
            status = 404,
            detail = "resource not found",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "NOT_FOUND",
                    details = mapOf("reason" to "Resource not found"),
                ),
        )

    fun invalidPayloadError(
        instance: String,
        reason: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/bad-request",
            title = "Bad Request",
            status = 400,
            detail = reason,
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "INVALID_PAYLOAD",
                    details = mapOf("reason" to reason),
                ),
        )

    fun mutationBatchTooLargeError(
        instance: String,
        limit: Int,
        actual: Int,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/bad-request",
            title = "Bad Request",
            status = 400,
            detail = "mutation batch size $actual exceeds the limit of $limit",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "MUTATION_BATCH_TOO_LARGE",
                    details =
                        mapOf(
                            "limit" to limit.toString(),
                            "actual" to actual.toString(),
                        ),
                ),
        )

    fun wrongServerError(
        instance: String,
        tokenIssuer: String?,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "https://nyd.com/problems/unauthorized",
            title = "Unauthorized",
            status = 401,
            detail = "token was issued by a different server instance",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "WRONG_SERVER",
                    details =
                        buildMap {
                            put("reason", "Authenticate against the server that issued your token")
                            tokenIssuer?.let { put("token_issuer", it) }
                        },
                ),
        )
}

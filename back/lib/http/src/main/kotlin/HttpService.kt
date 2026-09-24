@file:OptIn(ExperimentalTime::class)

package http

import org.koin.core.annotation.Single
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true)
class HttpService {
    private companion object {
        private const val INTERNAL_SERVER_ERROR = "Internal Server Error"
        private const val BAD_REQUEST = "Bad Request"
        private const val PROBLEM_TYPE_PREFIX = "urn:amap-en-ligne:problem:"
        private const val PROBLEM_UNAUTHORIZED = "${PROBLEM_TYPE_PREFIX}unauthorized"
        private const val PROBLEM_BAD_REQUEST = "${PROBLEM_TYPE_PREFIX}bad-request"
    }

    fun internalServerError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "${PROBLEM_TYPE_PREFIX}technical",
            title = INTERNAL_SERVER_ERROR,
            status = 500,
            detail = INTERNAL_SERVER_ERROR,
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = INTERNAL_SERVER_ERROR,
                    details = mapOf("reason" to INTERNAL_SERVER_ERROR),
                ),
        )

    fun expiredTokenError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = PROBLEM_UNAUTHORIZED,
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
            type = PROBLEM_UNAUTHORIZED,
            title = "Unauthorized",
            status = 401,
            detail = "missing or invalid authentication token",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "INVALID_AUTH_TOKEN",
                    details = mapOf("reason" to "Token missing or invalid"),
                ),
        )

    fun conflictError(
        instance: String,
        field: String,
        existingStatus: String? = null,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "${PROBLEM_TYPE_PREFIX}conflict",
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
            type = "${PROBLEM_TYPE_PREFIX}forbidden",
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
            type = "${PROBLEM_TYPE_PREFIX}not-found",
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

    fun goneError(
        instance: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = "${PROBLEM_TYPE_PREFIX}gone",
            title = "Gone",
            status = 410,
            detail = "resource is no longer available",
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "GONE",
                    details = mapOf("reason" to "Resource expired"),
                ),
        )

    fun invalidPayloadError(
        instance: String,
        reason: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = PROBLEM_BAD_REQUEST,
            title = BAD_REQUEST,
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

    fun weakPasswordError(
        instance: String,
        reason: String,
        timestamp: Instant = Clock.System.now(),
    ): ErrorResponse =
        ErrorResponse(
            type = PROBLEM_BAD_REQUEST,
            title = BAD_REQUEST,
            status = 400,
            detail = reason,
            instance = instance,
            timestamp = timestamp,
            error =
                ErrorDetails(
                    code = "WEAK_PASSWORD",
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
            type = PROBLEM_BAD_REQUEST,
            title = BAD_REQUEST,
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
            type = PROBLEM_UNAUTHORIZED,
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

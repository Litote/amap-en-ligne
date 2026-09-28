package routing

import http.ErrorResponse
import io.ktor.http.ContentType
import io.ktor.http.content.TextContent
import io.ktor.server.application.createApplicationPlugin
import kotlinx.serialization.json.Json

/**
 * Serves every [ErrorResponse] as `application/problem+json` (RFC 9457) instead of the
 * `application/json` that content negotiation would pick.
 *
 * Must be installed before `ContentNegotiation`: both transform the body on call respond,
 * in install order, and content negotiation leaves an already-converted body untouched.
 */
internal fun problemDetailsPlugin(json: Json) =
    createApplicationPlugin(name = "ProblemDetails") {
        onCallRespond { _, body ->
            if (body is ErrorResponse) {
                transformBody {
                    TextContent(json.encodeToString(ErrorResponse.serializer(), body), ContentType.Application.ProblemJson)
                }
            }
        }
    }

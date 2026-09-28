package routing

import authentication.AuthenticatedInfo
import authentication.Authentication
import authentication.AuthenticationService
import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.path
import io.ktor.server.response.respond

/**
 * Resolves the authenticated principal for call using [authenticationService].
 * Returns the [AuthenticatedInfo] on success, or `null` after responding with a
 * 401 envelope built by [httpService] when the token is expired or invalid.
 *
 * Mirrors the auth pre-check previously inlined in `APIGatewayLambdaBase.call`.
 */
internal suspend fun authenticatedInfoOrRespond(
    call: ApplicationCall,
    authenticationService: AuthenticationService,
    httpService: HttpService,
): AuthenticatedInfo? {
    val path = call.request.path()
    if (authenticationService.isUnauthenticatedPath(path)) {
        error("authenticatedInfoOrRespond called on unauthenticated path: $path")
    }
    return when (val auth = authenticationService.getAuthentication(call.request.headers["Authorization"])) {
        is Authentication.Success -> {
            auth.info
        }

        Authentication.ExpiredToken -> {
            call.respond(HttpStatusCode.Unauthorized, httpService.expiredTokenError(path))
            null
        }

        Authentication.InvalidToken -> {
            call.respond(HttpStatusCode.Unauthorized, httpService.invalidTokenError(path))
            null
        }

        is Authentication.WrongServer -> {
            call.respond(HttpStatusCode.Unauthorized, httpService.wrongServerError(path, auth.tokenIssuer))
            null
        }
    }
}

package routing

import activation.ActivationOutcome
import activation.ActivationService
import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.path
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import persistence.model.ActivateRequest

internal fun Route.activationRoute(
    activationService: ActivationService,
    httpService: HttpService,
) {
    get("/v1/activate") {
        val token = call.request.queryParameters["token"]
        if (token.isNullOrBlank()) {
            call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
            return@get
        }
        respondActivationOutcome(call, activationService.describe(token), httpService)
    }
    post("/v1/activate") {
        val request = call.receive<ActivateRequest>()
        passwordPolicyViolation(request.password)?.let { reason ->
            call.respond(HttpStatusCode.BadRequest, httpService.weakPasswordError(call.request.path(), reason))
            return@post
        }
        respondActivationOutcome(call, activationService.activate(request.token, request.password), httpService)
    }
}

// Not an ApplicationCall extension: ApplicationCall is a CoroutineScope and
// suspending CoroutineScope extensions are discouraged (Sonar kotlin:S6312).
private suspend fun respondActivationOutcome(
    call: ApplicationCall,
    outcome: ActivationOutcome,
    httpService: HttpService,
) {
    when (outcome) {
        is ActivationOutcome.Success -> {
            call.respond(outcome.response)
        }

        is ActivationOutcome.NotFound -> {
            call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
        }

        is ActivationOutcome.Expired -> {
            call.respond(HttpStatusCode.Gone, httpService.goneError(call.request.path()))
        }

        is ActivationOutcome.AlreadyActivated -> {
            call.respond(
                HttpStatusCode.Conflict,
                httpService.conflictError(call.request.path(), "token"),
            )
        }
    }
}

package routing

import activation.ActivationOutcome
import activation.ActivationService
import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.path
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import persistence.model.ActivateRequest

internal fun Route.activationRoute(
    activationService: ActivationService,
    httpService: HttpService,
) {
    post("/v1/activate") {
        val request = call.receive<ActivateRequest>()
        when (val outcome = activationService.activate(request.token, request.password)) {
            is ActivationOutcome.Success -> {
                call.respond(outcome.response)
            }

            is ActivationOutcome.NotFound -> {
                call.respond(HttpStatusCode.NotFound)
            }

            is ActivationOutcome.Expired -> {
                call.respond(HttpStatusCode.Gone)
            }

            is ActivationOutcome.AlreadyActivated -> {
                call.respond(
                    HttpStatusCode.Conflict,
                    httpService.conflictError(call.request.path(), "token"),
                )
            }
        }
    }
}

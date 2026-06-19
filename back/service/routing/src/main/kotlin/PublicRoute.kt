package routing

import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.path
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import onboarding.CreateMemberJoinOutcome
import onboarding.CreateOrganizationOutcome
import onboarding.CreateProducerOutcome
import onboarding.PublicService
import persistence.model.CreateMemberJoinRequestBody
import persistence.model.CreateOrganizationRequestBody
import persistence.model.CreateProducerRequestBody

internal fun Route.publicRoute(
    publicService: PublicService,
    httpService: HttpService,
) {
    get("/v1/public/organizations") {
        call.respond(publicService.listActiveOrganizations())
    }
    get("/v1/public/servers") {
        call.respond(publicService.listServers())
    }
    post("/v1/organization-requests") {
        val body = call.receive<CreateOrganizationRequestBody>()
        when (val outcome = publicService.createOrganizationRequest(body)) {
            is CreateOrganizationOutcome.Success -> {
                call.respond(HttpStatusCode.Created, outcome.result)
            }

            is CreateOrganizationOutcome.Conflict -> {
                call.respond(
                    HttpStatusCode.Conflict,
                    httpService.conflictError(call.request.path(), outcome.field, outcome.existingStatus.name),
                )
            }
        }
    }
    post("/v1/producer-requests") {
        val body = call.receive<CreateProducerRequestBody>()
        when (val outcome = publicService.createProducerRequest(body)) {
            is CreateProducerOutcome.Success -> {
                call.respond(HttpStatusCode.Created, outcome.result)
            }

            is CreateProducerOutcome.Conflict -> {
                call.respond(
                    HttpStatusCode.Conflict,
                    httpService.conflictError(call.request.path(), outcome.field, outcome.existingStatus.name),
                )
            }
        }
    }
    post("/v1/public/member-join-requests") {
        val body = call.receive<CreateMemberJoinRequestBody>()
        when (val outcome = publicService.createMemberJoinRequest(body)) {
            is CreateMemberJoinOutcome.Success -> {
                call.respond(HttpStatusCode.Created, outcome.result)
            }

            is CreateMemberJoinOutcome.Conflict -> {
                call.respond(
                    HttpStatusCode.Conflict,
                    httpService.conflictError(call.request.path(), outcome.field),
                )
            }
        }
    }
}

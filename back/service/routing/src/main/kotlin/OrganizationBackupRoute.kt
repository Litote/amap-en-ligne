package routing

import authentication.AuthenticationService
import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.path
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import persistence.changes.OrganizationExport
import sync.ExportOutcome
import sync.ExportService
import sync.ImportOutcome
import sync.ImportService

/**
 * Authenticated admin endpoints to back up / migrate a single organization in the
 * native JSON format.
 *
 * - `GET /v1/admin/organizations/{id}/export` — dump the organization's data.
 * - `POST /v1/admin/organizations/{id}/import` — restore an archive into the (empty) org.
 *
 * Authorization is enforced in the services: OWNER for any org, otherwise an ADMIN
 * of that very organization.
 */
internal fun Route.organizationBackupRoute(
    exportService: ExportService,
    importService: ImportService,
    authenticationService: AuthenticationService,
    httpService: HttpService,
    instanceName: String,
) {
    get("/v1/admin/organizations/{id}/export") {
        val info = authenticatedInfoOrRespond(call, authenticationService, httpService) ?: return@get
        val organizationId =
            call.parameters["id"]?.takeIf { it.isNotBlank() }
                ?: run {
                    call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
                    return@get
                }
        when (val outcome = exportService.exportOrganization(info, organizationId, instanceName)) {
            is ExportOutcome.Success -> call.respond(outcome.export)
            ExportOutcome.Forbidden -> call.respond(HttpStatusCode.Forbidden, httpService.forbiddenError(call.request.path()))
            ExportOutcome.NotFound -> call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
        }
    }

    post("/v1/admin/organizations/{id}/import") {
        val info = authenticatedInfoOrRespond(call, authenticationService, httpService) ?: return@post
        val organizationId =
            call.parameters["id"]?.takeIf { it.isNotBlank() }
                ?: run {
                    call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
                    return@post
                }
        val export = call.receive<OrganizationExport>()
        when (val outcome = importService.importIntoOrganization(info, organizationId, export)) {
            is ImportOutcome.Success -> {
                call.respond(outcome.result)
            }

            ImportOutcome.Forbidden -> {
                call.respond(HttpStatusCode.Forbidden, httpService.forbiddenError(call.request.path()))
            }

            ImportOutcome.NotFound -> {
                call.respond(HttpStatusCode.NotFound, httpService.notFoundError(call.request.path()))
            }

            is ImportOutcome.Conflict -> {
                call.respond(
                    HttpStatusCode.Conflict,
                    httpService.conflictError(call.request.path(), field = outcome.reason),
                )
            }

            is ImportOutcome.InvalidFormat -> {
                call.respond(HttpStatusCode.BadRequest, httpService.invalidPayloadError(call.request.path(), outcome.reason))
            }
        }
    }
}

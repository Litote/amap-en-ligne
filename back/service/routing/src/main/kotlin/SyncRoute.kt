package routing

import authentication.AuthenticationService
import http.HttpService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.path
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import persistence.changes.SyncRequest
import sync.DataService

/**
 * Maximum number of [ClientMutation]s accepted in a single `POST /v1/sync` call.
 *
 * A batch larger than this is rejected with HTTP 400 before any persistence occurs.
 * 500 is a deliberately conservative upper bound: typical client batches are well under 50
 * (offline queue drains), and extremely large batches are most likely bugs or abuse.
 */
internal const val MAX_MUTATIONS_PER_SYNC = 500

internal fun Route.syncRoute(
    dataService: DataService,
    authenticationService: AuthenticationService,
    httpService: HttpService,
) {
    post("/v1/sync") {
        val info = call.authenticatedInfoOrRespond(authenticationService, httpService) ?: return@post
        if (info.roles.isEmpty()) {
            call.respond(HttpStatusCode.Forbidden, httpService.forbiddenError(call.request.path()))
            return@post
        }
        val request = call.receive<SyncRequest>()
        if (request.mutations.size > MAX_MUTATIONS_PER_SYNC) {
            call.respond(
                HttpStatusCode.BadRequest,
                httpService.mutationBatchTooLargeError(
                    instance = call.request.path(),
                    limit = MAX_MUTATIONS_PER_SYNC,
                    actual = request.mutations.size,
                ),
            )
            return@post
        }
        val response = dataService.sync(info, request.cursors, request.mutations)
        call.respond(response)
    }
}

package routing

import authentication.AuthenticationService
import authentication.Role
import http.HttpService
import id.toId
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.path
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.ProducerAccount

internal fun Route.producerAccountSearchRoute(
    producerAccountSyncDAO: ProducerAccountSyncDAO,
    memberSyncDAO: MemberSyncDAO,
    authenticationService: AuthenticationService,
    httpService: HttpService,
) {
    get("/v1/admin/producer-accounts/search") {
        val info = call.authenticatedInfoOrRespond(authenticationService, httpService) ?: return@get
        if (!info.roles.any { it == Role.ADMIN || it == Role.OWNER }) {
            call.respond(HttpStatusCode.Forbidden, httpService.forbiddenError(call.request.path()))
            return@get
        }
        // After sub/id unification, organizationId is no longer in the JWT.
        // Resolve it from the DAO for ADMIN callers (OWNER callers can search instance-wide).
        val organizationId: String? =
            if (info.roles.contains(Role.OWNER)) {
                // OWNER can search without an org constraint.
                null
            } else {
                info.organizationId
                    ?: memberSyncDAO.findOrganizationIdBySub(info.memberId)?.id
                    ?: run {
                        call.respond(HttpStatusCode.Forbidden, httpService.forbiddenError(call.request.path()))
                        return@get
                    }
            }
        val q =
            call.request.queryParameters["q"]?.takeIf { it.isNotBlank() }
                ?: run {
                    call.respond(emptyList<ProducerAccount>())
                    return@get
                }
        val results =
            if (organizationId != null) {
                producerAccountSyncDAO.search(organizationId.toId<persistence.model.Organization>(), q)
            } else {
                // OWNER: instance-wide producer account search is not yet implemented
                emptyList()
            }
        call.respond(results)
    }
}

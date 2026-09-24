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
import persistence.dao.ProductTypeSyncDAO
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerProduct

internal fun Route.producerAccountSearchRoute(
    producerAccountSyncDAO: ProducerAccountSyncDAO,
    productTypeSyncDAO: ProductTypeSyncDAO?,
    memberSyncDAO: MemberSyncDAO,
    authenticationService: AuthenticationService,
    httpService: HttpService,
) {
    get("/v1/admin/producer-accounts/search") {
        val info = authenticatedInfoOrRespond(call, authenticationService, httpService) ?: return@get
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
                // OWNER: instance-wide search — same predicate as ADMIN search but without org exclusion.
                val lowerQuery = q.lowercase()
                producerAccountSyncDAO.listAll().filter { pa ->
                    pa.managementMode == ProducerManagementMode.ACCOUNT_BACKED &&
                        pa.activeStatus &&
                        (
                            pa.name.lowercase().contains(lowerQuery) ||
                                pa.contactEmail?.lowercase()?.contains(lowerQuery) == true
                        )
                }
            }
        call.respond(results.map { withCatalogProducts(it, productTypeSyncDAO) })
    }
}

/**
 * An account-backed producer manages its catalog as [persistence.model.ProductType]s, not in
 * [ProducerAccount.products]: expose them as products so the enrollment step can offer them
 * (otherwise such a producer could never be linked to an organization).
 */
private suspend fun withCatalogProducts(
    producer: ProducerAccount,
    productTypeSyncDAO: ProductTypeSyncDAO?,
): ProducerAccount {
    if (productTypeSyncDAO == null ||
        producer.managementMode != ProducerManagementMode.ACCOUNT_BACKED ||
        producer.products.isNotEmpty()
    ) {
        return producer
    }
    val products =
        productTypeSyncDAO.getByProducerAccountId(producer.producerAccountId).map {
            ProducerProduct(
                name = it.name,
                productTypeId = it.productTypeId,
                supportedBasketSizes = it.supportedBasketSizes,
                description = it.description,
            )
        }
    return producer.copy(products = products)
}

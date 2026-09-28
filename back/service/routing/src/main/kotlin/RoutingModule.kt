package routing

import activation.ActivationService
import authentication.AuthenticationService
import http.HttpService
import instanceconfig.InstanceAuthConfigSerializers
import instanceconfig.InstanceConfig
import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.BadRequestException
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.plugins.statuspages.StatusPages
import io.ktor.server.request.path
import io.ktor.server.response.respond
import io.ktor.server.routing.routing
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.plus
import onboarding.PublicService
import org.koin.core.KoinApplication
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import properties.Properties
import sync.DataService
import sync.ExportService
import sync.ImportService
import serialization.json as projectJson

/**
 * Wires the data routing into a Ktor [Application]. The same module is reused
 * by both the JVM HTTP deployment (`deploy:jvm`) and the Lambda deployment
 * (`deploy:lambda`), so that no transport-specific code leaks into
 * the route definitions.
 *
 * Services are resolved from [koin] eagerly. Koin is started by the caller,
 * keeping module composition flexible (different deployments may register
 * different sets of Koin modules).
 */
fun Application.dataRoutingModule(koin: KoinApplication) {
    val dataService = koin.koin.get<DataService>()
    val authenticationService = koin.koin.get<AuthenticationService>()
    val httpService = koin.koin.get<HttpService>()
    val instanceConfig = koin.koin.get<InstanceConfig>()
    val publicService = koin.koin.get<PublicService>()
    val activationService = koin.koin.get<ActivationService>()
    val producerAccountSyncDAO = koin.koin.get<ProducerAccountSyncDAO>()
    val productTypeSyncDAO = koin.koin.getOrNull<ProductTypeSyncDAO>()
    val memberSyncDAO = koin.koin.get<MemberSyncDAO>()
    val exportService = koin.koin.getOrNull<ExportService>()
    val importService = koin.koin.getOrNull<ImportService>()
    val properties = koin.koin.get<Properties>()
    val instanceAuthConfigSerializers = koin.koin.getOrNull<InstanceAuthConfigSerializers>()

    val routingJson =
        if (instanceAuthConfigSerializers == null) {
            projectJson
        } else {
            Json(projectJson) {
                serializersModule = projectJson.serializersModule + instanceAuthConfigSerializers.module
            }
        }

    install(problemDetailsPlugin(routingJson))
    install(ContentNegotiation) {
        json(routingJson)
    }

    install(StatusPages) {
        // A body in another format than JSON: the engine answers 415 itself with Ktor's
        // plain-text message (it names internal classes) — replace it with a problem document.
        status(HttpStatusCode.UnsupportedMediaType) { status ->
            call.respond(status, httpService.unsupportedMediaTypeError(call.request.path()))
        }
        // Unknown path / known path with another method: routing answers without a body;
        // give it a problem document. A route's own error body is left untouched.
        status(HttpStatusCode.NotFound, HttpStatusCode.MethodNotAllowed) { status ->
            if (content !is OutgoingContent.NoContent) return@status
            val path = call.request.path()
            call.respond(
                status,
                if (status == HttpStatusCode.NotFound) {
                    httpService.notFoundError(path)
                } else {
                    httpService.methodNotAllowedError(path)
                },
            )
        }
        // Malformed / undecodable request bodies (thrown by `call.receive`) are client errors.
        exception<BadRequestException> { call, cause ->
            logger.debug(cause) { "Bad request: ${cause.message}" }
            call.respond(
                HttpStatusCode.BadRequest,
                httpService.invalidPayloadError(call.request.path(), "malformed request body"),
            )
        }
        exception<Throwable> { call, cause ->
            logger.error(cause) { "Technical error: ${cause.message}" }
            call.respond(
                HttpStatusCode.InternalServerError,
                httpService.internalServerError(call.request.path()),
            )
        }
    }

    routing {
        discoveryRoute(instanceConfig)
        publicRoute(publicService, httpService)
        producerAccountSearchRoute(producerAccountSyncDAO, productTypeSyncDAO, memberSyncDAO, authenticationService, httpService)
        if (exportService != null && importService != null) {
            organizationBackupRoute(exportService, importService, authenticationService, httpService, instanceConfig.name)
        }
        activationRoute(activationService, httpService)
        deepLinkRoute(properties)
        syncRoute(dataService, authenticationService, httpService)
    }
}

private val logger = KotlinLogging.logger {}

package routing

import activation.ActivationService
import authentication.AuthenticationService
import http.HttpService
import instanceconfig.InstanceAuthConfigSerializers
import instanceconfig.InstanceConfig
import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.http.HttpStatusCode
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
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

    install(ContentNegotiation) {
        json(routingJson)
    }

    install(StatusPages) {
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
        producerAccountSearchRoute(producerAccountSyncDAO, memberSyncDAO, authenticationService, httpService)
        if (exportService != null && importService != null) {
            organizationBackupRoute(exportService, importService, authenticationService, httpService, instanceConfig.name)
        }
        activationRoute(activationService, httpService)
        deepLinkRoute(properties)
        syncRoute(dataService, authenticationService, httpService)
    }
}

private val logger = KotlinLogging.logger {}

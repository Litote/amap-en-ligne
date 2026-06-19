package lambda.ktor

import io.ktor.server.application.Application
import io.ktor.server.engine.EmbeddedServer
import io.ktor.server.engine.embeddedServer
import kotlinx.serialization.KSerializer
import lambda.APIGatewayV2HTTPEvent
import lambda.APIGatewayV2HTTPResponse
import lambda.SynchronousLambdaBase
import org.koin.core.KoinApplication

/**
 * Lambda handler base that drives an embedded Ktor pipeline via [LambdaEngine]
 * for API Gateway V2 (HTTP API) events. Subclasses (or callers passing a
 * [routingModule]) bring their own routing module — typically the same one
 * used by `deploy:jvm`, so HTTP behaviour is identical across deployments.
 *
 * The Ktor [EmbeddedServer] is constructed once per Lambda container and
 * reused across invocations: routing definitions and Koin lookups happen
 * exactly once at cold start.
 */
open class APIGatewayLambdaBase(
    koin: KoinApplication,
    routingModule: Application.(KoinApplication) -> Unit,
) : SynchronousLambdaBase<APIGatewayV2HTTPResponse>(koin) {
    private val server: EmbeddedServer<LambdaEngine, LambdaEngine.Configuration> =
        embeddedServer(LambdaEngine) {
            routingModule(koin)
        }.apply { start(wait = false) }

    override val responseSerializer: KSerializer<APIGatewayV2HTTPResponse> = APIGatewayV2HTTPResponse.serializer()

    final override suspend fun call(): APIGatewayV2HTTPResponse {
        val event = read<APIGatewayV2HTTPEvent>()
        return server.engine.handle(event)
    }

    override fun technicalError(): APIGatewayV2HTTPResponse = APIGatewayV2HTTPResponse(statusCode = 500)
}

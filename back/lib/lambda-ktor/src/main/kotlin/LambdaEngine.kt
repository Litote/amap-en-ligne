package lambda.ktor

import io.ktor.events.Events
import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationEnvironment
import io.ktor.server.engine.ApplicationEngine
import io.ktor.server.engine.ApplicationEngineFactory
import io.ktor.server.engine.BaseApplicationEngine
import io.ktor.util.pipeline.execute
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.readRemaining
import kotlinx.io.readByteArray
import lambda.APIGatewayV2HTTPEvent
import lambda.APIGatewayV2HTTPResponse
import java.util.Base64
import kotlin.coroutines.coroutineContext

/**
 * Ktor engine that maps a single [APIGatewayV2HTTPEvent] through the Ktor
 * pipeline and returns the resulting [APIGatewayV2HTTPResponse]. Unlike a
 * network engine, this one does not bind sockets; [start] and [stop] are
 * no-ops aside from the standard lifecycle events raised by the
 * [BaseApplicationEngine] base class.
 */
class LambdaEngine internal constructor(
    environment: ApplicationEnvironment,
    monitor: Events,
    developmentMode: Boolean,
    @Suppress("unused") public val configuration: Configuration,
    private val applicationProvider: () -> Application,
) : BaseApplicationEngine(environment, monitor, developmentMode) {
    class Configuration : BaseApplicationEngine.Configuration()

    override fun start(wait: Boolean): ApplicationEngine = this

    override fun stop(
        gracePeriodMillis: Long,
        timeoutMillis: Long,
    ) {
        // no-op: Lambda engine has no underlying server to release
    }

    suspend fun handle(event: APIGatewayV2HTTPEvent): APIGatewayV2HTTPResponse {
        val call = LambdaApplicationCall(applicationProvider(), event, coroutineContext)
        pipeline.execute(call)
        call.response.capturedBody.flushAndClose()
        return buildResponse(call.response)
    }

    companion object Factory : ApplicationEngineFactory<LambdaEngine, Configuration> {
        override fun configuration(configure: Configuration.() -> Unit): Configuration = Configuration().apply(configure)

        override fun create(
            environment: ApplicationEnvironment,
            monitor: Events,
            developmentMode: Boolean,
            configuration: Configuration,
            applicationProvider: () -> Application,
        ): LambdaEngine = LambdaEngine(environment, monitor, developmentMode, configuration, applicationProvider)
    }
}

private suspend fun buildResponse(response: LambdaApplicationResponse): APIGatewayV2HTTPResponse {
    val bodyBytes = response.capturedBody.drain()
    val headersMap =
        response.capturedHeaders.entries().associate { (name, values) ->
            name to values.joinToString(",")
        }
    val isText =
        headersMap.entries
            .firstOrNull { it.key.equals("content-type", ignoreCase = true) }
            ?.value
            ?.let { it.startsWith("text/") || it.contains("json") || it.contains("xml") || it.contains("javascript") }
            ?: false
    val (body, base64) =
        when {
            bodyBytes.isEmpty() -> null to false
            isText -> bodyBytes.toString(Charsets.UTF_8) to false
            else -> Base64.getEncoder().encodeToString(bodyBytes) to true
        }
    return APIGatewayV2HTTPResponse(
        statusCode = response.capturedStatus.value,
        headers = headersMap,
        body = body,
        base64Encoded = base64,
    )
}

private suspend fun ByteReadChannel.drain(): ByteArray = readRemaining().readByteArray()

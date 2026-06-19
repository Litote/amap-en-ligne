package lambda.ktor

import io.ktor.http.HeadersBuilder
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import io.ktor.server.application.PipelineCall
import io.ktor.server.engine.BaseApplicationResponse
import io.ktor.server.response.ResponseHeaders
import io.ktor.utils.io.ByteChannel
import io.ktor.utils.io.ByteWriteChannel

/**
 * Captures status, headers and body bytes in memory while the Ktor pipeline
 * runs, so that [LambdaEngine] can serialize them into an
 * [lambda.APIGatewayV2HTTPResponse] envelope after the pipeline completes.
 */
internal class LambdaApplicationResponse(
    call: PipelineCall,
) : BaseApplicationResponse(call) {
    @Volatile
    private var statusCode: HttpStatusCode = HttpStatusCode.OK

    private val headersBuilder: HeadersBuilder = HeadersBuilder()

    private val output: ByteChannel = ByteChannel(autoFlush = true)

    val capturedStatus: HttpStatusCode
        get() = statusCode

    val capturedHeaders: HeadersBuilder
        get() = headersBuilder

    val capturedBody: ByteChannel
        get() = output

    override val headers: ResponseHeaders =
        object : ResponseHeaders() {
            override fun engineAppendHeader(
                name: String,
                value: String,
            ) {
                headersBuilder.append(name, value)
            }

            override fun getEngineHeaderNames(): List<String> = headersBuilder.names().toList()

            override fun getEngineHeaderValues(name: String): List<String> = headersBuilder.getAll(name).orEmpty()
        }

    override fun setStatus(statusCode: HttpStatusCode) {
        this.statusCode = statusCode
    }

    override suspend fun responseChannel(): ByteWriteChannel = output

    override suspend fun respondUpgrade(upgrade: OutgoingContent.ProtocolUpgrade): Unit =
        throw UnsupportedOperationException("Protocol upgrade is not supported on Lambda")
}

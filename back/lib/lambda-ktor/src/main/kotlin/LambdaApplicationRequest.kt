package lambda.ktor

import io.ktor.http.Headers
import io.ktor.http.HeadersBuilder
import io.ktor.http.HttpMethod
import io.ktor.http.Parameters
import io.ktor.http.RequestConnectionPoint
import io.ktor.server.application.PipelineCall
import io.ktor.server.engine.BaseApplicationRequest
import io.ktor.server.request.RequestCookies
import io.ktor.utils.io.ByteReadChannel
import lambda.APIGatewayV2HTTPEvent
import java.util.Base64

internal class LambdaApplicationRequest(
    call: PipelineCall,
    event: APIGatewayV2HTTPEvent,
) : BaseApplicationRequest(call) {
    override val cookies: RequestCookies by lazy { RequestCookies(this) }

    override val engineHeaders: Headers =
        HeadersBuilder()
            .apply {
                for ((name, value) in event.headers) append(name, value)
            }.build()

    override val engineReceiveChannel: ByteReadChannel =
        when (val body = event.body) {
            null -> {
                ByteReadChannel.Empty
            }

            else -> {
                if (event.base64Encoded) {
                    ByteReadChannel(Base64.getDecoder().decode(body))
                } else {
                    ByteReadChannel(body.toByteArray(Charsets.UTF_8))
                }
            }
        }

    override val queryParameters: Parameters = Parameters.Empty

    override val rawQueryParameters: Parameters = Parameters.Empty

    override val local: RequestConnectionPoint =
        LambdaConnectionPoint(
            uri = event.path,
            method = HttpMethod.parse(event.method.name),
            hostHeader =
                event.headers.entries
                    .firstOrNull { it.key.equals("host", ignoreCase = true) }
                    ?.value,
        )
}

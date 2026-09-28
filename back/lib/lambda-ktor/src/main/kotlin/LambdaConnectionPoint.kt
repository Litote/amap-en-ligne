package lambda.ktor

import io.ktor.http.HttpMethod
import io.ktor.http.RequestConnectionPoint
import io.ktor.http.URLProtocol

/**
 * Minimal [RequestConnectionPoint] implementation for synthetic Lambda requests.
 * Only fields that Ktor's routing pipeline reads in practice carry meaningful
 * data; the rest fall back to safe defaults.
 */
internal class LambdaConnectionPoint(
    override val uri: String,
    override val method: HttpMethod,
    private val hostHeader: String?,
) : RequestConnectionPoint {
    override val scheme: String = "https"
    override val version: String = "HTTP/1.1"

    private val defaultPort: Int = URLProtocol.createOrDefault(scheme).defaultPort

    @Deprecated("Use localPort or serverPort instead")
    override val host: String
        get() = hostHeader?.substringBefore(":") ?: "lambda"

    @Deprecated("Use localPort or serverPort instead")
    override val port: Int
        get() = hostHeader?.substringAfter(":", defaultPort.toString())?.toIntOrNull() ?: defaultPort

    override val localPort: Int = defaultPort
    override val serverPort: Int = defaultPort
    override val localHost: String = "lambda"
    override val serverHost: String = hostHeader?.substringBeforeLast(":") ?: "lambda"
    override val localAddress: String = "lambda"
    override val remoteHost: String = "unknown"
    override val remotePort: Int = 0
    override val remoteAddress: String = "unknown"
}

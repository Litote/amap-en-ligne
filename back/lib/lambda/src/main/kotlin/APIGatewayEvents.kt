package lambda

import http.HttpMethod
import http.toHttpMethod
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient

@Serializable
data class APIGatewayV2HTTPEvent(
    val requestContext: APIGatewayV2HTTPEventRequestContext,
    val headers: Map<String, String> = emptyMap(),
    val body: String? = null,
    val pathParameters: Map<String, String> = emptyMap(),
    @SerialName("isBase64Encoded")
    val base64Encoded: Boolean = false,
    @Transient
    val path: String = requestContext.http.path,
    @Transient
    val method: HttpMethod = requestContext.http.method.toHttpMethod(),
) {
    fun getHeaderValue(name: String): String? = headers.getHeaderIgnoreCase(name)
}

@Serializable
data class APIGatewayV2HTTPEventHttp(
    val path: String,
    val method: String = HttpMethod.GET.name,
)

@Serializable
data class APIGatewayV2HTTPEventRequestContext(
    val http: APIGatewayV2HTTPEventHttp,
)

/**
 * Wire-level response for API Gateway v2 (payload format 2.0).
 *
 * [body] is the pre-serialized HTTP body as a string — API Gateway expects
 * a string and extracts it as the HTTP response body. [statusCode] and
 * [headers] are marked [EncodeDefault] so they are always present in the
 * emitted JSON, which is how API Gateway recognises a structured response
 * envelope.
 */
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class APIGatewayV2HTTPResponse(
    @EncodeDefault val statusCode: Int = 200,
    @EncodeDefault val headers: Map<String, String> = emptyMap(),
    val multiValueHeaders: Map<String, List<String>> = emptyMap(),
    val cookies: List<String> = emptyList(),
    val body: String? = null,
    @SerialName("isBase64Encoded")
    val base64Encoded: Boolean = false,
)

private fun Map<String, String>?.getHeaderIgnoreCase(name: String): String? =
    this
        ?.entries
        ?.find {
            it.key.equals(name, ignoreCase = true)
        }?.value

package lambda

import kotlinx.serialization.Serializable
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import serialization.json

class APIGatewayEventsTest {
    @Test
    fun `emits statusCode and headers even when defaults`() {
        val serialized =
            json.encodeToString(
                APIGatewayV2HTTPResponse.serializer(),
                APIGatewayV2HTTPResponse(body = "{\"value\":\"v\"}"),
            )

        assertEquals(
            """{"statusCode":200,"headers":{},"body":"{\"value\":\"v\"}"}""",
            serialized,
        )
    }

    @Test
    fun `serializes response with explicit status headers and string body`() {
        val serialized =
            json.encodeToString(
                APIGatewayV2HTTPResponse.serializer(),
                APIGatewayV2HTTPResponse(
                    statusCode = 200,
                    headers = mapOf("content-type" to "application/json"),
                    body = """[{"value":"v"}]""",
                ),
            )

        assertEquals(
            """{"statusCode":200,"headers":{"content-type":"application/json"},"body":"[{\"value\":\"v\"}]"}""",
            serialized,
        )
    }
}

@Serializable
class TestBody(
    val value: String,
)

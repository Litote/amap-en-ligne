package lambda.ktor

import io.ktor.server.engine.embeddedServer
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.routing
import kotlinx.coroutines.test.runTest
import lambda.APIGatewayV2HTTPEvent
import serialization.json
import kotlin.test.Test
import kotlin.test.assertEquals

class LambdaEngineTest {
    private val server =
        embeddedServer(LambdaEngine) {
            routing {
                get("/echo") {
                    call.respondText(call.request.queryParameters["q"] ?: "<none>")
                }
            }
        }.apply { start(wait = false) }

    @Test
    fun `GIVEN an API Gateway v2 event with a query string WHEN handled THEN query parameters reach the route`() =
        runTest {
            val event =
                json.decodeFromString(
                    APIGatewayV2HTTPEvent.serializer(),
                    """
                    {
                      "version": "2.0",
                      "rawPath": "/echo",
                      "rawQueryString": "q=Ferme%20Bio&other=1",
                      "queryStringParameters": {"q": "Ferme Bio", "other": "1"},
                      "headers": {"host": "example.com"},
                      "requestContext": {"http": {"method": "GET", "path": "/echo"}},
                      "isBase64Encoded": false
                    }
                    """.trimIndent(),
                )

            val response = server.engine.handle(event)

            assertEquals(200, response.statusCode)
            assertEquals("Ferme Bio", response.body)
        }
}

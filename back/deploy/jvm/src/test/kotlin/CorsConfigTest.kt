package deploy.jvm

import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.options
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.response.respond
import io.ktor.server.routing.get
import io.ktor.server.routing.routing
import io.ktor.server.testing.ApplicationTestBuilder
import io.ktor.server.testing.testApplication
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import kotlin.test.assertEquals
import kotlin.test.assertNull

@Execution(ExecutionMode.SAME_THREAD)
internal class CorsConfigTest {
    @BeforeEach
    fun clear() {
        System.clearProperty("CORS_ALLOW_ORIGINS")
    }

    @AfterEach
    fun tearDown() {
        System.clearProperty("CORS_ALLOW_ORIGINS")
    }

    @Test
    fun `GIVEN CORS_ALLOW_ORIGINS unset WHEN preflight THEN no CORS plugin installed`() =
        runTest {
            testApplication {
                application { setupHelloRoute() }

                val response = preflight("http://localhost:3000")

                // No CORS plugin → preflight is not intercepted, response is 405/404 and no headers.
                assertNull(response.headers[HttpHeaders.AccessControlAllowOrigin])
            }
        }

    @Test
    fun `GIVEN CORS_ALLOW_ORIGINS star WHEN preflight from any origin THEN responds with allow`() =
        runTest {
            System.setProperty("CORS_ALLOW_ORIGINS", "*")

            testApplication {
                application {
                    installCorsIfConfigured()
                    setupHelloRoute()
                }

                val response = preflight("http://anywhere.example")

                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals("*", response.headers[HttpHeaders.AccessControlAllowOrigin])
            }
        }

    @Test
    fun `GIVEN CORS_ALLOW_ORIGINS whitelist WHEN preflight from allowed origin THEN responds with that origin`() =
        runTest {
            System.setProperty("CORS_ALLOW_ORIGINS", "https://app.example.com,https://catalog.example.org")

            testApplication {
                application {
                    installCorsIfConfigured()
                    setupHelloRoute()
                }

                val allowed = preflight("https://app.example.com")
                assertEquals(HttpStatusCode.OK, allowed.status)
                assertEquals("https://app.example.com", allowed.headers[HttpHeaders.AccessControlAllowOrigin])

                val forbidden = preflight("https://evil.example")
                assertEquals(HttpStatusCode.Forbidden, forbidden.status)
            }
        }

    @Test
    fun `GIVEN CORS_ALLOW_ORIGINS star WHEN simple GET THEN response carries allow header`() =
        runTest {
            System.setProperty("CORS_ALLOW_ORIGINS", "*")

            testApplication {
                application {
                    installCorsIfConfigured()
                    setupHelloRoute()
                }

                val response =
                    client.get("/hello") {
                        header(HttpHeaders.Origin, "http://anywhere.example")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals("*", response.headers[HttpHeaders.AccessControlAllowOrigin])
            }
        }

    private fun Application.setupHelloRoute() {
        routing {
            get("/hello") {
                call.respond(HttpStatusCode.OK, "hello")
            }
        }
    }

    private suspend fun ApplicationTestBuilder.preflight(origin: String) =
        client.options("/hello") {
            header(HttpHeaders.Origin, origin)
            header(HttpHeaders.AccessControlRequestMethod, "GET")
        }
}

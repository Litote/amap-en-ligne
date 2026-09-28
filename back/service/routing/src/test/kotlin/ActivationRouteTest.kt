package routing

import activation.ActivationOutcome
import activation.ActivationService
import authentication.AuthenticationService
import http.HttpService
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceConfig
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import onboarding.PublicService
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.ActivateResponse
import persistence.model.ActivationKind
import properties.Properties
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
internal class ActivationRouteTest {
    private val activationService = mockk<ActivationService>()

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    private fun startActivationKoin() =
        startKoin {
            modules(
                module {
                    single<DataService> { mockk(relaxed = true) }
                    single<AuthenticationService> { mockk(relaxed = true) }
                    single { HttpService() }
                    single {
                        InstanceConfig(
                            name = "Test Instance",
                            apiUrl = "http://localhost/",
                            visible = true,
                            protocolVersion = "1",
                            serverVersion = "9.9.9-test",
                            auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
                        )
                    }
                    single<PublicService> { mockk(relaxed = true) }
                    single { activationService }
                    single<ProducerAccountSyncDAO> { mockk(relaxed = true) }
                    single<MemberSyncDAO> { mockk(relaxed = true) }
                    single<Properties> { Properties.Instance }
                },
            )
        }

    @Test
    fun `GIVEN a password violating the policy WHEN POST activate THEN 400 WEAK_PASSWORD and no activation`() =
        runTest {
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.post("/v1/activate") {
                        header(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"token":"tok","password":"abcdefgh"}""")
                    }

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertTrue(response.bodyAsText().contains("WEAK_PASSWORD"))
                coVerify(exactly = 0) { activationService.activate(any(), any()) }
            }
        }

    @Test
    fun `GIVEN a password matching the policy WHEN POST activate THEN activation proceeds`() =
        runTest {
            coEvery { activationService.activate("tok", "Str0ngPassword") } returns
                ActivationOutcome.Success(ActivateResponse(kind = ActivationKind.PRODUCER, email = "p@example.com"))
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.post("/v1/activate") {
                        header(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"token":"tok","password":"Str0ngPassword"}""")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
            }
        }

    @Test
    fun `GIVEN a known token WHEN GET activate THEN returns the account being activated`() =
        runTest {
            coEvery { activationService.describe("tok") } returns
                ActivationOutcome.Success(
                    ActivateResponse(kind = ActivationKind.ORGANIZATION_ADMIN, organizationName = "AMAP", email = "a@example.com"),
                )
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/v1/activate?token=tok")

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(response.bodyAsText().contains("a@example.com"))
            }
        }

    @Test
    fun `GIVEN no token WHEN GET activate THEN 400 INVALID_PAYLOAD`() =
        runTest {
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/v1/activate")

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertTrue(response.bodyAsText().contains("INVALID_PAYLOAD"))
            }
        }

    @Test
    fun `GIVEN an unknown token WHEN GET activate THEN 404 with problem details`() =
        runTest {
            coEvery { activationService.describe("nope") } returns ActivationOutcome.NotFound
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/v1/activate?token=nope")

                assertEquals(HttpStatusCode.NotFound, response.status)
                assertTrue(response.bodyAsText().contains("urn:amap-en-ligne:problem:not-found"))
            }
        }

    @Test
    fun `GIVEN an expired token WHEN GET activate THEN 410 with problem details`() =
        runTest {
            coEvery { activationService.describe("old") } returns ActivationOutcome.Expired
            val koin = startActivationKoin()

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/v1/activate?token=old")

                assertEquals(HttpStatusCode.Gone, response.status)
                assertTrue(response.bodyAsText().contains("urn:amap-en-ligne:problem:gone"))
            }
        }
}

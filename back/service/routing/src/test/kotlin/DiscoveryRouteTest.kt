package routing

import activation.ActivationService
import authentication.AuthenticationService
import http.HttpService
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceAuthConfig
import instanceconfig.InstanceAuthConfigSerializers
import instanceconfig.InstanceConfig
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import onboarding.AdminService
import onboarding.PublicService
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import owner.OwnerInvitationService
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import properties.Properties
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
internal class DiscoveryRouteTest {
    private val stubInstanceConfig =
        InstanceConfig(
            name = "Test Instance",
            apiUrl = "http://localhost/",
            visible = true,
            protocolVersion = "1",
            auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
        )

    private val goTrueSerializers =
        InstanceAuthConfigSerializers(
            SerializersModule {
                polymorphic(InstanceAuthConfig::class) {
                    subclass(GoTrueInstanceAuthConfig::class, GoTrueInstanceAuthConfig.serializer())
                }
            },
        )

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `GIVEN GoTrue serializers registered WHEN GET well-known THEN responds with discriminated auth payload`() =
        runTest {
            val koin =
                startKoin {
                    modules(
                        module {
                            single { stubInstanceConfig }
                            single { goTrueSerializers }
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<ActivationService>(relaxed = true) }
                            single { mockk<OwnerInvitationService>(relaxed = true) }
                            single<ProducerAccountSyncDAO> { mockk(relaxed = true) }
                            single<MemberSyncDAO> { mockk(relaxed = true) }
                            single { mockk<owner.OwnerService>(relaxed = true) }
                            single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                            single<Properties> { Properties.Instance }
                        },
                    )
                }

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/.well-known/amap-en-ligne.json")
                val body = response.bodyAsText()

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(body.contains("\"kind\":\"gotrue\""), "Expected kind discriminator in body: $body")
                assertTrue(body.contains("\"base_url\":\"http://localhost/auth\""), "Expected base_url in body: $body")
            }
        }

    @Test
    fun `GIVEN instance config with terms_url WHEN GET well-known THEN response includes terms_url`() =
        runTest {
            val configWithTermsUrl =
                stubInstanceConfig.copy(termsUrl = "https://example.org/cgu")
            val koin =
                startKoin {
                    modules(
                        module {
                            single { configWithTermsUrl }
                            single { goTrueSerializers }
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<ActivationService>(relaxed = true) }
                            single { mockk<OwnerInvitationService>(relaxed = true) }
                            single<ProducerAccountSyncDAO> { mockk(relaxed = true) }
                            single<MemberSyncDAO> { mockk(relaxed = true) }
                            single { mockk<owner.OwnerService>(relaxed = true) }
                            single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                            single<Properties> { Properties.Instance }
                        },
                    )
                }

            testApplication {
                application { dataRoutingModule(koin) }

                val response = client.get("/.well-known/amap-en-ligne.json")
                val body = response.bodyAsText()

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(
                    body.contains("\"terms_url\":\"https://example.org/cgu\""),
                    "Expected terms_url in body: $body",
                )
            }
        }
}

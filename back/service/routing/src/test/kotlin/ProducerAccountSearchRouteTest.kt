package routing

import activation.ActivationService
import authentication.AuthenticatedInfo
import authentication.Authentication
import authentication.AuthenticationService
import authentication.Role
import email.RejectionEmailPort
import http.HttpService
import id.toId
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceConfig
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import memberinvitation.MemberInvitationService
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
import persistence.model.Organization
import properties.Properties
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
@Execution(ExecutionMode.SAME_THREAD)
internal class ProducerAccountSearchRouteTest {
    private val stubInstanceConfig =
        InstanceConfig(
            name = "Test Instance",
            apiUrl = "http://localhost/",
            visible = true,
            protocolVersion = "1",
            auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
        )

    private val adminAuthService =
        object : AuthenticationService {
            override fun getAuthentication(token: String?): Authentication =
                if (token == null) {
                    Authentication.InvalidToken
                } else {
                    Authentication.Success(
                        AuthenticatedInfo(
                            memberId = "admin-member-id",
                            firstName = "Admin",
                            lastName = "User",
                            email = "admin@example.com",
                            organizationId = "org-1",
                            roles = listOf(Role.ADMIN),
                        ),
                    )
                }
        }

    private val nonAdminAuthService =
        object : AuthenticationService {
            override fun getAuthentication(token: String?): Authentication =
                if (token == null) {
                    Authentication.InvalidToken
                } else {
                    Authentication.Success(
                        AuthenticatedInfo(
                            memberId = "producer-member-id",
                            firstName = "Producer",
                            lastName = "User",
                            email = "producer@example.com",
                            organizationId = "org-1",
                            roles = listOf(Role.PRODUCER),
                        ),
                    )
                }
        }

    private fun buildStubProducerAccount(id: String = "pa-1") =
        persistence.model.ProducerAccount(
            producerAccountId = id.toId(),
            name = "Ferme $id",
            contactEmail = "$id@example.com",
            address = null,
            website = null,
            activeStatus = true,
            createdInstant = Instant.fromEpochMilliseconds(1_000_000L),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(2_000_000L),
        )

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `GIVEN admin token and matching query WHEN GET search THEN returns 200 with matching producers`() =
        runTest {
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
            coEvery {
                producerAccountSyncDAO.search("org-1".toId<Organization>(), "ferme")
            } returns listOf(buildStubProducerAccount("pa-1"))

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { adminAuthService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
                            single { mockk<ActivationService>(relaxed = true) }
                            single { mockk<OwnerInvitationService>(relaxed = true) }
                            single { mockk<RejectionEmailPort>(relaxed = true) }
                            single<ProducerAccountSyncDAO> { producerAccountSyncDAO }
                            single<MemberSyncDAO> { mockk(relaxed = true) }
                            single { mockk<owner.OwnerService>(relaxed = true) }
                            single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                            single<Properties> { Properties.Instance }
                        },
                    )
                }

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/producer-accounts/search?q=ferme") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(response.bodyAsText().contains("pa-1"))
            }
        }

    @Test
    fun `GIVEN admin token and blank query WHEN GET search THEN returns 200 with empty list`() =
        runTest {
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { adminAuthService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
                            single { mockk<ActivationService>(relaxed = true) }
                            single { mockk<OwnerInvitationService>(relaxed = true) }
                            single { mockk<RejectionEmailPort>(relaxed = true) }
                            single<ProducerAccountSyncDAO> { producerAccountSyncDAO }
                            single<MemberSyncDAO> { mockk(relaxed = true) }
                            single { mockk<owner.OwnerService>(relaxed = true) }
                            single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                            single<Properties> { Properties.Instance }
                        },
                    )
                }

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/producer-accounts/search") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals("[]", response.bodyAsText())
            }
        }

    @Test
    fun `GIVEN non-admin token WHEN GET search THEN returns 403`() =
        runTest {
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>(relaxed = true)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { nonAdminAuthService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
                            single { mockk<ActivationService>(relaxed = true) }
                            single { mockk<OwnerInvitationService>(relaxed = true) }
                            single { mockk<RejectionEmailPort>(relaxed = true) }
                            single<ProducerAccountSyncDAO> { producerAccountSyncDAO }
                            single<MemberSyncDAO> { mockk(relaxed = true) }
                            single { mockk<owner.OwnerService>(relaxed = true) }
                            single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                            single<Properties> { Properties.Instance }
                        },
                    )
                }

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/producer-accounts/search?q=ferme") {
                        header(HttpHeaders.Authorization, "Bearer producer-token")
                    }

                assertEquals(HttpStatusCode.Forbidden, response.status)
                assertTrue(response.bodyAsText().contains("FORBIDDEN"))
            }
        }
}

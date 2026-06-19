package routing

import activation.ActivationService
import authentication.AuthenticationService
import http.HttpService
import id.toId
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceConfig
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import onboarding.AdminService
import onboarding.CreateMemberJoinOutcome
import onboarding.CreateOrganizationOutcome
import onboarding.CreateProducerOutcome
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
import persistence.model.MemberJoinRequestCreated
import persistence.model.MemberJoinRequestStatus
import persistence.model.OrganizationRequestCreated
import persistence.model.OrganizationRequestStatus
import persistence.model.ProducerRequestCreated
import persistence.model.ProducerRequestStatus
import persistence.model.PublicOrganizationSummary
import persistence.model.Server
import properties.Properties
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
internal class PublicRouteTest {
    private val stubInstanceConfig =
        InstanceConfig(
            name = "Test Instance",
            apiUrl = "http://localhost/",
            visible = true,
            protocolVersion = "1",
            auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
        )

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `GIVEN active organizations WHEN GET v1 public organizations THEN returns 200 with list`() =
        runTest {
            val publicService = mockk<PublicService>()
            val orgs =
                listOf(
                    PublicOrganizationSummary(
                        organizationId = "org-1".toId(),
                        name = "AMAP des Collines",
                        contactEmail = "collines@example.com",
                        activeStatus = true,
                    ),
                )
            coEvery { publicService.listActiveOrganizations() } returns orgs

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response = client.get("/v1/public/organizations")

                assertEquals(HttpStatusCode.OK, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("org-1"))
                assertTrue(body.contains("AMAP des Collines"))
            }
        }

    @Test
    fun `GIVEN known servers WHEN GET v1 public servers THEN returns 200 with list`() =
        runTest {
            val publicService = mockk<PublicService>()
            val servers =
                listOf(
                    Server(
                        serverId = "srv-1".toId(),
                        name = "AMAP Île-de-France",
                        url = "https://idf.amap-en-ligne.org/",
                    ),
                )
            coEvery { publicService.listServers() } returns servers

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response = client.get("/v1/public/servers")

                assertEquals(HttpStatusCode.OK, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("srv-1"))
                assertTrue(body.contains("AMAP Île-de-France"))
            }
        }

    @Test
    fun `GIVEN no organizations WHEN GET v1 public organizations THEN returns 200 with empty list`() =
        runTest {
            val publicService = mockk<PublicService>()
            coEvery { publicService.listActiveOrganizations() } returns emptyList()

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response = client.get("/v1/public/organizations")

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(response.bodyAsText().contains("[]"))
            }
        }

    @Test
    fun `GIVEN valid body WHEN POST v1 organization-requests THEN returns 201 with request id`() =
        runTest {
            val publicService = mockk<PublicService>()
            val createdResult = OrganizationRequestCreated("req-1".toId(), OrganizationRequestStatus.PENDING_VALIDATION)
            coEvery { publicService.createOrganizationRequest(any()) } returns CreateOrganizationOutcome.Success(createdResult)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/organization-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "organization_name": "AMAP des Collines",
                              "organization_type": "AMAP",
                              "timezone": "Europe/Paris",
                              "default_language": "fr",
                              "admin_first_name": "Jean",
                              "admin_last_name": "Dupont",
                              "admin_email": "jean@example.com"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Created, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("req-1"))
                assertTrue(body.contains("PENDING_VALIDATION"))
            }
        }

    @Test
    fun `GIVEN duplicate organization name WHEN POST v1 organization-requests THEN returns 409`() =
        runTest {
            val publicService = mockk<PublicService>()
            coEvery { publicService.createOrganizationRequest(any()) } returns
                CreateOrganizationOutcome.Conflict("organization_name", OrganizationRequestStatus.PENDING_VALIDATION)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/organization-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "organization_name": "AMAP des Collines",
                              "organization_type": "AMAP",
                              "timezone": "Europe/Paris",
                              "default_language": "fr",
                              "admin_first_name": "Jean",
                              "admin_last_name": "Dupont",
                              "admin_email": "jean@example.com"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Conflict, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("CONFLICT"))
                assertTrue(body.contains("organization_name"))
                assertTrue(body.contains("PENDING_VALIDATION"))
            }
        }

    @Test
    fun `GIVEN valid body WHEN POST v1 producer-requests THEN returns 201 with request id`() =
        runTest {
            val publicService = mockk<PublicService>()
            val created = ProducerRequestCreated("preq-1".toId(), ProducerRequestStatus.PENDING_VALIDATION)
            coEvery { publicService.createProducerRequest(any()) } returns CreateProducerOutcome.Success(created)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/producer-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "producer_name": "Ferme des Collines",
                              "admin_first_name": "Jean",
                              "admin_last_name": "Dupont",
                              "admin_email": "jean@example.com"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Created, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("preq-1"))
                assertTrue(body.contains("PENDING_VALIDATION"))
            }
        }

    @Test
    fun `GIVEN duplicate producer name WHEN POST v1 producer-requests THEN returns 409`() =
        runTest {
            val publicService = mockk<PublicService>()
            coEvery { publicService.createProducerRequest(any()) } returns
                CreateProducerOutcome.Conflict("producer_name", ProducerRequestStatus.PENDING_VALIDATION)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/producer-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "producer_name": "Ferme des Collines",
                              "admin_first_name": "Jean",
                              "admin_last_name": "Dupont",
                              "admin_email": "jean@example.com"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Conflict, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("CONFLICT"))
                assertTrue(body.contains("producer_name"))
                assertTrue(body.contains("PENDING_VALIDATION"))
            }
        }

    @Test
    fun `GIVEN valid body WHEN POST v1 public member-join-requests THEN returns 201 with request id`() =
        runTest {
            val publicService = mockk<PublicService>()
            val created = MemberJoinRequestCreated("mjreq-1".toId(), MemberJoinRequestStatus.PENDING)
            coEvery { publicService.createMemberJoinRequest(any()) } returns CreateMemberJoinOutcome.Success(created)

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/public/member-join-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "organization_id": "org-1",
                              "email": "alice@example.com",
                              "first_name": "Alice",
                              "last_name": "Martin"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Created, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("mjreq-1"))
                assertTrue(body.contains("PENDING"))
            }
        }

    @Test
    fun `GIVEN duplicate email for same org WHEN POST v1 public member-join-requests THEN returns 409`() =
        runTest {
            val publicService = mockk<PublicService>()
            coEvery { publicService.createMemberJoinRequest(any()) } returns CreateMemberJoinOutcome.Conflict("email")

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { mockk(relaxed = true) }
                            single<AuthenticationService> { mockk(relaxed = true) }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { publicService }
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

                val response =
                    client.post("/v1/public/member-join-requests") {
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(
                            """
                            {
                              "organization_id": "org-1",
                              "email": "alice@example.com",
                              "first_name": "Alice",
                              "last_name": "Martin"
                            }
                            """.trimIndent(),
                        )
                    }

                assertEquals(HttpStatusCode.Conflict, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("CONFLICT"))
                assertTrue(body.contains("email"))
            }
        }
}

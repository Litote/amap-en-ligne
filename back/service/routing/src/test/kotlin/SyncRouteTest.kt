package routing

import activation.ActivationService
import authentication.AuthenticatedInfo
import authentication.Authentication
import authentication.AuthenticationService
import authentication.Role
import http.HttpService
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceConfig
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
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
import persistence.changes.SyncResponse
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import properties.Properties
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@Execution(ExecutionMode.SAME_THREAD)
internal class SyncRouteTest {
    private val stubInstanceConfig =
        InstanceConfig(
            name = "Test Instance",
            apiUrl = "http://localhost/",
            visible = true,
            protocolVersion = "1",
            auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
        )

    // Stub that mimics the legacy "any token is valid" behaviour the existing tests were written
    // against. Real auth providers (Cognito, GoTrue) are tested in their own module.
    // After sub/id unification: uses Role.PRODUCER so the routing check passes.
    private val stubAuthenticationService =
        object : AuthenticationService {
            override fun getAuthentication(token: String?): Authentication =
                if (token == null) {
                    Authentication.InvalidToken
                } else {
                    Authentication.Success(
                        AuthenticatedInfo(
                            memberId = "memberId",
                            firstName = "First",
                            lastName = "Last",
                            email = "test@example.com",
                            producerAccountId = "producerAccountId",
                            roles = listOf(Role.PRODUCER),
                        ),
                    )
                }
        }

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `GIVEN valid token WHEN POST v1 sync THEN delegates to DataService and returns 200`() =
        runTest {
            val dataService = mockk<DataService>()
            val expected = SyncResponse(authorizedScopes = emptyList(), results = emptyMap(), mutations = emptyList())
            val authInfoSlot = slot<AuthenticatedInfo>()
            coEvery { dataService.sync(capture(authInfoSlot), any(), any()) } returns expected

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single<AuthenticationService> { stubAuthenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer test-token")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"cursors":{},"mutations":[]}""")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("\"authorized_scopes\""))
                assertTrue(body.contains("\"results\""))
                assertEquals("producerAccountId", authInfoSlot.captured.producerAccountId)
                coVerify(exactly = 1) { dataService.sync(any(), any(), any()) }
            }
        }

    @Test
    fun `GIVEN user without producerAccountId or organizationId and no OWNER role WHEN POST v1 sync THEN responds 403`() =
        runTest {
            val dataService = mockk<DataService>()
            val authenticationService =
                object : AuthenticationService {
                    override fun getAuthentication(token: String?): Authentication =
                        if (token == null) {
                            Authentication.InvalidToken
                        } else {
                            Authentication.Success(
                                AuthenticatedInfo(
                                    memberId = "memberId",
                                    firstName = "Member",
                                    lastName = "User",
                                    email = "member@example.com",
                                    producerAccountId = null,
                                    organizationId = null,
                                ),
                            )
                        }
                }

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single<AuthenticationService> { authenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer test-token")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"cursors":{},"mutations":[]}""")
                    }

                assertEquals(HttpStatusCode.Forbidden, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("FORBIDDEN"))
                coVerify(exactly = 0) { dataService.sync(any(), any(), any()) }
            }
        }

    @Test
    fun `GIVEN user without producerAccountId or organizationId but with OWNER role WHEN POST v1 sync THEN responds 200 with empty data`() =
        runTest {
            val dataService = mockk<DataService>()
            val emptyResponse = SyncResponse(authorizedScopes = emptyList(), results = emptyMap(), mutations = emptyList())
            coEvery { dataService.sync(any(), any(), any()) } returns emptyResponse
            val authenticationService =
                object : AuthenticationService {
                    override fun getAuthentication(token: String?): Authentication =
                        if (token == null) {
                            Authentication.InvalidToken
                        } else {
                            Authentication.Success(
                                AuthenticatedInfo(
                                    memberId = "memberId",
                                    firstName = "Owner",
                                    lastName = "User",
                                    email = "owner@example.com",
                                    producerAccountId = null,
                                    organizationId = null,
                                    roles = listOf(Role.OWNER),
                                ),
                            )
                        }
                }

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single<AuthenticationService> { authenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer test-token")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"cursors":{},"mutations":[]}""")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                coVerify(exactly = 1) { dataService.sync(any(), any(), any()) }
            }
        }

    @Test
    fun `GIVEN user with ADMIN role but no organizationId in JWT WHEN POST v1 sync THEN delegates to DataService`() =
        runTest {
            // After sub/id unification: JWT no longer carries organizationId/producerAccountId;
            // scope resolution is done by AuthorizedScopeResolver via DB lookup.
            // The routing layer only blocks callers with NO roles at all.
            val emptyResponse = SyncResponse(authorizedScopes = emptyList(), results = emptyMap(), mutations = emptyList())
            val dataService = mockk<DataService>()
            coEvery { dataService.sync(any(), any(), any()) } returns emptyResponse
            val authenticationService =
                object : AuthenticationService {
                    override fun getAuthentication(token: String?): Authentication =
                        if (token == null) {
                            Authentication.InvalidToken
                        } else {
                            Authentication.Success(
                                AuthenticatedInfo(
                                    memberId = "memberId",
                                    firstName = "Admin",
                                    lastName = "User",
                                    email = "admin@example.com",
                                    producerAccountId = null,
                                    organizationId = null,
                                    roles = listOf(Role.ADMIN),
                                ),
                            )
                        }
                }

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single<AuthenticationService> { authenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer test-token")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"cursors":{},"mutations":[]}""")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                coVerify(exactly = 1) { dataService.sync(any(), any(), any()) }
            }
        }

    @Test
    fun `GIVEN mutations list exceeding MAX_MUTATIONS_PER_SYNC WHEN POST v1 sync THEN responds 400 and skips DataService`() =
        runTest {
            val dataService = mockk<DataService>()

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single<AuthenticationService> { stubAuthenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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

            // Build a JSON body with 501 minimal delete mutations (above the 500-mutation limit)
            val tooManyMutations =
                (1..501)
                    .joinToString(",") { i ->
                        """{"client_op_id":"op-$i","op":{"type":"Delete","entity_type":"ErrorReport","entity_id":"id-$i"}}"""
                    }
            val body = """{"cursors":{},"mutations":[$tooManyMutations]}"""

            testApplication {
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer test-token")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody(body)
                    }

                assertEquals(HttpStatusCode.BadRequest, response.status)
                val responseBody = response.bodyAsText()
                assertTrue(responseBody.contains("MUTATION_BATCH_TOO_LARGE"))
                coVerify(exactly = 0) { dataService.sync(any(), any(), any()) }
            }
        }

    @Test
    fun `GIVEN expired token WHEN POST v1 sync THEN responds 401 and skips DataService`() =
        runTest {
            val dataService = mockk<DataService>()
            val authenticationService = mockk<AuthenticationService>()
            every { authenticationService.isUnauthenticatedPath(any()) } returns false
            every { authenticationService.getAuthentication(any()) } returns Authentication.ExpiredToken

            val koin =
                startKoin {
                    modules(
                        module {
                            single<DataService> { dataService }
                            single { authenticationService }
                            single { HttpService() }
                            single { stubInstanceConfig }
                            single { mockk<PublicService>(relaxed = true) }
                            single { mockk<AdminService>(relaxed = true) }
                            single { mockk<MemberInvitationService>(relaxed = true) }
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
                application {
                    dataRoutingModule(koin)
                }

                val response =
                    client.post("/v1/sync") {
                        headers.append(HttpHeaders.Authorization, "Bearer expired")
                        headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                        setBody("""{"cursors":{},"mutations":[]}""")
                    }

                assertEquals(HttpStatusCode.Unauthorized, response.status)
                val body = response.bodyAsText()
                assertTrue(body.contains("EXPIRED_AUTH_TOKEN"))
                coVerify(exactly = 0) { dataService.sync(any(), any(), any()) }
            }
        }
}

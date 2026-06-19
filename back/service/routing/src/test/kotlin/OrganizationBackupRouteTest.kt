@file:OptIn(kotlin.time.ExperimentalTime::class)

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
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
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
import persistence.changes.OrganizationExport
import persistence.changes.OrganizationExportScopes
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import properties.Properties
import sync.DataService
import sync.ExportOutcome
import sync.ExportService
import sync.ImportOutcome
import sync.ImportResult
import sync.ImportService
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
internal class OrganizationBackupRouteTest {
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

    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    private fun startTestKoin(
        exportService: ExportService,
        importService: ImportService = mockk(relaxed = true),
    ) = startKoin {
        modules(
            module {
                single<DataService> { mockk(relaxed = true) }
                single<ExportService> { exportService }
                single<ImportService> { importService }
                single<AuthenticationService> { adminAuthService }
                single { HttpService() }
                single { stubInstanceConfig }
                single { mockk<PublicService>(relaxed = true) }
                single { mockk<AdminService>(relaxed = true) }
                single { mockk<MemberInvitationService>(relaxed = true) }
                single { mockk<ActivationService>(relaxed = true) }
                single { mockk<OwnerInvitationService>(relaxed = true) }
                single { mockk<RejectionEmailPort>(relaxed = true) }
                single<ProducerAccountSyncDAO> { mockk(relaxed = true) }
                single<MemberSyncDAO> { mockk(relaxed = true) }
                single { mockk<owner.OwnerService>(relaxed = true) }
                single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                single<Properties> { Properties.Instance }
            },
        )
    }

    @Test
    fun `GIVEN export success WHEN GET export THEN returns 200 with archive`() =
        runTest {
            val exportService = mockk<ExportService>()
            coEvery { exportService.exportOrganization(any(), "org-1", "Test Instance") } returns
                ExportOutcome.Success(
                    OrganizationExport(
                        formatVersion = OrganizationExport.CURRENT_FORMAT_VERSION,
                        exportedAt = Instant.fromEpochMilliseconds(1_000L),
                        sourceInstance = "Test Instance",
                        organizationId = "org-1",
                        scopes = OrganizationExportScopes(organization = emptyList(), productTypes = emptyList()),
                    ),
                )
            val koin = startTestKoin(exportService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/organizations/org-1/export") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(response.bodyAsText().contains("\"organization_id\":\"org-1\""))
                assertTrue(response.bodyAsText().contains("\"format_version\":1"))
            }
        }

    @Test
    fun `GIVEN export forbidden WHEN GET export THEN returns 403`() =
        runTest {
            val exportService = mockk<ExportService>()
            coEvery { exportService.exportOrganization(any(), any(), any()) } returns ExportOutcome.Forbidden
            val koin = startTestKoin(exportService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/organizations/org-1/export") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                    }

                assertEquals(HttpStatusCode.Forbidden, response.status)
                assertTrue(response.bodyAsText().contains("FORBIDDEN"))
            }
        }

    @Test
    fun `GIVEN export not found WHEN GET export THEN returns 404`() =
        runTest {
            val exportService = mockk<ExportService>()
            coEvery { exportService.exportOrganization(any(), any(), any()) } returns ExportOutcome.NotFound
            val koin = startTestKoin(exportService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.get("/v1/admin/organizations/unknown/export") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                    }

                assertEquals(HttpStatusCode.NotFound, response.status)
                assertTrue(response.bodyAsText().contains("NOT_FOUND"))
            }
        }

    private val emptyArchiveBody =
        """{"format_version":1,"exported_at":"1970-01-01T00:00:01Z","organization_id":"src-org",""" +
            """"scopes":{"organization":[]}}"""

    @Test
    fun `GIVEN import success WHEN POST import THEN returns 200 with result`() =
        runTest {
            val importService = mockk<ImportService>()
            coEvery { importService.importIntoOrganization(any(), "org-1", any()) } returns
                ImportOutcome.Success(
                    ImportResult(
                        organizationId = "org-1",
                        productTypes = 0,
                        producerAccounts = 0,
                        deliveryTemplates = 0,
                        members = 3,
                        contracts = 0,
                        organizations = 1,
                        memberInvitations = 0,
                        skippedInvitations = 0,
                        memberJoinRequests = 0,
                        basketExchanges = 0,
                    ),
                )
            val koin = startTestKoin(mockk(relaxed = true), importService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.post("/v1/admin/organizations/org-1/import") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                        contentType(ContentType.Application.Json)
                        setBody(emptyArchiveBody)
                    }

                assertEquals(HttpStatusCode.OK, response.status)
                assertTrue(response.bodyAsText().contains("\"members\":3"))
            }
        }

    @Test
    fun `GIVEN non-empty target WHEN POST import THEN returns 409`() =
        runTest {
            val importService = mockk<ImportService>()
            coEvery { importService.importIntoOrganization(any(), any(), any()) } returns
                ImportOutcome.Conflict("target organization already has members")
            val koin = startTestKoin(mockk(relaxed = true), importService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.post("/v1/admin/organizations/org-1/import") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                        contentType(ContentType.Application.Json)
                        setBody(emptyArchiveBody)
                    }

                assertEquals(HttpStatusCode.Conflict, response.status)
                assertTrue(response.bodyAsText().contains("CONFLICT"))
            }
        }

    @Test
    fun `GIVEN unsupported format version WHEN POST import THEN returns 400`() =
        runTest {
            val importService = mockk<ImportService>()
            coEvery { importService.importIntoOrganization(any(), any(), any()) } returns
                ImportOutcome.InvalidFormat("unsupported format_version 999")
            val koin = startTestKoin(mockk(relaxed = true), importService)

            testApplication {
                application { dataRoutingModule(koin) }

                val response =
                    client.post("/v1/admin/organizations/org-1/import") {
                        header(HttpHeaders.Authorization, "Bearer admin-token")
                        contentType(ContentType.Application.Json)
                        setBody(emptyArchiveBody)
                    }

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertTrue(response.bodyAsText().contains("INVALID_PAYLOAD"))
            }
        }
}

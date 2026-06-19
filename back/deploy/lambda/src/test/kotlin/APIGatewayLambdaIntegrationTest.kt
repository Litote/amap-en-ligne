package deploy.lambda

import activation.ActivationService
import authentication.AuthenticatedInfo
import authentication.Authentication
import authentication.AuthenticationService
import authentication.Role
import core.UserProvisioningPort
import email.MemberInvitationEmailPort
import email.MemberJoinRequestNotificationEmailPort
import email.OwnerActivationEmailPort
import http.HttpService
import id.Id
import instanceconfig.GoTrueInstanceAuthConfig
import instanceconfig.InstanceConfig
import io.mockk.coEvery
import io.mockk.mockk
import lambda.APIGatewayV2HTTPEvent
import lambda.APIGatewayV2HTTPEventHttp
import lambda.APIGatewayV2HTTPEventRequestContext
import lambda.APIGatewayV2HTTPResponse
import lambda.ktor.APIGatewayLambdaBase
import memberinvitation.MemberInvitationService
import notificationpublisher.NotificationPublisher
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
import persistence.dao.ActivationTokenDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.dao.ProducerSyncDAO
import persistence.dao.ServerDAO
import persistence.model.AccountStatus
import persistence.model.ActivationToken
import persistence.model.MemberInvitation
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OwnerInvitation
import persistence.model.ProducerAccount
import persistence.model.ProducerRequestStatus
import persistence.model.PublicOrganizationSummary
import persistence.model.Server
import properties.Properties
import routing.dataRoutingModule
import serialization.json
import sync.DataService
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
internal class APIGatewayLambdaIntegrationTest {
    @AfterEach
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `GIVEN POST v1 sync event WHEN handleRequest THEN returns 200 V2 envelope with SyncResponse body`() {
        val dataService = mockk<DataService>()
        val expected = SyncResponse(authorizedScopes = emptyList(), results = emptyMap(), mutations = emptyList())
        coEvery { dataService.sync(any(), any(), any()) } returns expected

        val stubOrganizationRequestDAO =
            @OptIn(ExperimentalTime::class)
            object : OrganizationRequestDAO {
                override suspend fun create(request: OrganizationRequest) = Unit

                override suspend fun existsByOrganizationName(
                    name: String,
                    excludedStatuses: Set<OrganizationRequestStatus>,
                ): OrganizationRequestStatus? = null

                override suspend fun existsByAdminEmail(
                    email: String,
                    excludedStatuses: Set<OrganizationRequestStatus>,
                ): OrganizationRequestStatus? = null

                override suspend fun listAll(): List<OrganizationRequest> = emptyList()

                override suspend fun listByStatus(status: OrganizationRequestStatus): List<OrganizationRequest> = emptyList()

                override suspend fun findById(requestId: Id<OrganizationRequest>): OrganizationRequest? = null

                override suspend fun updateStatus(
                    requestId: Id<OrganizationRequest>,
                    status: OrganizationRequestStatus,
                    reviewedAt: Instant,
                    reviewComment: String?,
                ) = Unit
            }

        val koin =
            startKoin {
                modules(
                    module {
                        single<DataService> { dataService }
                        single { mockk<owner.OwnerService>(relaxed = true) }
                        single { mockk<produceraccount.ProducerAccountService>(relaxed = true) }
                        single<Properties> { Properties.Instance }
                        single<AuthenticationService> {
                            object : AuthenticationService {
                                override fun getAuthentication(token: String?): Authentication =
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
                        single { HttpService() }
                        single {
                            InstanceConfig(
                                name = "Test Instance",
                                apiUrl = "http://localhost/",
                                visible = true,
                                protocolVersion = "1",
                                auth = GoTrueInstanceAuthConfig(baseUrl = "http://localhost/auth"),
                            )
                        }
                        single {
                            PublicService(
                                object : OrganizationDAO {
                                    override suspend fun listActive(): List<PublicOrganizationSummary> = emptyList()

                                    override suspend fun create(organization: Organization) = Unit
                                },
                                object : ServerDAO {
                                    override suspend fun list(): List<Server> = emptyList()
                                },
                                stubOrganizationRequestDAO,
                                object : OrganizationRequestSyncDAO {
                                    override suspend fun listAll(): List<OrganizationRequest> = emptyList()

                                    override suspend fun put(
                                        request: OrganizationRequest,
                                        change: persistence.changes.Change,
                                    ) = Unit
                                },
                                object : ProducerRequestDAO {
                                    override suspend fun create(request: persistence.model.ProducerRequest) = Unit

                                    override suspend fun existsByProducerName(
                                        name: String,
                                        excludedStatuses: Set<persistence.model.ProducerRequestStatus>,
                                    ): ProducerRequestStatus? = null

                                    override suspend fun existsByAdminEmail(
                                        email: String,
                                        excludedStatuses: Set<persistence.model.ProducerRequestStatus>,
                                    ): ProducerRequestStatus? = null

                                    override suspend fun listAll(): List<persistence.model.ProducerRequest> = emptyList()

                                    override suspend fun listByStatus(
                                        status: persistence.model.ProducerRequestStatus,
                                    ): List<persistence.model.ProducerRequest> = emptyList()

                                    override suspend fun findById(
                                        requestId: id.Id<persistence.model.ProducerRequest>,
                                    ): persistence.model.ProducerRequest? = null

                                    override suspend fun updateStatus(
                                        requestId: id.Id<persistence.model.ProducerRequest>,
                                        status: persistence.model.ProducerRequestStatus,
                                        reviewedAt: Instant,
                                        reviewComment: String?,
                                    ) = Unit
                                },
                                object : ProducerRequestSyncDAO {
                                    override suspend fun listAll(): List<persistence.model.ProducerRequest> = emptyList()

                                    override suspend fun put(
                                        request: persistence.model.ProducerRequest,
                                        change: persistence.changes.Change,
                                    ) = Unit
                                },
                                object : MemberJoinRequestDAO {
                                    override suspend fun create(request: MemberJoinRequest) = Unit

                                    override suspend fun existsPendingByEmailAndOrganization(
                                        email: String,
                                        organizationId: id.Id<Organization>,
                                    ): Boolean = false

                                    override suspend fun listByOrganization(organizationId: id.Id<Organization>): List<MemberJoinRequest> =
                                        emptyList()

                                    override suspend fun listByOrganizationAndStatus(
                                        organizationId: id.Id<Organization>,
                                        status: MemberJoinRequestStatus,
                                    ): List<MemberJoinRequest> = emptyList()

                                    override suspend fun findById(requestId: id.Id<MemberJoinRequest>): MemberJoinRequest? = null

                                    override suspend fun updateStatus(
                                        requestId: id.Id<MemberJoinRequest>,
                                        status: MemberJoinRequestStatus,
                                        reviewedAt: kotlin.time.Instant,
                                        reviewComment: String?,
                                    ) = Unit
                                },
                                object : MemberJoinRequestSyncDAO {
                                    override suspend fun listByOrganizationId(
                                        organizationId: id.Id<Organization>,
                                    ): List<MemberJoinRequest> = emptyList()

                                    override suspend fun put(
                                        request: MemberJoinRequest,
                                        change: persistence.changes.Change,
                                    ) = Unit
                                },
                                object : MemberJoinRequestNotificationEmailPort {
                                    override suspend fun notifyAdmins(
                                        request: MemberJoinRequest,
                                        organizationName: String?,
                                    ) = Unit
                                },
                                object : email.OrganizationRequestNotificationEmailPort {
                                    override suspend fun notifyOwners(request: persistence.model.OrganizationRequest) = Unit
                                },
                                object : email.ProducerRequestNotificationEmailPort {
                                    override suspend fun notifyOwners(request: persistence.model.ProducerRequest) = Unit
                                },
                                mockk<NotificationPublisher>(relaxed = true),
                                mockk<OwnerSyncDAO>(relaxed = true),
                                mockk<MemberSyncDAO>(relaxed = true),
                                mockk<ProducerAccountSyncDAO>(relaxed = true),
                                mockk<OrganizationSyncDAO>(relaxed = true),
                            )
                        }
                        single {
                            AdminService(
                                object : MemberJoinRequestDAO {
                                    override suspend fun create(request: MemberJoinRequest) = Unit

                                    override suspend fun existsPendingByEmailAndOrganization(
                                        email: String,
                                        organizationId: id.Id<Organization>,
                                    ): Boolean = false

                                    override suspend fun listByOrganization(organizationId: id.Id<Organization>): List<MemberJoinRequest> =
                                        emptyList()

                                    override suspend fun listByOrganizationAndStatus(
                                        organizationId: id.Id<Organization>,
                                        status: MemberJoinRequestStatus,
                                    ): List<MemberJoinRequest> = emptyList()

                                    override suspend fun findById(requestId: id.Id<MemberJoinRequest>): MemberJoinRequest? = null

                                    override suspend fun updateStatus(
                                        requestId: id.Id<MemberJoinRequest>,
                                        status: MemberJoinRequestStatus,
                                        reviewedAt: Instant,
                                        reviewComment: String?,
                                    ) = Unit
                                },
                            )
                        }
                        single {
                            MemberInvitationService(
                                object : MemberInvitationSyncDAO {
                                    override suspend fun put(
                                        invitation: MemberInvitation,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun findById(invitationId: String): MemberInvitation? = null

                                    override suspend fun listByOrganizationId(organizationId: id.Id<Organization>): List<MemberInvitation> =
                                        emptyList()

                                    override suspend fun findPendingByEmail(email: String): MemberInvitation? = null
                                },
                                mockk<MemberSyncDAO>(relaxed = true),
                                mockk<ActivationTokenDAO>(relaxed = true),
                                object : MemberInvitationEmailPort {
                                    override suspend fun sendInvitationEmail(
                                        invitation: MemberInvitation,
                                        token: ActivationToken,
                                        organizationName: String?,
                                    ) = Unit
                                },
                                mockk<OrganizationSyncDAO>(relaxed = true),
                                mockk<persistence.dao.OwnerSyncDAO>(relaxed = true),
                            )
                        }
                        single<ProducerAccountSyncDAO> {
                            object : ProducerAccountSyncDAO {
                                override suspend fun getByOrganizationId(organizationId: id.Id<Organization>): List<ProducerAccount> =
                                    emptyList()

                                override suspend fun listAll(): List<ProducerAccount> = emptyList()

                                override suspend fun findById(producerAccountId: id.Id<ProducerAccount>): ProducerAccount? = null

                                override suspend fun updateActiveStatus(
                                    producerAccountId: id.Id<ProducerAccount>,
                                    activeStatus: Boolean,
                                    changes: List<persistence.changes.Change>,
                                ) = Unit

                                override suspend fun put(
                                    producerAccount: ProducerAccount,
                                    organizationId: id.Id<Organization>,
                                    changes: List<persistence.changes.Change>,
                                ) = Unit

                                override suspend fun delete(
                                    producerAccountId: id.Id<ProducerAccount>,
                                    organizationId: id.Id<Organization>,
                                    changes: List<persistence.changes.Change>,
                                ) = Unit

                                override suspend fun createInitial(
                                    producerAccount: ProducerAccount,
                                    organizationId: id.Id<Organization>,
                                ) = Unit

                                override suspend fun createStandalone(producerAccount: ProducerAccount) = Unit

                                override suspend fun updateProfile(
                                    producerAccount: ProducerAccount,
                                    changes: List<persistence.changes.Change>,
                                ) = Unit

                                override suspend fun search(
                                    organizationId: id.Id<Organization>,
                                    query: String,
                                ): List<ProducerAccount> = emptyList()
                            }
                        }
                        single {
                            ActivationService(
                                object : ActivationTokenDAO {
                                    override suspend fun create(token: ActivationToken) = Unit

                                    override suspend fun findByToken(token: String): ActivationToken? = null

                                    override suspend fun markActivated(
                                        token: String,
                                        activatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByOwnerInvitationId(
                                        invitationId: id.Id<OwnerInvitation>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByMemberInvitationId(
                                        invitationId: id.Id<MemberInvitation>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByOrganizationRequestId(
                                        requestId: id.Id<persistence.model.OrganizationRequest>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByProducerRequestId(
                                        requestId: id.Id<persistence.model.ProducerRequest>,
                                        invalidatedAt: Instant,
                                    ) = Unit
                                },
                                stubOrganizationRequestDAO,
                                mockk<ProducerRequestDAO>(relaxed = true),
                                mockk<OrganizationSyncDAO>(relaxed = true),
                                mockk<ServerDAO>(relaxed = true),
                                get<ProducerAccountSyncDAO>(),
                                mockk<ProducerSyncDAO>(relaxed = true),
                                object : UserProvisioningPort {
                                    override suspend fun createAdminUser(
                                        email: String,
                                        password: String,
                                    ) = "stub-admin-sub"

                                    override suspend fun createOwnerUser(
                                        email: String,
                                        password: String,
                                        firstName: String,
                                        lastName: String,
                                    ): String = "stub-sub"

                                    override suspend fun createProducerUser(
                                        email: String,
                                        password: String,
                                        firstName: String,
                                        lastName: String,
                                    ): String = "stub-producer-sub"

                                    override suspend fun createMemberUser(
                                        email: String,
                                        password: String,
                                        firstName: String,
                                        lastName: String,
                                        organizationId: String,
                                        roles: Set<Role>,
                                    ): String = "stub-sub"

                                    override suspend fun banUser(sub: String) = Unit

                                    override suspend fun unbanUser(sub: String) = Unit

                                    override suspend fun deleteUser(sub: String) = Unit

                                    override suspend fun findProducerAccountIdByEmail(email: String): String? = null

                                    override suspend fun listAuthSubsByProducerAccount(producerAccountId: String): List<String> =
                                        emptyList()
                                },
                                mockk<MemberInvitationSyncDAO>(relaxed = true),
                                mockk<MemberSyncDAO>(relaxed = true),
                                object : OwnerInvitationSyncDAO {
                                    override suspend fun listAll(): List<OwnerInvitation> = emptyList()

                                    override suspend fun put(
                                        invitation: OwnerInvitation,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun findById(invitationId: id.Id<OwnerInvitation>): OwnerInvitation? = null

                                    override suspend fun existsPendingByEmail(email: String): Boolean = false
                                },
                                object : OwnerSyncDAO {
                                    override suspend fun listAll() = emptyList<persistence.model.Owner>()

                                    override suspend fun findById(ownerId: id.Id<persistence.model.Owner>) = null

                                    override suspend fun findBySub(sub: String): persistence.model.Owner? = null

                                    override suspend fun put(
                                        owner: persistence.model.Owner,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun updateStatus(
                                        ownerId: id.Id<persistence.model.Owner>,
                                        accountStatus: AccountStatus,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun existsByEmail(email: String) = false

                                    override suspend fun existsBySub(sub: String) = false

                                    override suspend fun delete(
                                        ownerId: id.Id<persistence.model.Owner>,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun promoteToOwner(
                                        owner: persistence.model.Owner,
                                        ownerChange: persistence.changes.Change,
                                        membersToRevoke: List<persistence.model.Member>,
                                        memberChanges: List<persistence.changes.Change>,
                                    ) = Unit
                                },
                            )
                        }
                        single {
                            OwnerInvitationService(
                                object : OwnerInvitationSyncDAO {
                                    override suspend fun listAll(): List<OwnerInvitation> = emptyList()

                                    override suspend fun put(
                                        invitation: OwnerInvitation,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun findById(invitationId: id.Id<OwnerInvitation>): OwnerInvitation? = null

                                    override suspend fun existsPendingByEmail(email: String): Boolean = false
                                },
                                object : OwnerSyncDAO {
                                    override suspend fun listAll() = emptyList<persistence.model.Owner>()

                                    override suspend fun findById(ownerId: id.Id<persistence.model.Owner>) = null

                                    override suspend fun findBySub(sub: String): persistence.model.Owner? = null

                                    override suspend fun put(
                                        owner: persistence.model.Owner,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun updateStatus(
                                        ownerId: id.Id<persistence.model.Owner>,
                                        accountStatus: AccountStatus,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun existsByEmail(email: String) = false

                                    override suspend fun existsBySub(sub: String) = false

                                    override suspend fun delete(
                                        ownerId: id.Id<persistence.model.Owner>,
                                        change: persistence.changes.Change,
                                    ) = Unit

                                    override suspend fun promoteToOwner(
                                        owner: persistence.model.Owner,
                                        ownerChange: persistence.changes.Change,
                                        membersToRevoke: List<persistence.model.Member>,
                                        memberChanges: List<persistence.changes.Change>,
                                    ) = Unit
                                },
                                object : ActivationTokenDAO {
                                    override suspend fun create(token: ActivationToken) = Unit

                                    override suspend fun findByToken(token: String): ActivationToken? = null

                                    override suspend fun markActivated(
                                        token: String,
                                        activatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByOwnerInvitationId(
                                        invitationId: id.Id<OwnerInvitation>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByMemberInvitationId(
                                        invitationId: id.Id<MemberInvitation>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByOrganizationRequestId(
                                        requestId: id.Id<persistence.model.OrganizationRequest>,
                                        invalidatedAt: Instant,
                                    ) = Unit

                                    override suspend fun invalidateByProducerRequestId(
                                        requestId: id.Id<persistence.model.ProducerRequest>,
                                        invalidatedAt: Instant,
                                    ) = Unit
                                },
                                object : OwnerActivationEmailPort {
                                    override suspend fun sendOwnerActivationEmail(
                                        invitation: OwnerInvitation,
                                        token: ActivationToken,
                                    ) = Unit
                                },
                            )
                        }
                        single<MemberSyncDAO> { mockk(relaxed = true) }
                    },
                )
            }

        val lambda = APIGatewayLambdaBase(koin) { koinApp -> dataRoutingModule(koinApp) }

        val event =
            APIGatewayV2HTTPEvent(
                requestContext = APIGatewayV2HTTPEventRequestContext(http = APIGatewayV2HTTPEventHttp(path = "/v1/sync", method = "POST")),
                headers = mapOf("authorization" to "Bearer test", "content-type" to "application/json"),
                body = """{"cursors":{},"mutations":[]}""",
            )
        val eventJson = json.encodeToString(APIGatewayV2HTTPEvent.serializer(), event)

        val responseJson = lambda.handleRequest(eventJson) { it }
        val response = json.decodeFromString(APIGatewayV2HTTPResponse.serializer(), responseJson)

        assertEquals(200, response.statusCode)
        val body = assertNotNull(response.body)
        assertTrue(body.contains("\"authorized_scopes\""))
        assertTrue(body.contains("\"results\""))
        assertEquals(false, response.base64Encoded)
    }
}

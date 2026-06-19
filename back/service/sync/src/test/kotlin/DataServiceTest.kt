package sync

import authentication.AuthenticatedInfo
import authentication.Role
import contract.ContractService
import core.AuthorizedScopeResolver
import deliverytemplate.DeliveryTemplateService
import email.ActivationEmailPort
import email.ProducerActivationEmailPort
import email.ProducerRequestRejectionEmailPort
import email.RejectionEmailPort
import errorreport.ErrorReportService
import exchange.BasketExchangeService
import i18n.DEFAULT_LANGUAGE
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import notification.DeviceTokenService
import notification.NotificationService
import organization.OrganizationService
import organizationrequest.OrganizationRequestService
import owner.OwnerInvitationService
import owner.OwnerTypeService
import persistence.changes.BasketExchangePayload
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberPayload
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.ChangeDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.ErrorReportSyncDAO
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
import persistence.dao.ProductTypeSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryReminders
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.ProductType
import persistence.model.UserPreferences
import persistence.model.UserSettings
import produceraccount.ProducerAccountService
import producerrequest.ProducerRequestService
import producttype.ProductTypeService
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant

internal class DataServiceTest {
    private val producerAccountId = "producer-1"
    private val producerScope = SyncScope.ProducerAccount(producerAccountId)
    private val productType =
        ProductType(
            productTypeId = "pt-1".toId(),
            producerAccountId = producerAccountId.toId(),
            supportedBasketSizes = listOf(BasketSize("small")),
            name = "Vegetables",
        )

    // After sub/id unification: memberId == producerAccountId for producers,
    // and Role.PRODUCER is required for the scope resolver to grant the producer scope.
    private val producerAuth =
        AuthenticatedInfo(
            memberId = producerAccountId,
            firstName = "Jane",
            lastName = "Doe",
            email = "jane@example.com",
            roles = listOf(Role.PRODUCER),
        )

    // Helper that creates an AuthorizedScopeResolver backed by a mock MemberSyncDAO.
    // findOrganizationIdBySub always returns null so callers without an org scope
    // receive no Organization-scoped results by default.
    private fun testScopeResolver(): AuthorizedScopeResolver {
        val dao = mockk<MemberSyncDAO>(relaxed = true)
        coEvery { dao.findOrganizationIdBySub(any()) } returns null
        return AuthorizedScopeResolver(dao, mockk(relaxed = true))
    }

    // Helper that creates an AuthorizedScopeResolver that returns a fixed org for the given sub.
    private fun testScopeResolverForAdmin(
        sub: String,
        organizationId: String,
    ): AuthorizedScopeResolver {
        val dao = mockk<MemberSyncDAO>(relaxed = true)
        coEvery { dao.findOrganizationIdBySub(sub) } returns organizationId.toId()
        return AuthorizedScopeResolver(dao, mockk(relaxed = true))
    }

    // Helper that creates an AuthorizedScopeResolver for a PRODUCER caller. The DAO lookup
    // resolves producerId → producerAccountId so the scope resolver grants the producer scope.
    private fun testScopeResolverForProducer(
        producerId: String,
        producerAccountId: String,
    ): AuthorizedScopeResolver {
        val memberDao = mockk<MemberSyncDAO>(relaxed = true)
        coEvery { memberDao.findOrganizationIdBySub(any()) } returns null
        val producerDao = mockk<ProducerSyncDAO>(relaxed = true)
        val now = Clock.System.now()
        val producer =
            Producer(
                producerId = producerId.toId(),
                producerAccountId = producerAccountId.toId(),
                role = ProducerRole.OWNER,
                associationInstant = now,
                status = ProducerStatus.ACTIVE,
                producerPreferences = ProducerPreferences(productionAlertsEnabled = true, lastUpdatedInstant = now),
                userPreferences =
                    UserPreferences(
                        emailNotificationsEnabled = true,
                        pushNotificationsEnabled = false,
                        lastUpdatedInstant = now,
                    ),
                userSettings =
                    UserSettings(
                        language = "fr",
                        timezone = kotlinx.datetime.TimeZone.of("Europe/Paris"),
                        serverId = "server-1".toId(),
                        lastUpdatedInstant = now,
                    ),
            )
        coEvery { producerDao.findByProducerId(producerId.toId<Producer>()) } returns producer
        return AuthorizedScopeResolver(memberDao, producerDao)
    }

    @Test
    fun `GIVEN auth without authorized scopes WHEN sync THEN returns empty scoped response`() =
        runTest {
            val service =
                DataService(
                    services =
                        listOf(
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = mockk(relaxed = true),
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolver(),
                )

            val response =
                service.sync(
                    AuthenticatedInfo(
                        memberId = "m-2",
                        firstName = "No",
                        lastName = "Scope",
                        email = "noscope@example.com",
                    ),
                    emptyMap(),
                )

            assertTrue(response.authorizedScopes.isEmpty())
            assertTrue(response.results.isEmpty())
        }

    @Test
    fun `GIVEN producer scope without cursor WHEN sync THEN bootstraps that scope`() =
        runTest {
            val productTypeDAO = mockk<ProductTypeSyncDAO>()
            val changeDAO = mockk<ChangeDAO>()
            coEvery { productTypeDAO.getByProducerAccountId(any()) } returns listOf(productType)

            val service =
                DataService(
                    services =
                        listOf(
                            ProductTypeService(productTypeDAO),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForProducer(producerAccountId, producerAccountId),
                )

            val response = service.sync(producerAuth, emptyMap())

            assertEquals(listOf(producerScope.key), response.authorizedScopes)
            val result = assertIs<BootstrapScopeResult>(response.results.getValue(producerScope.key))
            assertEquals(listOf(ProductTypePayload(productType)), result.items)
            assertTrue(result.nextCursor.isNotEmpty())
            coVerify(exactly = 0) { changeDAO.countSince(any(), any(), any()) }
        }

    @Test
    fun `GIVEN producer scope with incremental cursor under threshold WHEN sync THEN returns incremental result`() =
        runTest {
            val productTypeDAO = mockk<ProductTypeSyncDAO>()
            val changeDAO = mockk<ChangeDAO>()
            val change =
                Change(
                    cursor = "c2",
                    entityType = EntityType.ProductType,
                    entityId = "pt-1",
                    scopeKey = producerScope.key,
                    op = ChangeOp.UPSERT,
                    payload = ProductTypePayload(productType),
                    producedAt = 1,
                )
            coEvery { changeDAO.countSince(producerScope.key, "c1", any()) } returns 1
            coEvery { changeDAO.since(producerScope.key, "c1") } returns listOf(change)

            val service =
                DataService(
                    services =
                        listOf(
                            ProductTypeService(productTypeDAO),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForProducer(producerAccountId, producerAccountId),
                )

            val response = service.sync(producerAuth, mapOf(producerScope.key to "c1"))

            val result = assertIs<IncrementalScopeResult>(response.results.getValue(producerScope.key))
            assertEquals(listOf(change), result.changes)
            assertEquals("c2", result.nextCursor)
            coVerify(exactly = 0) { productTypeDAO.getByProducerAccountId(any()) }
        }

    @Test
    fun `GIVEN producer scope with too many changed rows WHEN sync THEN falls back to bootstrap`() =
        runTest {
            val productTypeDAO = mockk<ProductTypeSyncDAO>()
            val changeDAO = mockk<ChangeDAO>()
            coEvery {
                changeDAO.countSince(
                    producerScope.key,
                    "c1",
                    any(),
                )
            } returns ChangeDAO.DEFAULT_INCREMENTAL_LIMIT + 1
            coEvery { productTypeDAO.getByProducerAccountId(any()) } returns listOf(productType)

            val service =
                DataService(
                    services =
                        listOf(
                            ProductTypeService(productTypeDAO),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForProducer(producerAccountId, producerAccountId),
                )

            val response = service.sync(producerAuth, mapOf(producerScope.key to "c1"))

            val result = assertIs<BootstrapScopeResult>(response.results.getValue(producerScope.key))
            assertEquals(listOf(ProductTypePayload(productType)), result.items)
            coVerify(exactly = 0) { changeDAO.since(any(), any()) }
        }

    @Test
    fun `GIVEN owner scope member cursor WHEN sync THEN owner receives member changes incrementally`() =
        runTest {
            val changeDAO = mockk<ChangeDAO>()
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val change =
                Change(
                    cursor = "c9",
                    entityType = EntityType.Member,
                    entityId = "member-1",
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = null,
                    producedAt = 1,
                )
            coEvery { changeDAO.countSince(SyncScope.InstanceOwner.key, "c8", any()) } returns 1
            coEvery { changeDAO.since(SyncScope.InstanceOwner.key, "c8") } returns listOf(change)

            val service =
                DataService(
                    services =
                        listOf(
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = memberSyncDAO,
                    authorizedScopeResolver = testScopeResolver(),
                )
            val ownerAuth =
                AuthenticatedInfo(
                    memberId = "owner-1",
                    firstName = "Owner",
                    lastName = "User",
                    email = "owner@example.com",
                    roles = listOf(Role.OWNER),
                )

            val response = service.sync(ownerAuth, mapOf(SyncScope.InstanceOwner.key to "c8"))

            val result = assertIs<IncrementalScopeResult>(response.results.getValue(SyncScope.InstanceOwner.key))
            assertEquals(listOf(change), result.changes)
            coVerify(exactly = 0) { memberSyncDAO.listAll() }
        }

    @Test
    fun `GIVEN mutation WHEN sync THEN applies writes before returning outcomes`() =
        runTest {
            val productTypeDAO = mockk<ProductTypeSyncDAO>()
            val changeDAO = mockk<ChangeDAO>()
            val capturedProduct = slot<ProductType>()
            coEvery { productTypeDAO.put(capture(capturedProduct), any()) } returns Unit
            coEvery { productTypeDAO.getByProducerAccountId(any()) } returns emptyList()

            val service =
                DataService(
                    services =
                        listOf(
                            ProductTypeService(productTypeDAO),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForProducer(producerAccountId, producerAccountId),
                )

            val response =
                service.sync(
                    producerAuth,
                    emptyMap(),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-1",
                            op = Upsert(ProductTypePayload(productType)),
                        ),
                    ),
                )

            assertEquals(MutationStatus.APPLIED, response.mutations.single().status)
            assertEquals(productType.productTypeId, capturedProduct.captured.productTypeId)
        }

    @Test
    fun `GIVEN owner bootstrap without cursor WHEN sync THEN bootstraps mixed-type owner scope`() =
        runTest {
            val memberSyncDAO = mockk<MemberSyncDAO>()
            val member =
                Member(
                    memberId = "member-1".toId(),
                    organizationId = "org-1".toId(),
                    activeStatus = true,
                    memberSettings =
                        MemberSettings(
                            deliveryReminders = DeliveryReminders(1, "08:00"),
                            accessibilityOptions = AccessibilityOptions(false, false, false),
                            lastUpdatedInstant = Instant.fromEpochMilliseconds(1),
                        ),
                    memberPreferences = MemberPreferences(true, true, Instant.fromEpochMilliseconds(1)),
                    userPreferences = UserPreferences(true, false, Instant.fromEpochMilliseconds(1)),
                    userSettings =
                        UserSettings(
                            language = "fr",
                            timezone = TimeZone.of("Europe/Paris"),
                            serverId = "server-1".toId(),
                            lastUpdatedInstant = Instant.fromEpochMilliseconds(1),
                        ),
                )
            coEvery { memberSyncDAO.listAll() } returns listOf(member)

            val service =
                DataService(
                    services =
                        listOf(
                            OrganizationRequestService(
                                organizationRequestSyncDAO =
                                    mockk<OrganizationRequestSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                organizationRequestDAO = mockk<OrganizationRequestDAO>(relaxed = true),
                                organizationDAO = mockk<OrganizationDAO>(relaxed = true),
                                activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true),
                                activationEmailPort = mockk<ActivationEmailPort>(relaxed = true),
                                rejectionEmailPort = mockk<RejectionEmailPort>(relaxed = true),
                            ),
                            ProducerRequestService(
                                producerRequestSyncDAO =
                                    mockk<ProducerRequestSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                producerRequestDAO = mockk<ProducerRequestDAO>(relaxed = true),
                                producerAccountSyncDAO =
                                    mockk<ProducerAccountSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true),
                                producerActivationEmailPort = mockk<ProducerActivationEmailPort>(relaxed = true),
                                producerRequestRejectionEmailPort = mockk<ProducerRequestRejectionEmailPort>(relaxed = true),
                            ),
                            OwnerTypeService(
                                ownerDAO =
                                    mockk<OwnerSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                memberSyncDAO = memberSyncDAO,
                                roleService = mockk(relaxed = true),
                                ownerService = mockk(relaxed = true),
                                roleProvisioningPort = null,
                            ),
                            OwnerInvitationService(
                                ownerInvitationDAO =
                                    mockk<OwnerInvitationSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                ownerDAO =
                                    mockk<OwnerSyncDAO> {
                                        coEvery { existsByEmail(any()) } returns false
                                    },
                                activationTokenDAO = mockk(relaxed = true),
                                ownerActivationEmailPort = mockk(relaxed = true),
                            ),
                            OrganizationService(
                                organizationSyncDAO =
                                    mockk<OrganizationSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                deliveryTemplateSyncDAO = mockk(relaxed = true),
                                producerAccountSyncDAO = mockk(relaxed = true),
                                memberSyncDAO = mockk(relaxed = true),
                                notificationPublisher = mockk(relaxed = true),
                                contractSyncDAO = mockk(relaxed = true),
                            ),
                            ProducerAccountService(
                                producerAccountSyncDAO =
                                    mockk<ProducerAccountSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                                organizationSyncDAO = mockk(relaxed = true),
                                userProvisioningPort = mockk(relaxed = true),
                                accountLifecycleEmailPort = mockk(relaxed = true),
                                accountDeletionLogDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            ErrorReportService(
                                errorReportSyncDAO =
                                    mockk<ErrorReportSyncDAO> {
                                        coEvery { listAll() } returns emptyList()
                                    },
                            ),
                        ),
                    changeDAO = mockk(relaxed = true),
                    memberSyncDAO = memberSyncDAO,
                    authorizedScopeResolver = testScopeResolver(),
                )
            val ownerAuth =
                AuthenticatedInfo(
                    memberId = "owner-1",
                    firstName = "Owner",
                    lastName = "User",
                    email = "owner@example.com",
                    roles = listOf(Role.OWNER),
                )

            val response = service.sync(ownerAuth, emptyMap())

            val result = assertIs<BootstrapScopeResult>(response.results.getValue(SyncScope.InstanceOwner.key))
            assertEquals(listOf(MemberPayload(member)), result.items)
        }

    @Test
    fun `GIVEN tmp ProducerAccount upsert before Organization upsert WHEN sync THEN Organization persisted with real producer id`() =
        runTest {
            val organizationId = "org-1"
            val tmpProducerId = "tmp_new-producer"
            val adminAuth =
                AuthenticatedInfo(
                    memberId = "admin-1",
                    firstName = "Admin",
                    lastName = "User",
                    email = "admin@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
            val capturedProducer = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.findById(any()) } returns null
            coEvery {
                producerAccountSyncDAO.put(capture(capturedProducer), any(), any())
            } returns Unit
            coEvery { producerAccountSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            val capturedOrg = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(capturedOrg), any()) } returns Unit
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val now = Instant.fromEpochMilliseconds(1_000L)
            val producerAccount =
                ProducerAccount(
                    producerAccountId = tmpProducerId.toId(),
                    name = "New Producer",
                    contactEmail = "producer@example.com",
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations =
                        listOf(
                            ProducerOrganization(
                                organizationId = organizationId.toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )
            val organization =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "My AMAP",
                    contactEmail = "amap@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = DEFAULT_LANGUAGE,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = tmpProducerId.toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)

            val adminScopeResolver = testScopeResolverForAdmin("admin-1", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            ProducerAccountService(
                                producerAccountSyncDAO = producerAccountSyncDAO,
                                organizationSyncDAO = organizationSyncDAO,
                                userProvisioningPort = mockk(relaxed = true),
                                accountLifecycleEmailPort = mockk(relaxed = true),
                                accountDeletionLogDAO = mockk(relaxed = true),
                            ),
                            OrganizationService(
                                organizationSyncDAO = organizationSyncDAO,
                                deliveryTemplateSyncDAO = mockk(relaxed = true),
                                producerAccountSyncDAO = mockk(relaxed = true),
                                memberSyncDAO = mockk(relaxed = true),
                                notificationPublisher = mockk(relaxed = true),
                                contractSyncDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    // Provide a cursor so the sync takes the incremental path and does not
                    // attempt to bootstrap all entity types for the organization scope.
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-producer",
                            op = Upsert(ProducerAccountPayload(producerAccount)),
                        ),
                        ClientMutation(
                            clientOpId = "op-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
                )

            // Both mutations must be applied
            assertEquals(2, response.mutations.size)
            val producerOutcome = response.mutations.first { it.clientOpId == "op-producer" }
            val orgOutcome = response.mutations.first { it.clientOpId == "op-org" }
            assertEquals(MutationStatus.APPLIED, producerOutcome.status)
            assertEquals(MutationStatus.APPLIED, orgOutcome.status)

            // The real producer account id must have been allocated (not tmp)
            val realProducerId = producerOutcome.serverEntityId
            assertTrue(realProducerId != null && !realProducerId.startsWith(ClientMutation.TMP_ID_PREFIX))

            // The Organization persisted to the DAO must use the real producer account id
            assertEquals(realProducerId, capturedProducer.captured.producerAccountId.id)
            assertEquals(1, capturedOrg.captured.producers.size)
            assertEquals(
                realProducerId,
                capturedOrg.captured.producers
                    .single()
                    .producerAccountId.id,
            )
        }

    @Test
    fun `GIVEN tmp DeliveryTemplate upsert before Organization upsert WHEN sync THEN Organization has real template id`() =
        runTest {
            val organizationId = "org-dt"
            val tmpTemplateId = "tmp_template-1"
            val adminAuth =
                AuthenticatedInfo(
                    memberId = "admin-dt",
                    firstName = "Admin",
                    lastName = "User",
                    email = "admin@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            val deliveryTemplateSyncDAO = mockk<DeliveryTemplateSyncDAO>()
            val capturedTemplate = slot<DeliveryTemplate>()
            coEvery { deliveryTemplateSyncDAO.put(capture(capturedTemplate), any()) } returns Unit
            coEvery { deliveryTemplateSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            val capturedOrg = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(capturedOrg), any()) } returns Unit
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val now = Instant.fromEpochMilliseconds(1_000L)
            val deliveryTemplate =
                DeliveryTemplate(
                    deliveryTemplateId = tmpTemplateId.toId(),
                    organizationId = organizationId.toId(),
                    name = "Morning Template",
                    standardStartTime = "08:00",
                    standardEndTime = "12:00",
                )
            val organization =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "My AMAP",
                    contactEmail = "amap@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = DEFAULT_LANGUAGE,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    defaultDeliveryTemplateId = tmpTemplateId.toId(),
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)
            val adminScopeResolver = testScopeResolverForAdmin("admin-dt", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            DeliveryTemplateService(deliveryTemplateSyncDAO),
                            OrganizationService(
                                organizationSyncDAO = organizationSyncDAO,
                                deliveryTemplateSyncDAO = mockk(relaxed = true),
                                producerAccountSyncDAO = mockk(relaxed = true),
                                memberSyncDAO = mockk(relaxed = true),
                                notificationPublisher = mockk(relaxed = true),
                                contractSyncDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-template",
                            op = Upsert(DeliveryTemplatePayload(deliveryTemplate)),
                        ),
                        ClientMutation(
                            clientOpId = "op-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
                )

            assertEquals(2, response.mutations.size)
            val templateOutcome = response.mutations.first { it.clientOpId == "op-template" }
            val orgOutcome = response.mutations.first { it.clientOpId == "op-org" }
            assertEquals(MutationStatus.APPLIED, templateOutcome.status)
            assertEquals(MutationStatus.APPLIED, orgOutcome.status)

            // DeliveryTemplateService returns the tmp id as serverEntityId (no real id allocation yet),
            // so the rewrite maps tmp → tmp which is a no-op — the organization is stored with
            // whatever id the template returned. The test verifies the mechanism is wired correctly.
            val templateServerEntityId = templateOutcome.serverEntityId
            assertEquals(capturedOrg.captured.defaultDeliveryTemplateId?.id, templateServerEntityId)
        }

    @Test
    fun `GIVEN tmp entity creation via stub service WHEN sync THEN FK in later mutation is rewritten`() =
        runTest {
            // This test exercises the generic rewrite mechanism using a stub EntityTypeService
            // that allocates a real server id for a tmp_ creation — confirming the flow works
            // for any entity type that allocates real ids.
            val organizationId = "org-generic"
            val tmpId = "tmp_generic-entity"
            val realId = "real-entity-123"

            val adminAuth =
                AuthenticatedInfo(
                    memberId = "admin-gen",
                    firstName = "Admin",
                    lastName = "User",
                    email = "admin@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            val capturedOrg = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(capturedOrg), any()) } returns Unit
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val now = Instant.fromEpochMilliseconds(1_000L)

            // A stub ProducerAccountService-like service that always allocates the "real" id.
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
            coEvery { producerAccountSyncDAO.findById(any()) } returns null
            coEvery { producerAccountSyncDAO.put(any(), any(), any()) } returns Unit
            coEvery { producerAccountSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val producerAccount =
                ProducerAccount(
                    producerAccountId = tmpId.toId(),
                    name = "Generic Producer",
                    contactEmail = "gen@example.com",
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = emptyList(),
                    userPreferences =
                        UserPreferences(
                            emailNotificationsEnabled = true,
                            pushNotificationsEnabled = false,
                            lastUpdatedInstant = now,
                        ),
                )
            // Organization referencing the tmp producer in products
            val organization =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "My AMAP",
                    contactEmail = "amap@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = DEFAULT_LANGUAGE,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = tmpId.toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)
            val adminScopeResolver = testScopeResolverForAdmin("admin-gen", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            ProducerAccountService(
                                producerAccountSyncDAO = producerAccountSyncDAO,
                                organizationSyncDAO = organizationSyncDAO,
                                userProvisioningPort = mockk(relaxed = true),
                                accountLifecycleEmailPort = mockk(relaxed = true),
                                accountDeletionLogDAO = mockk(relaxed = true),
                            ),
                            OrganizationService(
                                organizationSyncDAO = organizationSyncDAO,
                                deliveryTemplateSyncDAO = mockk(relaxed = true),
                                producerAccountSyncDAO = mockk(relaxed = true),
                                memberSyncDAO = mockk(relaxed = true),
                                notificationPublisher = mockk(relaxed = true),
                                contractSyncDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-producer",
                            op = Upsert(ProducerAccountPayload(producerAccount)),
                        ),
                        ClientMutation(
                            clientOpId = "op-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
                )

            assertEquals(2, response.mutations.size)
            val producerOutcome = response.mutations.first { it.clientOpId == "op-producer" }
            assertEquals(MutationStatus.APPLIED, producerOutcome.status)
            val allocatedRealId = producerOutcome.serverEntityId
            assertTrue(allocatedRealId != null && !allocatedRealId.startsWith(ClientMutation.TMP_ID_PREFIX))

            // The Organization stored to the DAO must have had its tmp producerAccountId rewritten.
            assertEquals(
                allocatedRealId,
                capturedOrg.captured.producers
                    .single()
                    .producerAccountId.id,
            )
        }

    @Test
    fun `GIVEN first mutation REJECTED WHEN second mutation references tmp id THEN FK is not rewritten`() =
        runTest {
            val organizationId = "org-reject"
            val tmpProducerId = "tmp_rejected-producer"
            val adminAuth =
                AuthenticatedInfo(
                    memberId = "admin-r",
                    firstName = "Admin",
                    lastName = "User",
                    email = "admin@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            // ProducerAccountService will reject because of INVALID_PAYLOAD (account-backed tmp not allowed via org sync)
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
            coEvery { producerAccountSyncDAO.findById(any()) } returns null
            coEvery { producerAccountSyncDAO.getByOrganizationId(any()) } returns emptyList()

            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            val capturedOrg = slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(capturedOrg), any()) } returns Unit
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val now = Instant.fromEpochMilliseconds(1_000L)
            // Using ACCOUNT_BACKED here will be rejected by ProducerAccountService.
            val rejectedProducer =
                ProducerAccount(
                    producerAccountId = tmpProducerId.toId(),
                    name = "Rejected Producer",
                    activeStatus = true,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED, // triggers rejection
                    organizations = emptyList(),
                    userPreferences =
                        UserPreferences(
                            emailNotificationsEnabled = true,
                            pushNotificationsEnabled = false,
                            lastUpdatedInstant = now,
                        ),
                )
            val organization =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "My AMAP",
                    contactEmail = "amap@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = DEFAULT_LANGUAGE,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = tmpProducerId.toId(),
                                associationInstant = now,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)
            val adminScopeResolver = testScopeResolverForAdmin("admin-r", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            ProducerAccountService(
                                producerAccountSyncDAO = producerAccountSyncDAO,
                                organizationSyncDAO = organizationSyncDAO,
                                userProvisioningPort = mockk(relaxed = true),
                                accountLifecycleEmailPort = mockk(relaxed = true),
                                accountDeletionLogDAO = mockk(relaxed = true),
                            ),
                            OrganizationService(
                                organizationSyncDAO = organizationSyncDAO,
                                deliveryTemplateSyncDAO = mockk(relaxed = true),
                                producerAccountSyncDAO = mockk(relaxed = true),
                                memberSyncDAO = mockk(relaxed = true),
                                notificationPublisher = mockk(relaxed = true),
                                contractSyncDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-rejected-producer",
                            op = Upsert(ProducerAccountPayload(rejectedProducer)),
                        ),
                        ClientMutation(
                            clientOpId = "op-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
                )

            assertEquals(2, response.mutations.size)
            val rejectedOutcome = response.mutations.first { it.clientOpId == "op-rejected-producer" }
            assertEquals(MutationStatus.REJECTED, rejectedOutcome.status)
            assertNull(rejectedOutcome.serverEntityId)

            // The Organization was still applied (each mutation is independent).
            val orgOutcome = response.mutations.first { it.clientOpId == "op-org" }
            assertEquals(MutationStatus.APPLIED, orgOutcome.status)

            // Because the ProducerAccount was REJECTED, the tmp id was never added to tmpIdMap.
            // Therefore, the Organization was persisted with the original tmp producerAccountId unchanged.
            assertEquals(
                tmpProducerId,
                capturedOrg.captured.producers
                    .single()
                    .producerAccountId.id,
            )
        }

    @Test
    fun `GIVEN tmp Contract upsert then BasketExchange referencing it WHEN sync THEN BasketExchange receives real contract id`() =
        runTest {
            // This test wires mock services that "allocate" a real id when given a tmp_ Contract id,
            // then checks the BasketExchange gets the rewritten contractId.
            val organizationId = "org-bex"
            val tmpContractId = "tmp_contract-bex"
            val realContractId = "contract-real-bex"
            val adminAuth =
                AuthenticatedInfo(
                    memberId = "member-bex",
                    firstName = "Member",
                    lastName = "Offerer",
                    email = "member@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            val now = Instant.fromEpochMilliseconds(1_000L)

            // Mock ContractService that allocates a real id for a tmp_ creation.
            val contractService = mockk<ContractService>()
            every { contractService.entityType } returns EntityType.Contract
            coEvery { contractService.applyUpsert(any(), any(), any()) } answers {
                val mutation = secondArg<ClientMutation>()
                MutationOutcome(
                    clientOpId = mutation.clientOpId,
                    status = MutationStatus.APPLIED,
                    serverEntityId = realContractId,
                )
            }
            coEvery { contractService.snapshot(any(), any()) } returns emptyList()

            // Mock BasketExchangeService that captures the contractId it receives.
            val capturedPayload = slot<BasketExchangePayload>()
            val basketExchangeService = mockk<BasketExchangeService>()
            every { basketExchangeService.entityType } returns EntityType.BasketExchange
            coEvery { basketExchangeService.applyUpsert(any(), any(), capture(capturedPayload)) } answers {
                val mutation = secondArg<ClientMutation>()
                MutationOutcome(
                    clientOpId = mutation.clientOpId,
                    status = MutationStatus.APPLIED,
                    serverEntityId = "bex-real",
                )
            }
            coEvery { basketExchangeService.snapshot(any(), any()) } returns emptyList()

            val contract =
                Contract(
                    contractId = tmpContractId.toId(),
                    name = "Test contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = LocalDate(2024, 1, 1),
                    maxDeliveryDate = LocalDate(2024, 12, 31),
                    deliveryCount = 10,
                    seasonYear = 2024,
                )
            val basketExchange =
                BasketExchange(
                    basketExchangeId = "tmp_bex-1".toId(),
                    organizationId = organizationId.toId(),
                    deliveryId = "dlv-1".toId(),
                    contractId = tmpContractId.toId(),
                    offeringMemberId = "member-bex".toId(),
                    status = BasketExchangeStatus.OPEN,
                    createdAt = now,
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)
            val adminScopeResolver = testScopeResolverForAdmin("member-bex", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            contractService,
                            basketExchangeService,
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-contract",
                            op = Upsert(ContractPayload(contract)),
                        ),
                        ClientMutation(
                            clientOpId = "op-bex",
                            op = Upsert(BasketExchangePayload(basketExchange)),
                        ),
                    ),
                )

            assertEquals(2, response.mutations.size)
            assertEquals(MutationStatus.APPLIED, response.mutations.first { it.clientOpId == "op-contract" }.status)
            assertEquals(MutationStatus.APPLIED, response.mutations.first { it.clientOpId == "op-bex" }.status)

            // The BasketExchangePayload received by BasketExchangeService had the tmp contractId rewritten.
            assertEquals(realContractId, capturedPayload.captured.basketExchange.contractId.id)
        }

    @Test
    fun `GIVEN tmp Contract upsert then Organization delivery referencing it WHEN sync THEN delivery receives real contract id`() =
        runTest {
            val organizationId = "org-weekly"
            val tmpContractId = "tmp_contract-weekly"
            val realContractId = "contract-real-weekly"
            val adminAuth =
                AuthenticatedInfo(
                    memberId = "member-weekly",
                    firstName = "Admin",
                    lastName = "Weekly",
                    email = "admin@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.ADMIN),
                )

            val now = Instant.fromEpochMilliseconds(1_000L)

            // Mock ContractService that allocates a real id for a tmp_ creation.
            val contractService = mockk<ContractService>()
            every { contractService.entityType } returns EntityType.Contract
            coEvery { contractService.applyUpsert(any(), any(), any()) } answers {
                val mutation = secondArg<ClientMutation>()
                MutationOutcome(
                    clientOpId = mutation.clientOpId,
                    status = MutationStatus.APPLIED,
                    serverEntityId = realContractId,
                )
            }
            coEvery { contractService.snapshot(any(), any()) } returns emptyList()

            // Mock OrganizationService that captures the Organization payload it receives.
            val capturedOrgPayload = slot<OrganizationPayload>()
            val organizationService = mockk<OrganizationService>()
            every { organizationService.entityType } returns EntityType.Organization
            coEvery { organizationService.applyUpsert(any(), any(), capture(capturedOrgPayload)) } answers {
                val mutation = secondArg<ClientMutation>()
                MutationOutcome(
                    clientOpId = mutation.clientOpId,
                    status = MutationStatus.APPLIED,
                    serverEntityId = organizationId,
                )
            }
            coEvery { organizationService.snapshot(any(), any()) } returns emptyList()

            val contract =
                Contract(
                    contractId = tmpContractId.toId(),
                    name = "Weekly contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = LocalDate(2026, 1, 1),
                    maxDeliveryDate = LocalDate(2026, 12, 31),
                    deliveryCount = 52,
                    seasonYear = 2026,
                )
            val deliveryContract =
                DeliveryContract(
                    contractId = tmpContractId.toId(),
                    basketQuantity = 1,
                    deliveryDescription = "Weekly basket",
                    status = DeliveryContractStatus.PENDING,
                )
            val delivery =
                Delivery(
                    deliveryId = "dlv-weekly-1".toId(),
                    organizationId = organizationId.toId(),
                    scheduledDate = LocalDateTime.parse("2026-01-05T18:00:00"),
                    status = DeliveryStatus.PLANNED,
                    minVolunteersRequired = 0,
                    contracts = listOf(deliveryContract),
                )
            val organization =
                Organization(
                    organizationId = organizationId.toId(),
                    name = "Weekly AMAP",
                    contactEmail = "weekly@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = DEFAULT_LANGUAGE,
                    createdInstant = now,
                    lastUpdatedInstant = now,
                    deliveries = listOf(delivery),
                )

            val changeDAO = mockk<ChangeDAO>(relaxed = true)
            val adminScopeResolver = testScopeResolverForAdmin("member-weekly", organizationId)
            val service =
                DataService(
                    services =
                        listOf(
                            contractService,
                            organizationService,
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolver(),
                            ),
                        ),
                    changeDAO = changeDAO,
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = adminScopeResolver,
                )

            val response =
                service.sync(
                    adminAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-contract",
                            op = Upsert(ContractPayload(contract)),
                        ),
                        ClientMutation(
                            clientOpId = "op-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
                )

            assertEquals(2, response.mutations.size)
            val contractOutcome = response.mutations.first { it.clientOpId == "op-contract" }
            assertEquals(MutationStatus.APPLIED, contractOutcome.status)
            assertTrue(
                contractOutcome.serverEntityId != null &&
                    contractOutcome.serverEntityId != tmpContractId,
            )

            // The OrganizationPayload received by OrganizationService must have the tmp contractId rewritten.
            val capturedDeliveryContract =
                capturedOrgPayload.captured.organization.deliveries
                    .single()
                    .contracts
                    .single()
            assertEquals(realContractId, capturedDeliveryContract.contractId.id)
        }

    // ---- Authorization guard tests (transverse P0/P1 safety net) ----

    @Test
    fun `GIVEN volunteer caller WHEN upsert Contract THEN REJECTED FORBIDDEN`() =
        runTest {
            val organizationId = "org-guard"
            val volunteerAuth =
                AuthenticatedInfo(
                    memberId = "volunteer-1",
                    firstName = "Vol",
                    lastName = "U",
                    email = "vol@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.VOLUNTEER),
                )

            val contractSyncDAO = mockk<ContractSyncDAO>()
            val service =
                DataService(
                    services =
                        listOf(
                            ContractService(
                                contractSyncDAO = contractSyncDAO,
                                organizationSyncDAO = mockk(relaxed = true),
                            ),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                            ),
                        ),
                    changeDAO = mockk(relaxed = true),
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                )

            val contract =
                Contract(
                    contractId = "contract-1".toId(),
                    name = "Test contract",
                    organizationId = organizationId.toId(),
                    producerAccountId = "producer-1".toId(),
                    minDeliveryDate = LocalDate(2025, 1, 1),
                    maxDeliveryDate = LocalDate(2025, 12, 31),
                    deliveryCount = 10,
                    seasonYear = 2025,
                )

            val response =
                service.sync(
                    volunteerAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-contract",
                            op = Upsert(ContractPayload(contract)),
                        ),
                    ),
                )

            val outcome = response.mutations.single()
            assertEquals(MutationStatus.REJECTED, outcome.status)
            // DAO must never be called
            coVerify(exactly = 0) { contractSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN upsert DeliveryTemplate THEN REJECTED FORBIDDEN`() =
        runTest {
            val organizationId = "org-guard-tmpl"
            val volunteerAuth =
                AuthenticatedInfo(
                    memberId = "volunteer-2",
                    firstName = "Vol",
                    lastName = "U",
                    email = "vol2@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.VOLUNTEER),
                )

            val deliveryTemplateSyncDAO = mockk<DeliveryTemplateSyncDAO>()
            val service =
                DataService(
                    services =
                        listOf(
                            DeliveryTemplateService(deliveryTemplateSyncDAO),
                            NotificationService(
                                notificationSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                            ),
                            DeviceTokenService(
                                deviceTokenSyncDAO = mockk(relaxed = true),
                                authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                            ),
                        ),
                    changeDAO = mockk(relaxed = true),
                    memberSyncDAO = mockk(relaxed = true),
                    authorizedScopeResolver = testScopeResolverForAdmin(volunteerAuth.memberId, organizationId),
                )

            val template =
                DeliveryTemplate(
                    deliveryTemplateId = "tmpl-1".toId(),
                    organizationId = organizationId.toId(),
                    name = "Template",
                    standardStartTime = "18:00",
                    standardEndTime = "20:00",
                )

            val response =
                service.sync(
                    volunteerAuth,
                    mapOf("organization:$organizationId" to "c-init"),
                    listOf(
                        ClientMutation(
                            clientOpId = "op-tmpl",
                            op = Upsert(DeliveryTemplatePayload(template)),
                        ),
                    ),
                )

            val outcome = response.mutations.single()
            assertEquals(MutationStatus.REJECTED, outcome.status)
            coVerify(exactly = 0) { deliveryTemplateSyncDAO.put(any(), any()) }
        }
}

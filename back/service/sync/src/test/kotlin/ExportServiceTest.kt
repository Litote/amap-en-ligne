@file:OptIn(kotlin.time.ExperimentalTime::class)

package sync

import authentication.AuthenticatedInfo
import authentication.Role
import i18n.DEFAULT_LANGUAGE
import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.MemberPayload
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.BasketSize
import persistence.model.DeliveryReminders
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.ProductType
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Instant

internal class ExportServiceTest {
    private val organizationId = "org-1"

    private val now = Instant.fromEpochMilliseconds(1_000L)

    private val organization =
        Organization(
            organizationId = organizationId.toId(),
            name = "My AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = DEFAULT_LANGUAGE,
            createdInstant = now,
            lastUpdatedInstant = now,
        )

    private val member =
        Member(
            memberId = "member-1".toId(),
            organizationId = organizationId.toId(),
            activeStatus = true,
            memberSettings =
                MemberSettings(
                    deliveryReminders = DeliveryReminders(1, "08:00"),
                    accessibilityOptions = AccessibilityOptions(false, false, false),
                    lastUpdatedInstant = now,
                ),
            memberPreferences = MemberPreferences(true, true, now),
            userPreferences = UserPreferences(true, false, now),
            userSettings =
                UserSettings(
                    language = "fr",
                    timezone = TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId(),
                    lastUpdatedInstant = now,
                ),
        )

    private val producerAccount =
        ProducerAccount(
            producerAccountId = "pa-1".toId(),
            name = "Ferme",
            contactEmail = "ferme@example.com",
            activeStatus = true,
            createdInstant = now,
            lastUpdatedInstant = now,
        )

    private val productType =
        ProductType(
            productTypeId = "pt-1".toId(),
            producerAccountId = "pa-1".toId(),
            supportedBasketSizes = listOf(BasketSize("small")),
            name = "Vegetables",
        )

    private fun adminAuth(orgId: String? = organizationId) =
        AuthenticatedInfo(
            memberId = "admin-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = orgId,
            roles = listOf(Role.ADMIN),
        )

    private fun buildService(
        dataService: DataService = mockk(relaxed = true),
        organizationSyncDAO: OrganizationSyncDAO = mockk(relaxed = true),
        producerAccountSyncDAO: ProducerAccountSyncDAO = mockk(relaxed = true),
        productTypeDAO: ProductTypeSyncDAO = mockk(relaxed = true),
        memberSyncDAO: MemberSyncDAO = mockk(relaxed = true),
    ) = ExportService(dataService, organizationSyncDAO, producerAccountSyncDAO, productTypeDAO, memberSyncDAO)

    @Test
    fun `GIVEN admin of the org WHEN export THEN returns org payloads and linked product types`() =
        runTest {
            val dataService = mockk<DataService>()
            coEvery { dataService.snapshotScope(any(), SyncScope.Organization(organizationId)) } returns
                listOf(MemberPayload(member))
            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            coEvery { organizationSyncDAO.getById(organizationId.toId<Organization>()) } returns organization
            val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
            coEvery { producerAccountSyncDAO.getByOrganizationId(organizationId.toId<Organization>()) } returns
                listOf(producerAccount)
            val productTypeDAO = mockk<ProductTypeSyncDAO>()
            coEvery { productTypeDAO.getByProducerAccountId("pa-1".toId()) } returns listOf(productType)

            val service =
                buildService(
                    dataService = dataService,
                    organizationSyncDAO = organizationSyncDAO,
                    producerAccountSyncDAO = producerAccountSyncDAO,
                    productTypeDAO = productTypeDAO,
                )

            val outcome = service.exportOrganization(adminAuth(), organizationId, "Test Instance")

            val success = assertIs<ExportOutcome.Success>(outcome)
            assertEquals(organizationId, success.export.organizationId)
            assertEquals("Test Instance", success.export.sourceInstance)
            assertEquals(listOf(MemberPayload(member)), success.export.scopes.organization)
            assertEquals(listOf(ProductTypePayload(productType)), success.export.scopes.productTypes)
        }

    @Test
    fun `GIVEN admin of a different org WHEN export THEN forbidden`() =
        runTest {
            val service = buildService()

            val outcome = service.exportOrganization(adminAuth(orgId = "other-org"), organizationId, null)

            assertIs<ExportOutcome.Forbidden>(outcome)
        }

    @Test
    fun `GIVEN owner WHEN export any org THEN authorized`() =
        runTest {
            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            coEvery { organizationSyncDAO.getById(organizationId.toId<Organization>()) } returns organization
            val dataService = mockk<DataService>()
            coEvery { dataService.snapshotScope(any(), any()) } returns emptyList()

            val service = buildService(dataService = dataService, organizationSyncDAO = organizationSyncDAO)

            val ownerAuth =
                AuthenticatedInfo(
                    memberId = "owner-1",
                    firstName = "Owner",
                    lastName = "User",
                    email = "owner@example.com",
                    roles = listOf(Role.OWNER),
                )

            assertIs<ExportOutcome.Success>(service.exportOrganization(ownerAuth, organizationId, null))
        }

    @Test
    fun `GIVEN volunteer WHEN export THEN forbidden`() =
        runTest {
            val service = buildService()

            val volunteerAuth =
                AuthenticatedInfo(
                    memberId = "vol-1",
                    firstName = "Vol",
                    lastName = "U",
                    email = "vol@example.com",
                    organizationId = organizationId,
                    roles = listOf(Role.VOLUNTEER),
                )

            assertIs<ExportOutcome.Forbidden>(service.exportOrganization(volunteerAuth, organizationId, null))
        }

    @Test
    fun `GIVEN unknown org WHEN export THEN not found`() =
        runTest {
            val organizationSyncDAO = mockk<OrganizationSyncDAO>()
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val service = buildService(organizationSyncDAO = organizationSyncDAO)

            assertIs<ExportOutcome.NotFound>(service.exportOrganization(adminAuth(), organizationId, null))
        }
}

@file:OptIn(kotlin.time.ExperimentalTime::class)

package sync

import authentication.AuthenticatedInfo
import authentication.Role
import i18n.DEFAULT_LANGUAGE
import id.toId
import io.mockk.CapturingSlot
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.Change
import persistence.changes.MemberPayload
import persistence.changes.OrganizationExport
import persistence.changes.OrganizationExportScopes
import persistence.changes.OrganizationPayload
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.DeliveryReminders
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Instant

internal class ImportServiceTest {
    private val targetOrgId = "target-org"
    private val sourceOrgId = "source-org"
    private val now = Instant.fromEpochMilliseconds(1_000L)

    private val targetOrganization =
        Organization(
            organizationId = targetOrgId.toId(),
            name = "Target Shell",
            contactEmail = "shell@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = DEFAULT_LANGUAGE,
            createdInstant = now,
            lastUpdatedInstant = now,
        )

    private val sourceOrganization =
        Organization(
            organizationId = sourceOrgId.toId(),
            name = "Imported AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = DEFAULT_LANGUAGE,
            createdInstant = now,
            lastUpdatedInstant = now,
        )

    private val sourceMember =
        Member(
            memberId = "member-1".toId(),
            organizationId = sourceOrgId.toId(),
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

    private fun adminAuth(orgId: String? = targetOrgId) =
        AuthenticatedInfo(
            memberId = "admin-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = orgId,
            roles = listOf(Role.ADMIN),
        )

    private fun archive(
        organization: Organization = sourceOrganization,
        members: List<Member> = listOf(sourceMember),
        formatVersion: Int = OrganizationExport.CURRENT_FORMAT_VERSION,
    ) = OrganizationExport(
        formatVersion = formatVersion,
        exportedAt = now,
        sourceInstance = "Source",
        organizationId = sourceOrgId,
        scopes =
            OrganizationExportScopes(
                organization = listOf(OrganizationPayload(organization)) + members.map { MemberPayload(it) },
            ),
    )

    private fun buildService(
        organizationSyncDAO: OrganizationSyncDAO = emptyOrgDao(),
        producerAccountSyncDAO: ProducerAccountSyncDAO = mockk(relaxed = true),
        memberSyncDAO: MemberSyncDAO = emptyMemberDao(),
        contractSyncDAO: ContractSyncDAO = mockk(relaxed = true),
        deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO = mockk(relaxed = true),
        basketExchangeSyncDAO: BasketExchangeSyncDAO = mockk(relaxed = true),
        memberInvitationDAO: MemberInvitationSyncDAO = mockk(relaxed = true),
        memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO = mockk(relaxed = true),
        productTypeDAO: ProductTypeSyncDAO = mockk(relaxed = true),
    ) = ImportService(
        organizationSyncDAO,
        producerAccountSyncDAO,
        memberSyncDAO,
        contractSyncDAO,
        deliveryTemplateSyncDAO,
        basketExchangeSyncDAO,
        memberInvitationDAO,
        memberJoinRequestSyncDAO,
        productTypeDAO,
    )

    private fun emptyOrgDao(): OrganizationSyncDAO =
        mockk(relaxed = true) {
            coEvery { getById(targetOrgId.toId<Organization>()) } returns targetOrganization
        }

    private fun emptyMemberDao(): MemberSyncDAO =
        mockk(relaxed = true) {
            coEvery { getByOrganizationId(any()) } returns emptyList()
            coEvery { findOrganizationIdBySub(any()) } returns null
        }

    @Test
    fun `GIVEN empty target WHEN import THEN writes entities with rewritten org id and returns counts`() =
        runTest {
            val memberChanges: CapturingSlot<List<Change>> = slot()
            val capturedMember = slot<Member>()
            val memberSyncDAO =
                mockk<MemberSyncDAO>(relaxed = true) {
                    coEvery { getByOrganizationId(any()) } returns emptyList()
                    coEvery { findOrganizationIdBySub(any()) } returns null
                    coEvery { put(capture(capturedMember), capture(memberChanges)) } returns Unit
                }
            val capturedOrg = slot<Organization>()
            val organizationSyncDAO =
                mockk<OrganizationSyncDAO>(relaxed = true) {
                    coEvery { getById(targetOrgId.toId<Organization>()) } returns targetOrganization
                    coEvery { put(capture(capturedOrg), any()) } returns Unit
                }

            val service = buildService(organizationSyncDAO = organizationSyncDAO, memberSyncDAO = memberSyncDAO)

            val outcome = service.importIntoOrganization(adminAuth(), targetOrgId, archive())

            val success = assertIs<ImportOutcome.Success>(outcome)
            assertEquals(1, success.result.members)
            assertEquals(1, success.result.organizations)
            // org id rewritten source -> target on both the org aggregate and the member
            assertEquals(targetOrgId, capturedOrg.captured.organizationId.id)
            assertEquals(targetOrgId, capturedMember.captured.organizationId.id)
            // change scope key targets the destination org
            assertEquals("organization:$targetOrgId", memberChanges.captured.single().scopeKey)
        }

    @Test
    fun `GIVEN admin of a different org WHEN import THEN forbidden`() =
        runTest {
            val service = buildService()

            val outcome = service.importIntoOrganization(adminAuth(orgId = "other"), targetOrgId, archive())

            assertIs<ImportOutcome.Forbidden>(outcome)
        }

    @Test
    fun `GIVEN unknown target org WHEN import THEN not found`() =
        runTest {
            val organizationSyncDAO =
                mockk<OrganizationSyncDAO>(relaxed = true) {
                    coEvery { getById(any()) } returns null
                }
            val service = buildService(organizationSyncDAO = organizationSyncDAO)

            assertIs<ImportOutcome.NotFound>(service.importIntoOrganization(adminAuth(), targetOrgId, archive()))
        }

    @Test
    fun `GIVEN non-empty target WHEN import THEN conflict`() =
        runTest {
            val memberSyncDAO =
                mockk<MemberSyncDAO>(relaxed = true) {
                    coEvery { getByOrganizationId(any()) } returns listOf(sourceMember)
                    coEvery { findOrganizationIdBySub(any()) } returns null
                }
            val service = buildService(memberSyncDAO = memberSyncDAO)

            assertIs<ImportOutcome.Conflict>(service.importIntoOrganization(adminAuth(), targetOrgId, archive()))
        }

    @Test
    fun `GIVEN unsupported format version WHEN import THEN invalid format`() =
        runTest {
            val service = buildService()

            val outcome = service.importIntoOrganization(adminAuth(), targetOrgId, archive(formatVersion = 999))

            assertIs<ImportOutcome.InvalidFormat>(outcome)
        }
}

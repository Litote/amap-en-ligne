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
import persistence.changes.MemberInvitationPayload
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
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.AccessibilityOptions
import persistence.model.DeliveryReminders
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
import persistence.model.Organization
import persistence.model.Owner
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.hours
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
        invitations: List<MemberInvitation> = emptyList(),
        formatVersion: Int = OrganizationExport.CURRENT_FORMAT_VERSION,
    ) = OrganizationExport(
        formatVersion = formatVersion,
        exportedAt = now,
        sourceInstance = "Source",
        organizationId = sourceOrgId,
        scopes =
            OrganizationExportScopes(
                organization =
                    listOf(OrganizationPayload(organization)) +
                        members.map { MemberPayload(it) } +
                        invitations.map { MemberInvitationPayload(it) },
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
        ownerSyncDAO: OwnerSyncDAO = emptyOwnerDao(),
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
        ownerSyncDAO,
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

    private fun emptyOwnerDao(): OwnerSyncDAO =
        mockk(relaxed = true) {
            coEvery { listAll() } returns emptyList()
        }

    private fun ownerDaoWithEmails(vararg emails: String): OwnerSyncDAO =
        mockk(relaxed = true) {
            coEvery { listAll() } returns emails.map { ownerWithEmail(it) }
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
    fun `GIVEN target with existing members WHEN import THEN succeeds and merges members`() =
        runTest {
            val memberSyncDAO =
                mockk<MemberSyncDAO>(relaxed = true) {
                    coEvery { getByOrganizationId(any()) } returns listOf(sourceMember)
                    coEvery { findOrganizationIdBySub(any()) } returns null
                }
            val service = buildService(memberSyncDAO = memberSyncDAO)

            assertIs<ImportOutcome.Success>(service.importIntoOrganization(adminAuth(), targetOrgId, archive()))
        }

    @Test
    fun `GIVEN unsupported format version WHEN import THEN invalid format`() =
        runTest {
            val service = buildService()

            val outcome = service.importIntoOrganization(adminAuth(), targetOrgId, archive(formatVersion = 999))

            assertIs<ImportOutcome.InvalidFormat>(outcome)
        }

    @Test
    fun `GIVEN imported member with email and no invitation WHEN import THEN generates a PENDING_ACTIVATION invitation`() =
        runTest {
            val captured = mutableListOf<MemberInvitation>()
            val memberInvitationDAO =
                mockk<MemberInvitationSyncDAO>(relaxed = true) {
                    coEvery { put(capture(captured), any()) } returns Unit
                }
            val service = buildService(memberInvitationDAO = memberInvitationDAO)

            val outcome =
                service.importIntoOrganization(
                    adminAuth(),
                    targetOrgId,
                    archive(members = listOf(memberWithEmail("alice@example.com", "m-alice", "Alice", "Durand"))),
                )

            val success = assertIs<ImportOutcome.Success>(outcome)
            assertEquals(1, success.result.generatedInvitations)
            val generated = captured.single()
            assertEquals("alice@example.com", generated.email)
            assertEquals(MemberInvitationStatus.PENDING_ACTIVATION, generated.status)
            assertEquals("Alice", generated.firstName)
            assertEquals("Durand", generated.lastName)
            assertEquals(targetOrgId, generated.organizationId.id)
        }

    @Test
    fun `GIVEN imported member whose email already has an imported invitation WHEN import THEN does not duplicate`() =
        runTest {
            val captured = mutableListOf<MemberInvitation>()
            val memberInvitationDAO =
                mockk<MemberInvitationSyncDAO>(relaxed = true) {
                    coEvery { put(capture(captured), any()) } returns Unit
                }
            val service = buildService(memberInvitationDAO = memberInvitationDAO)

            val outcome =
                service.importIntoOrganization(
                    adminAuth(),
                    targetOrgId,
                    archive(
                        // Member email differs only by case — dedup is case-insensitive.
                        members = listOf(memberWithEmail("Bob@Example.com", "m-bob", "Bob", "Martin")),
                        invitations = listOf(importedInvitation("bob@example.com")),
                    ),
                )

            val success = assertIs<ImportOutcome.Success>(outcome)
            assertEquals(0, success.result.generatedInvitations)
            // Only the imported invitation is written; no auto-generated one for the same email.
            assertEquals(1, captured.size)
            assertTrue(captured.all { it.email.equals("bob@example.com", ignoreCase = true) })
        }

    @Test
    fun `GIVEN imported member without email WHEN import THEN generates no invitation`() =
        runTest {
            val captured = mutableListOf<MemberInvitation>()
            val memberInvitationDAO =
                mockk<MemberInvitationSyncDAO>(relaxed = true) {
                    coEvery { put(capture(captured), any()) } returns Unit
                }
            val service = buildService(memberInvitationDAO = memberInvitationDAO)

            // sourceMember carries no email.
            val outcome = service.importIntoOrganization(adminAuth(), targetOrgId, archive())

            val success = assertIs<ImportOutcome.Success>(outcome)
            assertEquals(0, success.result.generatedInvitations)
            assertTrue(captured.isEmpty())
        }

    @Test
    fun `GIVEN imported member whose email already belongs to an owner WHEN import THEN skips member and invitation and warns`() =
        runTest {
            val capturedMembers = mutableListOf<Member>()
            val memberSyncDAO =
                mockk<MemberSyncDAO>(relaxed = true) {
                    coEvery { getByOrganizationId(any()) } returns emptyList()
                    coEvery { findOrganizationIdBySub(any()) } returns null
                    coEvery { put(capture(capturedMembers), any()) } returns Unit
                }
            val capturedInvitations = mutableListOf<MemberInvitation>()
            val memberInvitationDAO =
                mockk<MemberInvitationSyncDAO>(relaxed = true) {
                    coEvery { put(capture(capturedInvitations), any()) } returns Unit
                }
            val service =
                buildService(
                    memberSyncDAO = memberSyncDAO,
                    memberInvitationDAO = memberInvitationDAO,
                    // Owner email differs only by case — the collision is case-insensitive.
                    ownerSyncDAO = ownerDaoWithEmails("Owner@Example.com"),
                )

            val outcome =
                service.importIntoOrganization(
                    adminAuth(),
                    targetOrgId,
                    archive(
                        members =
                            listOf(
                                memberWithEmail("owner@example.com", "m-owner", "Conflict", "Owner"),
                                memberWithEmail("alice@example.com", "m-alice", "Alice", "Durand"),
                            ),
                    ),
                )

            val success = assertIs<ImportOutcome.Success>(outcome)
            // The owner-colliding member is not imported; only the clean one is.
            assertEquals(1, success.result.members)
            assertTrue(capturedMembers.none { it.email.equals("owner@example.com", ignoreCase = true) })
            // No invitation generated for the owner-colliding email; only the clean one.
            assertEquals(1, success.result.generatedInvitations)
            assertTrue(capturedInvitations.none { it.email.equals("owner@example.com", ignoreCase = true) })
            // The collision is surfaced as a warning mentioning the email.
            assertEquals(1, success.result.warnings.size)
            assertTrue(
                success.result.warnings
                    .single()
                    .contains("owner@example.com"),
            )
        }

    private fun memberWithEmail(
        email: String,
        memberId: String,
        firstName: String,
        lastName: String,
    ): Member =
        sourceMember.copy(
            memberId = memberId.toId(),
            email = email,
            firstName = firstName,
            lastName = lastName,
            roles = setOf(Role.VOLUNTEER),
        )

    private fun ownerWithEmail(email: String): Owner =
        Owner(
            ownerId = "owner-${email.substringBefore('@')}".toId(),
            firstName = "Existing",
            lastName = "Owner",
            email = email,
            registeredAt = now,
            updatedAt = now,
        )

    private fun importedInvitation(email: String): MemberInvitation =
        MemberInvitation(
            invitationId = "inv-${email.substringBefore('@')}",
            organizationId = sourceOrgId.toId(),
            email = email,
            firstName = "Imported",
            lastName = "Invitee",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = now,
            expiresAt = now + 168.hours,
        )
}

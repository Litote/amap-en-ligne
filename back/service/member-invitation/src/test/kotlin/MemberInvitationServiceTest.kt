@file:OptIn(ExperimentalTime::class)

package memberinvitation

import authentication.AuthenticatedInfo
import authentication.Role
import email.MemberInvitationEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MemberInvitationPayload
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.Organization
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime

internal class MemberInvitationServiceTest {
    private val memberInvitationDAO = mockk<MemberInvitationSyncDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val memberInvitationEmailPort = mockk<MemberInvitationEmailPort>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val service =
        MemberInvitationService(
            memberInvitationDAO = memberInvitationDAO,
            memberSyncDAO = memberSyncDAO,
            activationTokenDAO = activationTokenDAO,
            memberInvitationEmailPort = memberInvitationEmailPort,
            organizationSyncDAO = organizationSyncDAO,
        )

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-sub",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = "org-123",
            roles = listOf(Role.ADMIN),
        )

    private fun buildInvitation(invitationId: String = "tmp_1"): MemberInvitation {
        val now = Clock.System.now()
        return MemberInvitation(
            invitationId = invitationId,
            organizationId = "org-123".toId(),
            email = "alice@example.com",
            firstName = "Alice",
            lastName = "Martin",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = now,
            expiresAt = now + 168.hours,
        )
    }

    @Test
    fun `GIVEN tmp invitation WHEN applyUpsert THEN creates row token and email`() =
        runTest {
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberInvitationDAO.findPendingByEmail(any()) } returns null

            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                    payload = MemberInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotEquals("tmp_1", outcome.serverEntityId)

            val invitationSlot = slot<MemberInvitation>()
            val tokenSlot = slot<ActivationToken>()
            coVerify { memberInvitationDAO.put(capture(invitationSlot), any()) }
            coVerify { activationTokenDAO.create(capture(tokenSlot)) }
            coVerify { memberInvitationEmailPort.sendInvitationEmail(any(), any(), any()) }
            assertEquals(MemberInvitationStatus.PENDING_ACTIVATION, invitationSlot.captured.status)
            assertEquals(ActivationKind.MEMBER, tokenSlot.captured.kind)
        }

    @Test
    fun `GIVEN existing member email WHEN applyUpsert THEN rejects with unique violation`() =
        runTest {
            coEvery {
                memberSyncDAO.getByOrganizationId(any())
            } returns
                listOf(
                    mockk<Member> {
                        coEvery { email } returns "alice@example.com"
                    },
                )

            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                    payload = MemberInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(persistence.changes.MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN non-expired pending invitation for email in another org WHEN createInvitation THEN rejects with unique violation`() =
        runTest {
            // The constraint is global: a user can only belong to one AMAP at a time.
            // A non-expired pending invitation for the same email in a different organization must be rejected.
            val existingInvitation = buildInvitation("inv-existing")
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberInvitationDAO.findPendingByEmail(any()) } returns existingInvitation

            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                    payload = MemberInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(persistence.changes.MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN expired pending invitation for email WHEN createInvitation THEN cancels old invitation and creates new one`() =
        runTest {
            val now = Clock.System.now()
            val expiredInvitation = buildInvitation("inv-expired").copy(expiresAt = now - 1.hours)
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberInvitationDAO.findPendingByEmail(any()) } returns expiredInvitation

            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                    payload = MemberInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotEquals("tmp_1", outcome.serverEntityId)

            // Capture all put calls: first is the cancel, second is the new invitation
            val capturedInvitations = mutableListOf<MemberInvitation>()
            coVerify(exactly = 2) { memberInvitationDAO.put(capture(capturedInvitations), any()) }
            assertEquals(MemberInvitationStatus.CANCELLED, capturedInvitations[0].status)
            assertEquals("inv-expired", capturedInvitations[0].invitationId)

            // Verify the old token was invalidated and new one created
            coVerify { activationTokenDAO.invalidateByMemberInvitationId("inv-expired".toId(), any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { memberInvitationEmailPort.sendInvitationEmail(any(), any(), any()) }
        }

    @Test
    fun `GIVEN DAO throws DuplicatePendingInvitationException WHEN createInvitation THEN rejects with unique violation`() =
        runTest {
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberInvitationDAO.findPendingByEmail(any()) } returns null
            coEvery { memberInvitationDAO.put(any(), any()) } throws persistence.dao.DuplicatePendingInvitationException()

            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                    payload = MemberInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(persistence.changes.MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN existing invitation with newer resend_requested_at WHEN applyUpsert THEN invalidates old tokens and resends`() =
        runTest {
            val persisted = buildInvitation("inv-1")
            coEvery { memberInvitationDAO.findById("inv-1") } returns persisted

            val resendAt = Clock.System.now()
            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation =
                        ClientMutation(
                            "op-2",
                            Upsert(
                                MemberInvitationPayload(
                                    persisted.copy(resendRequestedAt = resendAt),
                                ),
                            ),
                        ),
                    payload = MemberInvitationPayload(persisted.copy(resendRequestedAt = resendAt)),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { activationTokenDAO.invalidateByMemberInvitationId("inv-1".toId(), any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { memberInvitationEmailPort.sendInvitationEmail(any(), any(), any()) }
        }

    @Test
    fun `GIVEN an organization name WHEN createInvitation THEN it is passed to the invitation email`() =
        runTest {
            coEvery { memberSyncDAO.getByOrganizationId(any()) } returns emptyList()
            coEvery { memberInvitationDAO.findPendingByEmail(any()) } returns null
            coEvery { organizationSyncDAO.getById(any()) } returns
                mockk<Organization>(relaxed = true) { coEvery { name } returns "AMAP des Collines" }

            service.applyUpsert(
                auth = adminAuth,
                mutation = ClientMutation("op-1", Upsert(MemberInvitationPayload(buildInvitation()))),
                payload = MemberInvitationPayload(buildInvitation()),
            )

            val nameSlot = slot<String>()
            coVerify { memberInvitationEmailPort.sendInvitationEmail(any(), any(), capture(nameSlot)) }
            assertEquals("AMAP des Collines", nameSlot.captured)
        }

    @Test
    fun `GIVEN resend with custom subject and body WHEN applyUpsert THEN persists and sends the custom copy`() =
        runTest {
            val persisted = buildInvitation("inv-1")
            coEvery { memberInvitationDAO.findById("inv-1") } returns persisted

            val resendAt = Clock.System.now()
            val incoming =
                persisted.copy(
                    resendRequestedAt = resendAt,
                    customEmailSubject = "Connecte-toi",
                    customEmailBody = "Merci de finaliser ton inscription.",
                )
            val outcome =
                service.applyUpsert(
                    auth = adminAuth,
                    mutation = ClientMutation("op-9", Upsert(MemberInvitationPayload(incoming))),
                    payload = MemberInvitationPayload(incoming),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val savedSlot = slot<MemberInvitation>()
            val sentSlot = slot<MemberInvitation>()
            coVerify { memberInvitationDAO.put(capture(savedSlot), any()) }
            coVerify { memberInvitationEmailPort.sendInvitationEmail(capture(sentSlot), any(), any()) }
            assertEquals("Connecte-toi", savedSlot.captured.customEmailSubject)
            assertEquals("Merci de finaliser ton inscription.", savedSlot.captured.customEmailBody)
            assertEquals("Connecte-toi", sentSlot.captured.customEmailSubject)
            assertEquals("Merci de finaliser ton inscription.", sentSlot.captured.customEmailBody)
        }

    @Test
    fun `GIVEN pending invitation WHEN applyDelete THEN marks it CANCELLED`() =
        runTest {
            val invitation = buildInvitation("inv-2")
            coEvery { memberInvitationDAO.findById("inv-2") } returns invitation

            val outcome =
                service.applyDelete(
                    auth = adminAuth,
                    mutation = ClientMutation("op-3", Delete(persistence.model.EntityType.MemberInvitation, "inv-2")),
                    op = Delete(persistence.model.EntityType.MemberInvitation, "inv-2"),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val updatedSlot = slot<MemberInvitation>()
            coVerify { memberInvitationDAO.put(capture(updatedSlot), any()) }
            assertEquals(MemberInvitationStatus.CANCELLED, updatedSlot.captured.status)
            coVerify { activationTokenDAO.invalidateByMemberInvitationId("inv-2".toId(), any()) }
        }
}

@file:OptIn(ExperimentalTime::class)

package owner

import authentication.AuthenticatedInfo
import authentication.Role
import email.OwnerActivationEmailPort
import id.Id
import id.generateId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationStatus
import persistence.changes.OwnerInvitationPayload
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

internal class OwnerInvitationServiceTest {
    private val ownerInvitationDAO = mockk<OwnerInvitationSyncDAO>(relaxed = true)
    private val ownerDAO = mockk<OwnerSyncDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val ownerActivationEmailPort = mockk<OwnerActivationEmailPort>(relaxed = true)

    private val service =
        OwnerInvitationService(
            ownerInvitationDAO,
            ownerDAO,
            activationTokenDAO,
            ownerActivationEmailPort,
        )

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "owner-sub",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            roles = listOf(Role.OWNER),
        )

    private fun buildInvitation(id: String = "tmp_owner"): OwnerInvitation =
        OwnerInvitation(
            invitationId = Id(id),
            firstName = "Alice",
            lastName = "Dupont",
            email = "alice@example.com",
            status = OwnerInvitationStatus.PENDING_ACTIVATION,
            submittedAt = Clock.System.now(),
        )

    @Test
    fun `GIVEN tmp invitation WHEN applyUpsert THEN creates invitation token and email`() =
        runTest {
            coEvery { ownerDAO.existsByEmail(any()) } returns false
            coEvery { ownerInvitationDAO.existsPendingByEmail(any()) } returns false

            val outcome =
                service.applyUpsert(
                    auth = ownerAuth,
                    mutation = ClientMutation("op-1", Upsert(OwnerInvitationPayload(buildInvitation()))),
                    payload = OwnerInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotEquals("tmp_owner", outcome.serverEntityId)

            val invitationSlot = slot<OwnerInvitation>()
            val tokenSlot = slot<ActivationToken>()
            coVerify { ownerInvitationDAO.put(capture(invitationSlot), any()) }
            coVerify { activationTokenDAO.create(capture(tokenSlot)) }
            assertEquals(OwnerInvitationStatus.PENDING_ACTIVATION, invitationSlot.captured.status)
            assertEquals(ActivationKind.OWNER, tokenSlot.captured.kind)
        }

    @Test
    fun `GIVEN duplicate owner email WHEN applyUpsert THEN rejects`() =
        runTest {
            coEvery { ownerDAO.existsByEmail("alice@example.com") } returns true

            val outcome =
                service.applyUpsert(
                    auth = ownerAuth,
                    mutation = ClientMutation("op-1", Upsert(OwnerInvitationPayload(buildInvitation()))),
                    payload = OwnerInvitationPayload(buildInvitation()),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(persistence.changes.MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
        }

    @Test
    fun `GIVEN existing invitation with newer resend_requested_at WHEN applyUpsert THEN invalidates old token and resends`() =
        runTest {
            val invitation = buildInvitation("owner-inv-1")
            val resendAt = Clock.System.now()
            coEvery { ownerInvitationDAO.findById(invitation.invitationId) } returns invitation

            val outcome =
                service.applyUpsert(
                    auth = ownerAuth,
                    mutation =
                        ClientMutation(
                            "op-2",
                            Upsert(OwnerInvitationPayload(invitation.copy(resendRequestedAt = resendAt))),
                        ),
                    payload = OwnerInvitationPayload(invitation.copy(resendRequestedAt = resendAt)),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { activationTokenDAO.invalidateByOwnerInvitationId(invitation.invitationId, any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { ownerActivationEmailPort.sendOwnerActivationEmail(any(), any()) }
        }

    @Test
    fun `GIVEN pending invitation WHEN applyDelete THEN marks it CANCELLED`() =
        runTest {
            val invitation = buildInvitation("owner-inv-2")
            coEvery { ownerInvitationDAO.findById(invitation.invitationId) } returns invitation

            val outcome =
                service.applyDelete(
                    auth = ownerAuth,
                    mutation = ClientMutation("op-3", Delete(persistence.model.EntityType.OwnerInvitation, invitation.invitationId.id)),
                    op = Delete(persistence.model.EntityType.OwnerInvitation, invitation.invitationId.id),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            val invitationSlot = slot<OwnerInvitation>()
            coVerify { ownerInvitationDAO.put(capture(invitationSlot), any()) }
            assertEquals(OwnerInvitationStatus.CANCELLED, invitationSlot.captured.status)
            coVerify { activationTokenDAO.invalidateByOwnerInvitationId(invitation.invitationId, any()) }
        }
}

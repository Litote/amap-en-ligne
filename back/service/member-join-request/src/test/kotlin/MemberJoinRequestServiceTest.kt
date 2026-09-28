@file:OptIn(ExperimentalTime::class)

package memberjoinrequest

import authentication.AuthenticatedInfo
import authentication.Role
import email.MemberInvitationEmailPort
import email.MemberJoinRequestRejectionEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.ActivationTokenDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

internal class MemberJoinRequestServiceTest {
    private val memberJoinRequestSyncDAO = mockk<MemberJoinRequestSyncDAO>(relaxed = true)
    private val memberJoinRequestDAO = mockk<MemberJoinRequestDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val memberInvitationDAO = mockk<MemberInvitationSyncDAO>(relaxed = true)
    private val activationTokenDAO = mockk<ActivationTokenDAO>(relaxed = true)
    private val memberInvitationEmailPort = mockk<MemberInvitationEmailPort>(relaxed = true)
    private val rejectionEmailPort = mockk<MemberJoinRequestRejectionEmailPort>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val service =
        MemberJoinRequestService(
            memberJoinRequestSyncDAO = memberJoinRequestSyncDAO,
            memberJoinRequestDAO = memberJoinRequestDAO,
            memberSyncDAO = memberSyncDAO,
            memberInvitationDAO = memberInvitationDAO,
            activationTokenDAO = activationTokenDAO,
            memberInvitationEmailPort = memberInvitationEmailPort,
            rejectionEmailPort = rejectionEmailPort,
            organizationSyncDAO = organizationSyncDAO,
        )

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-sub",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = "org-1",
            roles = listOf(Role.ADMIN),
        )

    private fun buildRequest(status: MemberJoinRequestStatus = MemberJoinRequestStatus.PENDING): MemberJoinRequest =
        MemberJoinRequest(
            requestId = "mjreq-1".toId(),
            organizationId = "org-1".toId(),
            email = "alice@example.com",
            firstName = "Alice",
            lastName = "Martin",
            status = status,
            submittedAt = Clock.System.now(),
        )

    @Test
    fun `GIVEN pending request WHEN approve THEN creates invitation token and marks request approved without creating member`() =
        runTest {
            val existing = buildRequest()
            coEvery { memberJoinRequestDAO.findById(existing.requestId) } returns existing
            coEvery { memberSyncDAO.getByOrganizationId(existing.organizationId) } returns emptyList()
            coEvery { memberInvitationDAO.listByOrganizationId(existing.organizationId) } returns emptyList()

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    ClientMutation("op-1", Upsert(MemberJoinRequestPayload(existing.copy(status = MemberJoinRequestStatus.APPROVED)))),
                    MemberJoinRequestPayload(existing.copy(status = MemberJoinRequestStatus.APPROVED)),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { memberSyncDAO.put(any(), any()) }
            coVerify { memberInvitationDAO.put(match { it.status == MemberInvitationStatus.PENDING_ACTIVATION }, any()) }
            coVerify { activationTokenDAO.create(any()) }
            coVerify { memberInvitationEmailPort.sendInvitationEmail(any(), any(), any()) }
            coVerify { memberJoinRequestSyncDAO.put(match { it.status == MemberJoinRequestStatus.APPROVED }, any()) }
        }

    @Test
    fun `GIVEN pending request WHEN reject THEN stores review metadata and sends rejection notification`() =
        runTest {
            val existing = buildRequest()
            coEvery { memberJoinRequestDAO.findById(existing.requestId) } returns existing

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    ClientMutation(
                        "op-2",
                        Upsert(
                            MemberJoinRequestPayload(
                                existing.copy(
                                    status = MemberJoinRequestStatus.REJECTED,
                                    reviewComment = "No spots available",
                                ),
                            ),
                        ),
                    ),
                    MemberJoinRequestPayload(
                        existing.copy(
                            status = MemberJoinRequestStatus.REJECTED,
                            reviewComment = "No spots available",
                        ),
                    ),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify {
                memberJoinRequestSyncDAO.put(
                    match {
                        it.status == MemberJoinRequestStatus.REJECTED &&
                            it.reviewComment == "No spots available" &&
                            it.reviewedAt != null
                    },
                    any(),
                )
            }
            coVerify { rejectionEmailPort.sendRejectionEmail(match { it.status == MemberJoinRequestStatus.REJECTED }, any()) }
        }

    @Test
    fun `GIVEN pending request for another org WHEN applyUpsert THEN rejects forbidden`() =
        runTest {
            val existing = buildRequest().copy(organizationId = "org-2".toId())
            val payload = existing.copy(status = MemberJoinRequestStatus.APPROVED)
            coEvery { memberJoinRequestDAO.findById(existing.requestId) } returns existing

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    ClientMutation("op-3", Upsert(MemberJoinRequestPayload(payload))),
                    MemberJoinRequestPayload(payload),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN already processed request WHEN applyUpsert THEN rejects conflict`() =
        runTest {
            val existing = buildRequest(MemberJoinRequestStatus.APPROVED)
            coEvery { memberJoinRequestDAO.findById(existing.requestId) } returns existing

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    ClientMutation("op-4", Upsert(MemberJoinRequestPayload(existing))),
                    MemberJoinRequestPayload(existing),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
        }

    @Test
    fun `GIVEN approved join request with CANCELLED invitation WHEN approve second join request THEN applied`() =
        runTest {
            val existing = buildRequest()
            val now = Clock.System.now()
            val cancelledInvitation =
                MemberInvitation(
                    invitationId = "inv-cancelled",
                    organizationId = existing.organizationId,
                    email = existing.email,
                    firstName = existing.firstName,
                    lastName = existing.lastName,
                    roles = setOf(authentication.Role.VOLUNTEER),
                    status = MemberInvitationStatus.CANCELLED,
                    createdAt = now,
                    expiresAt = now,
                )
            coEvery { memberJoinRequestDAO.findById(existing.requestId) } returns existing
            coEvery { memberSyncDAO.getByOrganizationId(existing.organizationId) } returns emptyList()
            coEvery { memberInvitationDAO.listByOrganizationId(existing.organizationId) } returns listOf(cancelledInvitation)

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    ClientMutation("op-5", Upsert(MemberJoinRequestPayload(existing.copy(status = MemberJoinRequestStatus.APPROVED)))),
                    MemberJoinRequestPayload(existing.copy(status = MemberJoinRequestStatus.APPROVED)),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }
}

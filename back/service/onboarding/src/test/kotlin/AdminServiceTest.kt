@file:OptIn(ExperimentalTime::class)

package onboarding

import id.generateId
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.dao.MemberJoinRequestDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

internal class AdminServiceTest {
    private val memberJoinRequestDAO = mockk<MemberJoinRequestDAO>(relaxed = true)
    private val service = AdminService(memberJoinRequestDAO)

    private fun buildPendingMemberJoinRequest(orgId: String = "org-1"): MemberJoinRequest =
        MemberJoinRequest(
            requestId = generateId(),
            organizationId = orgId.toId<Organization>(),
            email = "alice@example.com",
            firstName = "Alice",
            lastName = "Martin",
            status = MemberJoinRequestStatus.PENDING,
            submittedAt = Clock.System.now(),
        )

    @Test
    fun `GIVEN pending member join request WHEN approveMemberJoinRequest THEN status is updated to APPROVED`() =
        runTest {
            val orgId = "org-1"
            val request = buildPendingMemberJoinRequest(orgId)
            coEvery { memberJoinRequestDAO.findById(request.requestId) } returns request

            val result = service.approveMemberJoinRequest(orgId.toId<Organization>(), request.requestId)

            coVerify {
                memberJoinRequestDAO.updateStatus(request.requestId, MemberJoinRequestStatus.APPROVED, any(), null)
            }
            assertIs<MemberJoinRequestOutcome.Success>(result)
            assertEquals(MemberJoinRequestStatus.APPROVED, result.request.status)
        }

    @Test
    fun `GIVEN unknown member join request id WHEN approveMemberJoinRequest THEN returns NotFound`() =
        runTest {
            coEvery { memberJoinRequestDAO.findById(any()) } returns null

            val result = service.approveMemberJoinRequest("org-1".toId<Organization>(), generateId())

            assertIs<MemberJoinRequestOutcome.NotFound>(result)
        }

    @Test
    fun `GIVEN already-processed member join request WHEN approveMemberJoinRequest THEN returns AlreadyProcessed`() =
        runTest {
            val request = buildPendingMemberJoinRequest().copy(status = MemberJoinRequestStatus.APPROVED)
            coEvery { memberJoinRequestDAO.findById(request.requestId) } returns request

            val result = service.approveMemberJoinRequest("org-1".toId<Organization>(), request.requestId)

            assertIs<MemberJoinRequestOutcome.AlreadyProcessed>(result)
        }

    @Test
    fun `GIVEN pending member join request WHEN rejectMemberJoinRequest THEN status is updated to REJECTED with comment`() =
        runTest {
            val orgId = "org-1"
            val request = buildPendingMemberJoinRequest(orgId)
            val reviewComment = "No spots available"
            coEvery { memberJoinRequestDAO.findById(request.requestId) } returns request

            val result = service.rejectMemberJoinRequest(orgId.toId<Organization>(), request.requestId, reviewComment)

            coVerify {
                memberJoinRequestDAO.updateStatus(
                    request.requestId,
                    MemberJoinRequestStatus.REJECTED,
                    any(),
                    reviewComment,
                )
            }
            assertIs<MemberJoinRequestOutcome.Success>(result)
            assertEquals(MemberJoinRequestStatus.REJECTED, result.request.status)
            assertEquals(reviewComment, result.request.reviewComment)
        }
}

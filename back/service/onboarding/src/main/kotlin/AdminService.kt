@file:OptIn(ExperimentalTime::class)

package onboarding

import id.Id
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.dao.MemberJoinRequestDAO
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.Organization
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true)
class AdminService(
    private val memberJoinRequestDAO: MemberJoinRequestDAO,
) {
    suspend fun listMemberJoinRequests(
        organizationId: Id<Organization>,
        status: MemberJoinRequestStatus?,
    ): List<MemberJoinRequest> =
        if (status != null) {
            memberJoinRequestDAO.listByOrganizationAndStatus(organizationId, status)
        } else {
            memberJoinRequestDAO.listByOrganization(organizationId)
        }

    suspend fun approveMemberJoinRequest(
        organizationId: Id<Organization>,
        requestId: Id<MemberJoinRequest>,
    ): MemberJoinRequestOutcome {
        val request = memberJoinRequestDAO.findById(requestId) ?: return MemberJoinRequestOutcome.NotFound
        if (request.status != MemberJoinRequestStatus.PENDING) return MemberJoinRequestOutcome.AlreadyProcessed
        val now = Clock.System.now()
        memberJoinRequestDAO.updateStatus(requestId, MemberJoinRequestStatus.APPROVED, now, null)
        logger.info {
            "Member join request ${requestId.id} approved — would invite ${request.email} to org ${organizationId.id}"
        }
        return MemberJoinRequestOutcome.Success(request.copy(status = MemberJoinRequestStatus.APPROVED, reviewedAt = now))
    }

    suspend fun rejectMemberJoinRequest(
        organizationId: Id<Organization>,
        requestId: Id<MemberJoinRequest>,
        reviewComment: String?,
    ): MemberJoinRequestOutcome {
        val request = memberJoinRequestDAO.findById(requestId) ?: return MemberJoinRequestOutcome.NotFound
        if (request.status != MemberJoinRequestStatus.PENDING) return MemberJoinRequestOutcome.AlreadyProcessed
        val reviewedAt = Clock.System.now()
        memberJoinRequestDAO.updateStatus(requestId, MemberJoinRequestStatus.REJECTED, reviewedAt, reviewComment)
        logger.info { "Member join request ${requestId.id} rejected for org ${organizationId.id}" }
        return MemberJoinRequestOutcome.Success(
            request.copy(status = MemberJoinRequestStatus.REJECTED, reviewedAt = reviewedAt, reviewComment = reviewComment),
        )
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

sealed class MemberJoinRequestOutcome {
    data class Success(
        val request: MemberJoinRequest,
    ) : MemberJoinRequestOutcome()

    object NotFound : MemberJoinRequestOutcome()

    object AlreadyProcessed : MemberJoinRequestOutcome()
}

package persistence.dao

import id.Id
import persistence.model.ActivationToken
import persistence.model.MemberInvitation
import persistence.model.OrganizationRequest
import persistence.model.OwnerInvitation
import persistence.model.ProducerRequest
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@OptIn(ExperimentalTime::class)
interface ActivationTokenDAO {
    suspend fun create(token: ActivationToken)

    suspend fun findByToken(token: String): ActivationToken?

    suspend fun markActivated(
        token: String,
        activatedAt: Instant,
    )

    suspend fun invalidateByOwnerInvitationId(
        invitationId: Id<OwnerInvitation>,
        invalidatedAt: Instant,
    )

    suspend fun invalidateByMemberInvitationId(
        invitationId: Id<MemberInvitation>,
        invalidatedAt: Instant,
    )

    suspend fun invalidateByOrganizationRequestId(
        requestId: Id<OrganizationRequest>,
        invalidatedAt: Instant,
    )

    suspend fun invalidateByProducerRequestId(
        requestId: Id<ProducerRequest>,
        invalidatedAt: Instant,
    )
}

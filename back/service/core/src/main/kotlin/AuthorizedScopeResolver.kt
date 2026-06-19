package core

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.SyncScope
import persistence.dao.MemberSyncDAO
import persistence.dao.ProducerSyncDAO
import persistence.model.Producer

/**
 * Resolves the list of [SyncScope]s that a given [AuthenticatedInfo] is authorized to access,
 * and returns an enriched [AuthenticatedInfo] with [AuthenticatedInfo.organizationId] and
 * [AuthenticatedInfo.producerAccountId] populated from the DynamoDB / Postgres lookup so that
 * downstream services can use them without re-reading the JWT (which no longer carries them).
 *
 * Scope resolution rules:
 *  - PRODUCER  → lookup [Producer] by `sub` (= producerId) to find `producerAccountId`,
 *                then grant `producer-account:{producerAccountId}`
 *  - OWNER     → `owner:{sub}` + `instance-owner`
 *  - everyone else (ADMIN / MEMBER / COORDINATOR / VOLUNTEER) → DynamoDB/Postgres lookup
 *    to find the member's `organization_id`, then `organization:{orgId}` + `member:{sub}`
 */
@Single(createdAtStart = true)
class AuthorizedScopeResolver(
    private val memberSyncDAO: MemberSyncDAO,
    private val producerSyncDAO: ProducerSyncDAO,
) {
    suspend fun resolve(auth: AuthenticatedInfo): Pair<List<SyncScope>, AuthenticatedInfo> {
        if (auth.roles.contains(Role.OWNER)) {
            val scopes =
                listOf(
                    SyncScope.Owner(auth.memberId),
                    SyncScope.InstanceOwner,
                )
            return scopes to auth
        }

        if (auth.roles.contains(Role.PRODUCER)) {
            val producer =
                producerSyncDAO.findByProducerId(auth.memberId.toId<Producer>())
                    ?: return emptyList<SyncScope>() to auth
            val scopes = listOf(SyncScope.ProducerAccount(producer.producerAccountId.id))
            val enriched = auth.copy(producerAccountId = producer.producerAccountId.id)
            return scopes to enriched
        }

        // ADMIN / COORDINATOR / VOLUNTEER: resolve organizationId from the DAO
        val organizationId = memberSyncDAO.findOrganizationIdBySub(auth.memberId)
        if (organizationId == null) {
            return emptyList<SyncScope>() to auth
        }
        val scopes =
            listOf(
                SyncScope.Organization(organizationId.id),
                SyncScope.Member(auth.memberId),
            )
        val enriched = auth.copy(organizationId = organizationId.id)
        return scopes to enriched
    }
}

package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.Member
import persistence.model.Organization

interface MemberSyncDAO {
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Member>

    /**
     * Returns all member rows across all organizations.
     * Used as the OWNER bootstrap snapshot source on the `instance-owner` scope (and as the
     * deterministic fallback when an incremental diff exceeds ChangeDAO.DEFAULT_INCREMENTAL_LIMIT).
     *
     * Incremental OWNER-scope Member sync IS supported: every member write fans out an
     * `instance-owner`-scoped [Change] in addition to the `organization:{id}` one (see
     * `MemberService.buildUpsertChanges` / `buildDeleteChanges`), so an OWNER polling with a
     * cursor receives member updates through `DataService.syncScope` without a forced bootstrap.
     * Regression test: `DataServiceTest."GIVEN owner scope member cursor WHEN sync THEN owner
     * receives member changes incrementally"`.
     */
    suspend fun listAll(): List<Member>

    /**
     * Returns the organization id of the member whose [memberId] equals [sub].
     *
     * After the sub/id unification, every account-backed member is created with
     * `memberId = sub` (the auth-provider subject). This lookup is the primary
     * way [AuthorizedScopeResolver] discovers the organization scope for ADMIN /
     * MEMBER / COORDINATOR / VOLUNTEER callers at sync time, replacing the
     * former `organization_id` JWT claim.
     *
     * Returns `null` when no member row exists for the given [sub] (e.g. the
     * user was deleted or has not yet been fully activated).
     */
    suspend fun findOrganizationIdBySub(sub: String): Id<Organization>?

    /**
     * Returns all member rows whose [Member.memberId] equals [sub].
     *
     * Since [memberId] == sub by convention, this is equivalent to a
     * cross-all-orgs lookup by the auth-provider subject. Used by OWNER-scoped
     * paths to find a user's memberships (e.g. for LAST_ADMIN / MIXED_ROLES
     * checks and the role-promotion flow).
     */
    suspend fun getMembersBySub(sub: String): List<Member>

    /** Atomically writes the member and its scope change records. */
    suspend fun put(
        member: Member,
        changes: List<Change>,
    )

    /** Atomically deletes the member and records the corresponding tombstones. */
    suspend fun delete(
        memberId: Id<Member>,
        organizationId: Id<Organization>,
        changes: List<Change>,
    )

    /**
     * Atomically flips `active_status` on every Member row whose [Member.memberId]
     * equals [sub], keeps `account_status` aligned (`ACTIVE` / `SUSPENDED`),
     * and writes the supplied Changes.
     *
     * Since [memberId] == sub by convention, this is a single-row update in the
     * common single-AMAP case.
     */
    suspend fun setActiveStatusBySub(
        sub: String,
        activeStatus: Boolean,
        changes: List<Change>,
    )

    /**
     * Atomically anonymises every Member row whose [Member.memberId] equals [sub]:
     * clears member PII, forces `active_status = false`,
     * sets `account_status = SUSPENDED`, and writes the supplied Changes.
     */
    suspend fun anonymiseBySub(
        sub: String,
        changes: List<Change>,
    )
}

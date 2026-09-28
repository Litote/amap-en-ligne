package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.MemberInvitation
import persistence.model.Organization
import kotlin.time.ExperimentalTime

/**
 * Thrown by [MemberInvitationSyncDAO.put] when a concurrent or duplicate pending invitation
 * for the same email already exists. The constraint is global (no organization filter):
 * a user can only have one pending invitation across all AMAPs at a time.
 */
class DuplicatePendingInvitationException : Exception("A pending invitation already exists for this email")

@OptIn(ExperimentalTime::class)
interface MemberInvitationSyncDAO {
    /**
     * Persists an invitation and its associated change atomically.
     *
     * @throws DuplicatePendingInvitationException if a pending invitation for the same
     *   email already exists (enforced at the database level to prevent TOCTOU races).
     */
    suspend fun put(
        invitation: MemberInvitation,
        change: Change,
    )

    suspend fun findById(invitationId: String): MemberInvitation?

    suspend fun listByOrganizationId(organizationId: Id<Organization>): List<MemberInvitation>

    /**
     * Returns the PENDING_ACTIVATION invitation for [email] across all organizations, or null if none.
     * The check is global because a user can only belong to one AMAP at a time.
     */
    suspend fun findPendingByEmail(email: String): MemberInvitation?
}

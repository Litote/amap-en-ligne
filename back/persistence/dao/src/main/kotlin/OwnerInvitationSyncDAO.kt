@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import kotlin.time.ExperimentalTime

interface OwnerInvitationSyncDAO {
    suspend fun listAll(): List<OwnerInvitation>

    suspend fun put(
        invitation: OwnerInvitation,
        change: Change,
    )

    suspend fun findById(invitationId: Id<OwnerInvitation>): OwnerInvitation?

    suspend fun existsPendingByEmail(email: String): Boolean
}

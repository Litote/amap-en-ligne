@file:OptIn(ExperimentalTime::class)

package owner

import core.RoleService
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.OwnersBroadcastEvent
import id.Id
import id.generateId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MutationErrorCode
import persistence.changes.OwnerPayload
import persistence.changes.SyncScope
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.OwnerSyncDAO
import persistence.model.AccountDeletionLog
import persistence.model.AccountStatus
import persistence.model.DeletedAccountRole
import persistence.model.EntityType
import persistence.model.Owner
import java.security.MessageDigest
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

sealed class OwnerLifecycleOutcome {
    data object Success : OwnerLifecycleOutcome()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : OwnerLifecycleOutcome()

    data object NotFound : OwnerLifecycleOutcome()
}

data class OwnerProfileUpdate(
    val firstName: String,
    val lastName: String,
    val email: String,
    val phone: String?,
)

/**
 * Lifecycle operations on the OWNER role: suspend, reactivate, delete.
 *
 * Invariants:
 *  - `LAST_OWNER` — suspending or deleting the last active OWNER is rejected.
 *  - `SELF_ACTION_FORBIDDEN` — an OWNER cannot suspend, reactivate or delete
 *    their own account. The actor's identity is resolved from the JWT sub.
 *
 * Side effects (best-effort, post-commit):
 *  - `UserProvisioningPort.banUser` / `unbanUser` / `deleteUser` — propagates
 *    the lifecycle state to the auth provider.
 *  - `AccountLifecycleEmailPort` — notifies the impacted user and broadcasts a
 *    PII-free notice to the other Owners.
 *  - `AccountDeletionLogDAO.append` — durable audit log for deletions (only).
 */
@Single(createdAtStart = true)
class OwnerService(
    private val ownerDAO: OwnerSyncDAO,
    private val roleService: RoleService,
    private val userProvisioningPort: UserProvisioningPort,
    private val accountLifecycleEmailPort: AccountLifecycleEmailPort,
    private val accountDeletionLogDAO: AccountDeletionLogDAO,
) {
    suspend fun suspend(
        actorSub: String,
        ownerId: String,
    ): OwnerLifecycleOutcome = transition(actorSub, ownerId, AccountStatus.SUSPENDED)

    suspend fun reactivate(
        actorSub: String,
        ownerId: String,
    ): OwnerLifecycleOutcome = transition(actorSub, ownerId, AccountStatus.ACTIVE)

    suspend fun delete(
        actorSub: String,
        ownerId: String,
    ): OwnerLifecycleOutcome {
        val owner = ownerDAO.findById(ownerId.toOwnerId()) ?: return OwnerLifecycleOutcome.NotFound

        if (owner.ownerId.id == actorSub) {
            return rejectSelfAction("delete")
        }
        val lastOwnerError = roleService.validateLastOwner(ownerId)
        if (lastOwnerError != null) {
            return OwnerLifecycleOutcome.Rejected(lastOwnerError, "cannot delete the last active owner")
        }

        val tombstone =
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Owner,
                entityId = ownerId,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.DELETE,
                payload = null,
                producedAt = System.currentTimeMillis(),
            )
        ownerDAO.delete(owner.ownerId, tombstone)

        sideEffects(
            owner = owner,
            actorSub = actorSub,
            authAction = { userProvisioningPort.deleteUser(owner.ownerId.id) },
            emailToTarget = { accountLifecycleEmailPort.notifyAccountDeleted(it) },
            broadcastEvent = OwnersBroadcastEvent.ACCOUNT_DELETED,
            auditAction = {
                val actorOwner = ownerDAO.findBySub(actorSub)
                if (actorOwner != null) {
                    accountDeletionLogDAO.append(
                        AccountDeletionLog(
                            id = generateId(),
                            deletedSubHash = sha256(owner.ownerId.id),
                            deletedRole = DeletedAccountRole.OWNER,
                            deletedAt = Clock.System.now(),
                            actorOwnerId = actorOwner.ownerId,
                        ),
                    )
                } else {
                    logger.warn { "Could not resolve actor owner for sub=$actorSub — audit log skipped" }
                }
            },
        )

        return OwnerLifecycleOutcome.Success
    }

    /**
     * Backward-compat alias for the legacy [suspend] flow. Older callers
     * referenced [revoke] explicitly; new code should call [suspend].
     */
    suspend fun revoke(
        actorSub: String,
        ownerId: String,
    ): OwnerLifecycleOutcome = suspend(actorSub, ownerId)

    /**
     * Updates the profile fields of the OWNER identified by [actorSub].
     * Only firstName, lastName, email and phone are updated; other fields are preserved.
     */
    suspend fun updateProfile(
        actorSub: String,
        update: OwnerProfileUpdate,
    ): OwnerLifecycleOutcome {
        val owner = ownerDAO.findBySub(actorSub) ?: return OwnerLifecycleOutcome.NotFound
        val updated =
            owner.copy(
                firstName = update.firstName,
                lastName = update.lastName,
                email = update.email,
                phone = update.phone,
                updatedAt = Clock.System.now(),
            )
        val change =
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Owner,
                entityId = owner.ownerId.id,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.UPSERT,
                payload = OwnerPayload(updated),
                producedAt = System.currentTimeMillis(),
            )
        ownerDAO.put(updated, change)
        return OwnerLifecycleOutcome.Success
    }

    private suspend fun transition(
        actorSub: String,
        ownerId: String,
        target: AccountStatus,
    ): OwnerLifecycleOutcome {
        val owner = ownerDAO.findById(ownerId.toOwnerId()) ?: return OwnerLifecycleOutcome.NotFound
        if (owner.ownerId.id == actorSub) {
            return rejectSelfAction(if (target == AccountStatus.SUSPENDED) "suspend" else "reactivate")
        }
        if (target == AccountStatus.SUSPENDED) {
            val lastOwnerError = roleService.validateLastOwner(ownerId)
            if (lastOwnerError != null) {
                return OwnerLifecycleOutcome.Rejected(lastOwnerError, "cannot suspend the last active owner")
            }
        }
        if (owner.accountStatus == target) {
            // Idempotent: still fire side-effects so the auth provider stays in sync.
            // No-op on the row + Change to avoid useless writes.
        } else {
            val change =
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.Owner,
                    entityId = ownerId,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = OwnerPayload(owner.copy(accountStatus = target)),
                    producedAt = System.currentTimeMillis(),
                )
            ownerDAO.updateStatus(owner.ownerId, target, change)
        }

        sideEffects(
            owner = owner,
            actorSub = actorSub,
            authAction = {
                if (target == AccountStatus.SUSPENDED) {
                    userProvisioningPort.banUser(owner.ownerId.id)
                } else {
                    userProvisioningPort.unbanUser(owner.ownerId.id)
                }
            },
            emailToTarget = {
                if (target == AccountStatus.SUSPENDED) {
                    accountLifecycleEmailPort.notifyAccountSuspended(it)
                } else {
                    accountLifecycleEmailPort.notifyAccountReactivated(it)
                }
            },
            broadcastEvent =
                if (target == AccountStatus.SUSPENDED) {
                    OwnersBroadcastEvent.ACCOUNT_SUSPENDED
                } else {
                    OwnersBroadcastEvent.ACCOUNT_REACTIVATED
                },
            auditAction = { /* suspend/reactivate are not audited */ },
        )

        return OwnerLifecycleOutcome.Success
    }

    private suspend fun sideEffects(
        owner: Owner,
        actorSub: String,
        authAction: suspend () -> Unit,
        emailToTarget: suspend (AccountLifecycleTarget) -> Unit,
        broadcastEvent: OwnersBroadcastEvent,
        auditAction: suspend () -> Unit,
    ) {
        runCatching { authAction() }
            .onFailure { e -> logger.error(e) { "Auth provider call failed for ${owner.ownerId.id}" } }

        val target =
            AccountLifecycleTarget(
                sub = owner.ownerId.id, // ownerId == sub by convention
                email = owner.email,
                firstName = owner.firstName,
                lastName = owner.lastName,
                role = AccountLifecycleRole.OWNER,
            )
        runCatching { emailToTarget(target) }
            .onFailure { e -> logger.error(e) { "Lifecycle email to ${owner.email} failed" } }

        val actorOwner = ownerDAO.findBySub(actorSub)
        val actorEmail = actorOwner?.email ?: "(unknown actor)"
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event = broadcastEvent,
                actorOwnerEmail = actorEmail,
                impactedRole = AccountLifecycleRole.OWNER,
            )
        }.onFailure { e -> logger.error(e) { "Broadcast notification failed for $broadcastEvent" } }

        runCatching { auditAction() }
            .onFailure { e -> logger.error(e) { "Audit log write failed for ${owner.ownerId.id}" } }
    }

    private fun rejectSelfAction(verb: String): OwnerLifecycleOutcome =
        OwnerLifecycleOutcome.Rejected(
            MutationErrorCode.SELF_ACTION_FORBIDDEN,
            "an OWNER cannot $verb their own account",
        )

    private companion object {
        private val logger = KotlinLogging.logger {}

        private fun sha256(input: String): String =
            MessageDigest
                .getInstance("SHA-256")
                .digest(input.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it) }
    }
}

private fun String.toOwnerId(): Id<Owner> = Id(this)

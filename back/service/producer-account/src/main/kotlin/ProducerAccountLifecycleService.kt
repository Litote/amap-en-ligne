package produceraccount

import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.OwnersBroadcastEvent
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.MutationErrorCode
import persistence.dao.AccountDeletionLogDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.AccountDeletionLog
import persistence.model.DeletedAccountRole
import persistence.model.ProducerAccount
import persistence.model.UserPreferences

/**
 * Handles [ProducerAccount] status-lifecycle mutations:
 *  - [suspend] / [reactivate] — OWNER-driven `active_status` flip; bans / unbans linked auth users.
 *  - [delete] — OWNER-driven deletion: removes auth users, logs audit entries, flips `active_status`.
 *  - [updateProfile] — name/email/address/website/preferences update for PRODUCER self-edit and
 *    OWNER self-profile paths.
 *
 * All public methods return a [ProducerLifecycleOutcome]. Mapping that result to a
 * [persistence.changes.MutationOutcome] is the responsibility of [ProducerAccountService],
 * which has access to the [core.EntityTypeService] helper methods.
 */
@Single
class ProducerAccountLifecycleService(
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val userProvisioningPort: UserProvisioningPort,
    private val accountLifecycleEmailPort: AccountLifecycleEmailPort,
    private val accountDeletionLogDAO: AccountDeletionLogDAO,
    private val changeFactory: ProducerAccountChangeFactory,
) {
    /**
     * Suspends a producer account at the request of an OWNER. Flips
     * `active_status = false` on every denormalised row and fans out a
     * Change to each linked organisation scope + the `instance-owner` scope.
     *
     * Side-effects (best-effort): bans every linked auth user, sends a
     * suspension email to the producer, and broadcasts the event to owners.
     */
    suspend fun suspend(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome = transition(actorSub, producerAccountId, activeStatus = false)

    /** Reactivates a previously suspended producer account. Symmetric of [suspend]. */
    suspend fun reactivate(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome = transition(actorSub, producerAccountId, activeStatus = true)

    /**
     * Deletes a producer at the request of an OWNER.
     *
     * Per the spec the producer entity row is **kept** but flipped to `active_status = false`.
     * The destructive work happens at the auth-provider layer:
     *  1. Enumerate auth users whose JWT `producer_account_id` matches.
     *  2. Delete each from the auth provider.
     *  3. Append one [AccountDeletionLog] entry per deleted sub
     *     (`deleted_role = PRODUCER`, SHA-256-hashed sub, actor preserved).
     *  4. Flip `active_status = false` and fan out Changes.
     *  5. Fire email notifications.
     *
     * If no auth user references this producer, the call still succeeds and flips
     * `active_status` — the producer account is left "unattached".
     */
    suspend fun delete(
        actorSub: String,
        producerAccountId: String,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound

        // 1. Enumerate auth users tied to this producer (best-effort — the
        // port returns empty if the auth provider is unreachable or no user
        // exists). On port failure we still proceed with the state flip.
        val authSubs =
            runCatching { userProvisioningPort.listAuthSubsByProducerAccount(producerAccountId) }
                .onFailure { e ->
                    logger.error(e) { "Failed to enumerate auth users for producer $producerAccountId" }
                }.getOrDefault(emptyList())

        // 2. Delete each auth user. Idempotent on the port side.
        authSubs.forEach { sub ->
            runCatching { userProvisioningPort.deleteUser(sub) }
                .onFailure { e -> logger.error(e) { "deleteUser($sub) failed during producer delete" } }
        }

        // 3. Audit-log one entry per deleted sub. If no sub was found, write
        // one entry hashed on the producer_account_id so the deletion event
        // is traceable.
        val now =
            kotlin.time.Clock.System
                .now()
        val subsForAudit = authSubs.ifEmpty { listOf("producer-account:$producerAccountId") }
        subsForAudit.forEach { sub ->
            runCatching {
                accountDeletionLogDAO.append(
                    AccountDeletionLog(
                        id = generateId(),
                        deletedSubHash = sha256(sub),
                        deletedRole = DeletedAccountRole.PRODUCER,
                        deletedAt = now,
                        actorOwnerId = actorSub.toId(),
                    ),
                )
            }.onFailure { e -> logger.error(e) { "audit log append failed for producer $producerAccountId" } }
        }

        // 4. Flip active_status (idempotent — only writes if currently active).
        if (producer.activeStatus) {
            val updated = producer.copy(activeStatus = false)
            producerAccountSyncDAO.updateActiveStatus(
                producer.producerAccountId,
                activeStatus = false,
                changes = changeFactory.buildStatusChangeChanges(updated),
            )
        }

        // 5. Email side-effects.
        sideEffectsForDelete(producer)

        logger.info {
            "Producer $producerAccountId deleted by actor=$actorSub: " +
                "${authSubs.size} auth user(s) removed, producer entity kept inactive"
        }
        return ProducerLifecycleOutcome.Success
    }

    /**
     * Updates the profile fields of the producer account identified by [producerAccountId].
     * Only name, contactEmail, address, website, and userPreferences are updated; other fields
     * are preserved.
     */
    suspend fun updateProfile(
        producerAccountId: String,
        update: ProducerAccountProfileUpdate,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound
        val updated =
            producer.copy(
                name = update.name,
                contactEmail = update.contactEmail,
                address = update.address,
                website = update.website,
                userPreferences = update.userPreferences ?: producer.userPreferences,
                lastUpdatedInstant =
                    kotlin.time.Clock.System
                        .now(),
            )
        val changes = changeFactory.buildStatusChangeChanges(updated)
        producerAccountSyncDAO.updateProfile(updated, changes)
        return ProducerLifecycleOutcome.Success
    }

    private suspend fun transition(
        actorSub: String,
        producerAccountId: String,
        activeStatus: Boolean,
    ): ProducerLifecycleOutcome {
        val producer =
            producerAccountSyncDAO.findById(producerAccountId.toId())
                ?: return ProducerLifecycleOutcome.NotFound

        if (actorSub == producerAccountId) {
            return ProducerLifecycleOutcome.Rejected(
                MutationErrorCode.SELF_ACTION_FORBIDDEN,
                "an OWNER cannot suspend or reactivate their own producer account",
            )
        }

        if (producer.activeStatus == activeStatus) {
            // Idempotent — nothing to write, no side-effects to fire.
            return ProducerLifecycleOutcome.Success
        }

        val updatedProducer = producer.copy(activeStatus = activeStatus)
        val changes = changeFactory.buildStatusChangeChanges(updatedProducer)
        producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, activeStatus, changes)

        sideEffects(
            producer = updatedProducer,
            activeStatus = activeStatus,
        )
        return ProducerLifecycleOutcome.Success
    }

    private suspend fun sideEffects(
        producer: ProducerAccount,
        activeStatus: Boolean,
    ) {
        // Ban or unban the auth users associated with this producer (best-effort).
        // For NO_ACCOUNT producers, listAuthSubsByProducerAccount returns empty → no-op.
        val authSubs =
            runCatching { userProvisioningPort.listAuthSubsByProducerAccount(producer.producerAccountId.id) }
                .getOrDefault(emptyList())
        authSubs.forEach { sub ->
            runCatching {
                if (activeStatus) userProvisioningPort.unbanUser(sub) else userProvisioningPort.banUser(sub)
            }.onFailure { e -> logger.error(e) { "Auth provider call failed for producer sub=$sub" } }
        }
        val target =
            AccountLifecycleTarget(
                sub = producer.producerAccountId.id,
                email = producer.contactEmail ?: "(unknown)",
                firstName = producer.name,
                lastName = "",
                role = AccountLifecycleRole.PRODUCER,
            )
        runCatching {
            if (activeStatus) {
                accountLifecycleEmailPort.notifyAccountReactivated(target)
            } else {
                accountLifecycleEmailPort.notifyAccountSuspended(target)
            }
        }.onFailure { e ->
            logger.error(e) { "Producer lifecycle email failed for ${producer.producerAccountId.id}" }
        }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event =
                    if (activeStatus) {
                        OwnersBroadcastEvent.ACCOUNT_REACTIVATED
                    } else {
                        OwnersBroadcastEvent.ACCOUNT_SUSPENDED
                    },
                actorOwnerEmail = "(actor email unavailable)",
                impactedRole = AccountLifecycleRole.PRODUCER,
            )
        }.onFailure { e ->
            logger.error(e) { "Producer lifecycle Owners broadcast failed" }
        }
    }

    private suspend fun sideEffectsForDelete(producer: ProducerAccount) {
        val target =
            AccountLifecycleTarget(
                sub = producer.producerAccountId.id,
                email = producer.contactEmail ?: "(unknown)",
                firstName = producer.name,
                lastName = "",
                role = AccountLifecycleRole.PRODUCER,
            )
        runCatching { accountLifecycleEmailPort.notifyAccountDeleted(target) }
            .onFailure { e -> logger.error(e) { "Producer delete email failed for ${producer.producerAccountId.id}" } }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event = OwnersBroadcastEvent.ACCOUNT_DELETED,
                actorOwnerEmail = "(actor email unavailable)",
                impactedRole = AccountLifecycleRole.PRODUCER,
            )
        }.onFailure { e -> logger.error(e) { "Producer delete Owners broadcast failed" } }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}

        private fun sha256(input: String): String =
            java.security.MessageDigest
                .getInstance("SHA-256")
                .digest(input.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it) }
    }
}

sealed class ProducerLifecycleOutcome {
    data object Success : ProducerLifecycleOutcome()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerLifecycleOutcome()

    data object NotFound : ProducerLifecycleOutcome()
}

data class ProducerAccountProfileUpdate(
    val name: String,
    val contactEmail: String?,
    val address: String?,
    val website: String?,
    val userPreferences: UserPreferences? = null,
)

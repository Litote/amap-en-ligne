package member

import authentication.AuthenticatedInfo
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.AccountLifecycleTarget
import email.OwnersBroadcastEvent
import id.Id
import id.generateId
import io.github.oshai.kotlinlogging.KotlinLogging
import persistence.dao.AccountDeletionLogDAO
import persistence.model.AccountDeletionLog
import persistence.model.DeletedAccountRole
import persistence.model.Member
import persistence.model.MemberAccountStatus
import java.security.MessageDigest
import kotlin.time.Clock

/**
 * Best-effort side-effects of OWNER lifecycle actions on a member (by `sub`): auth-provider
 * ban/unban/delete, deletion audit log, target + owners emails. Every step swallows and logs its
 * failure — the already-committed member rows are never rolled back.
 */
internal class MemberLifecycleSideEffects(
    private val userProvisioningPort: UserProvisioningPort,
    private val accountLifecycleEmailPort: AccountLifecycleEmailPort,
    private val accountDeletionLogDAO: AccountDeletionLogDAO,
) {
    /** Auth-provider ban/unban + lifecycle notifications for a member status change. */
    suspend fun onStatusChanged(
        updatedMembers: List<Member>,
        auth: AuthenticatedInfo,
        targetSub: String,
        accountStatus: MemberAccountStatus,
    ) {
        val isActive = accountStatus == MemberAccountStatus.ACTIVE
        runCatching {
            if (isActive) {
                userProvisioningPort.unbanUser(targetSub)
            } else {
                userProvisioningPort.banUser(targetSub)
            }
        }.onFailure { error ->
            logger.error(error) { "Auth provider ${if (isActive) "unban" else "ban"} failed for $targetSub" }
        }
        notifyMemberLifecycle(
            members = updatedMembers,
            auth = auth,
            targetSub = targetSub,
            ownersEvent =
                if (isActive) {
                    OwnersBroadcastEvent.ACCOUNT_REACTIVATED
                } else {
                    OwnersBroadcastEvent.ACCOUNT_SUSPENDED
                },
            notifyTarget = { target ->
                if (isActive) {
                    accountLifecycleEmailPort.notifyAccountReactivated(target)
                } else {
                    accountLifecycleEmailPort.notifyAccountSuspended(target)
                }
            },
        )
    }

    /**
     * Auth-provider user deletion, one [AccountDeletionLog] per membership row, and lifecycle
     * notifications. [members] are the rows as they were *before* anonymisation (PII needed for
     * the target email).
     */
    suspend fun onDeleted(
        members: List<Member>,
        auth: AuthenticatedInfo,
        targetSub: String,
    ) {
        runCatching { userProvisioningPort.deleteUser(targetSub) }
            .onFailure { error -> logger.error(error) { "deleteUser($targetSub) failed in auth provider" } }

        val deletedSubHash = sha256(targetSub)
        members.forEach {
            runCatching {
                accountDeletionLogDAO.append(
                    AccountDeletionLog(
                        id = generateId(),
                        deletedSubHash = deletedSubHash,
                        deletedRole = DeletedAccountRole.AMAP_MEMBER,
                        deletedAt = Clock.System.now(),
                        actorOwnerId = Id(auth.memberId),
                    ),
                )
            }.onFailure { error ->
                logger.error(error) { "audit log append failed for $targetSub" }
            }
        }
        notifyMemberLifecycle(
            members = members,
            auth = auth,
            targetSub = targetSub,
            ownersEvent = OwnersBroadcastEvent.ACCOUNT_DELETED,
            notifyTarget = { target -> accountLifecycleEmailPort.notifyAccountDeleted(target) },
        )
    }

    private suspend fun notifyMemberLifecycle(
        members: List<Member>,
        auth: AuthenticatedInfo,
        targetSub: String,
        ownersEvent: OwnersBroadcastEvent,
        notifyTarget: suspend (AccountLifecycleTarget) -> Unit,
    ) {
        val firstMember = members.firstOrNull() ?: return
        runCatching { notifyTarget(firstMember.toLifecycleTarget(targetSub)) }
            .onFailure { error -> logger.error(error) { "Member lifecycle email failed for $targetSub" } }
        runCatching {
            accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                event = ownersEvent,
                actorOwnerEmail = auth.email,
                impactedRole = AccountLifecycleRole.AMAP_MEMBER,
            )
        }.onFailure { error ->
            logger.error(error) { "Members lifecycle Owners broadcast failed" }
        }
    }

    private fun Member.toLifecycleTarget(targetSub: String): AccountLifecycleTarget =
        AccountLifecycleTarget(
            sub = targetSub,
            email = email ?: "(member email unavailable)",
            firstName = firstName.orEmpty(),
            lastName = lastName.orEmpty(),
            role = AccountLifecycleRole.AMAP_MEMBER,
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

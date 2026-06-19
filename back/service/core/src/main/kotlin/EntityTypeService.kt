package core

import authentication.AuthenticatedInfo
import authentication.Role
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.EntityPayload
import persistence.changes.MutationError
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.SyncScope
import persistence.model.EntityType

abstract class EntityTypeService<P : EntityPayload>(
    val entityType: EntityType,
) {
    abstract suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: P,
    ): MutationOutcome

    abstract suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome

    abstract suspend fun snapshot(auth: AuthenticatedInfo): List<P>

    open suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<P> = snapshot(auth)

    fun applied(
        mutation: ClientMutation,
        serverEntityId: String,
    ): MutationOutcome =
        MutationOutcome(
            clientOpId = mutation.clientOpId,
            status = MutationStatus.APPLIED,
            serverEntityId = serverEntityId,
        )

    fun rejected(
        mutation: ClientMutation,
        code: MutationErrorCode,
        message: String,
    ): MutationOutcome =
        MutationOutcome(
            clientOpId = mutation.clientOpId,
            status = MutationStatus.REJECTED,
            error = MutationError(code = code, message = message),
        )

    /**
     * Returns null when [auth] holds at least one of [allowed] roles, or a FORBIDDEN
     * [MutationOutcome] otherwise.
     *
     * Centralises role-based access checks so every [EntityTypeService] subclass uses the same
     * guard and future subclasses cannot accidentally omit the check.
     */
    protected fun requireAnyRole(
        auth: AuthenticatedInfo,
        allowed: Set<Role>,
        mutation: ClientMutation,
        message: String = "insufficient role: required one of ${allowed.joinToString()}",
    ): MutationOutcome? = if (auth.roles.any { it in allowed }) null else rejected(mutation, MutationErrorCode.FORBIDDEN, message)
}

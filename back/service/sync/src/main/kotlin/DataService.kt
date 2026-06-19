package sync

import authentication.AuthenticatedInfo
import core.AuthorizedScopeResolver
import core.EntityTypeService
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.EntityPayload
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberPayload
import persistence.changes.MutationError
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.ScopeSyncResult
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ChangeDAO
import persistence.dao.MemberSyncDAO
import persistence.model.EntityType

@Single(createdAtStart = true)
class DataService(
    services: List<EntityTypeService<*>>,
    private val changeDAO: ChangeDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val authorizedScopeResolver: AuthorizedScopeResolver,
) {
    private val serviceMap: Map<EntityType, EntityTypeService<*>> =
        services.associateBy { it.entityType }.also {
            require(it.size == services.size) { "duplicate EntityTypeService for the same EntityType" }
        }

    private fun service(entityType: EntityType) =
        @Suppress("UNCHECKED_CAST")
        (serviceMap[entityType] as? EntityTypeService<EntityPayload>)
            ?: error("unknown entity service for: $entityType")

    suspend fun sync(
        authenticatedInfo: AuthenticatedInfo,
        cursors: Map<String, String?>,
        mutations: List<ClientMutation> = emptyList(),
    ): SyncResponse {
        // Resolve the authorized scopes and enrich the auth info with organizationId /
        // producerAccountId
        val (authorizedScopes, enrichedAuth) = authorizedScopeResolver.resolve(authenticatedInfo)

        // Maps tmp_* ids allocated in earlier mutations to the real server ids,
        // so that later mutations in the same batch can reference the real FK values.
        val tmpIdMap = mutableMapOf<String, String>()
        val outcomes =
            mutations.map { mutation ->
                val rewritten =
                    (mutation.op as? Upsert)
                        ?.let { mutation.copy(op = it.copy(payload = it.payload.rewriteTmpIds(tmpIdMap))) }
                        ?: mutation
                val outcome = applyMutation(enrichedAuth, rewritten)
                // After a successful creation from a tmp_* id, record the mapping so subsequent
                // mutations in the same batch can resolve the same tmp_* FK reference.
                val realId = outcome.serverEntityId
                if (outcome.status == MutationStatus.APPLIED && realId != null) {
                    (mutation.op as? Upsert)
                        ?.payload
                        ?.extractTmpId()
                        ?.let { tmpId -> tmpIdMap[tmpId] = realId }
                }
                outcome
            }
        outcomes
            .filter { it.status == MutationStatus.REJECTED }
            .forEach { logger.warn { "rejected mutation ${it.clientOpId}: ${it.error}" } }

        val results =
            authorizedScopes.associate { scope ->
                scope.key to syncScope(enrichedAuth, scope, cursors[scope.key])
            }
        return SyncResponse(
            authorizedScopes = authorizedScopes.map(SyncScope::key),
            results = results,
            mutations = outcomes,
        )
    }

    /**
     * Aggregates the full snapshot of every [EntityType] of the given [scope].
     * Reused by the export feature to dump an organization's data; the regular sync
     * path goes through [bootstrapScope] which additionally allocates a cursor.
     */
    suspend fun snapshotScope(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<EntityPayload> =
        buildList {
            for (entityType in scope.entityTypes) {
                addAll(snapshot(auth, scope, entityType))
            }
        }

    private suspend fun syncScope(
        auth: AuthenticatedInfo,
        scope: SyncScope,
        cursor: String?,
    ): ScopeSyncResult {
        if (cursor == null) {
            return bootstrapScope(auth, scope)
        }

        val changedRowCount =
            changeDAO.countSince(
                scopeKey = scope.key,
                cursor = cursor,
                limit = ChangeDAO.DEFAULT_INCREMENTAL_LIMIT + 1,
            )
        return if (changedRowCount > ChangeDAO.DEFAULT_INCREMENTAL_LIMIT) {
            bootstrapScope(auth, scope)
        } else {
            val changes = changeDAO.since(scope.key, cursor)
            IncrementalScopeResult(
                changes = changes,
                nextCursor = changes.lastOrNull()?.cursor ?: cursor,
            )
        }
    }

    private suspend fun bootstrapScope(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): BootstrapScopeResult {
        val nextCursor = Cursor.next()
        val items =
            buildList {
                for (entityType in scope.entityTypes) {
                    addAll(snapshot(auth, scope, entityType))
                }
            }
        return BootstrapScopeResult(items = items, nextCursor = nextCursor)
    }

    private suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
        entityType: EntityType,
    ): List<EntityPayload> =
        when {
            scope == SyncScope.InstanceOwner && entityType == EntityType.Member -> {
                memberSyncDAO.listAll().map { MemberPayload(it) }
            }

            else -> {
                service(entityType).snapshot(auth, scope)
            }
        }

    private suspend fun applyMutation(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
    ): MutationOutcome =
        try {
            logger.info { "applying mutation ${mutation.clientOpId} op=${mutation.op::class.simpleName}" }
            when (val op = mutation.op) {
                is Upsert -> applyUpsert(auth, mutation, op.payload)
                is Delete -> applyDelete(auth, mutation, op)
            }
        } catch (e: Exception) {
            logger.error(e) { "unexpected error processing mutation ${mutation.clientOpId}" }
            MutationOutcome(
                clientOpId = mutation.clientOpId,
                status = MutationStatus.REJECTED,
                error = MutationError(code = MutationErrorCode.INVALID_PAYLOAD, message = "internal error"),
            )
        }

    private suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: EntityPayload,
    ): MutationOutcome = service(payload.entityType).applyUpsert(auth, mutation, payload)

    private suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = service(op.entityType).applyDelete(auth, mutation, op)

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

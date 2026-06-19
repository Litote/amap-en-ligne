@file:OptIn(kotlin.time.ExperimentalTime::class)

package sync

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.EntityPayload
import persistence.changes.OrganizationExport
import persistence.changes.OrganizationExportScopes
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.Organization
import kotlin.time.Clock

/**
 * Builds a versioned [OrganizationExport] of a single organization (backup / migration).
 *
 * Reuses [DataService.snapshotScope] for the `organization:{id}` scope and the
 * [ProductTypeSyncDAO] for the linked producers' catalogs (which live on their own
 * `producer-account:{id}` scopes). Authorization: OWNER for any org, otherwise an
 * ADMIN of that very organization.
 */
@Single(createdAtStart = true)
class ExportService(
    private val dataService: DataService,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val productTypeDAO: ProductTypeSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
) {
    suspend fun exportOrganization(
        auth: AuthenticatedInfo,
        organizationId: String,
        sourceInstance: String?,
    ): ExportOutcome {
        if (!isAuthorized(auth, organizationId)) return ExportOutcome.Forbidden
        organizationSyncDAO.getById(organizationId.toId<Organization>()) ?: return ExportOutcome.NotFound

        val scope = SyncScope.Organization(organizationId)
        val enrichedAuth = auth.copy(organizationId = organizationId)
        val organizationPayloads = dataService.snapshotScope(enrichedAuth, scope)

        val productTypePayloads = collectProductTypes(organizationId)

        return ExportOutcome.Success(
            OrganizationExport(
                formatVersion = OrganizationExport.CURRENT_FORMAT_VERSION,
                exportedAt = Clock.System.now(),
                sourceInstance = sourceInstance,
                organizationId = organizationId,
                scopes =
                    OrganizationExportScopes(
                        organization = organizationPayloads,
                        productTypes = productTypePayloads,
                    ),
            ),
        )
    }

    private suspend fun collectProductTypes(organizationId: String): List<EntityPayload> =
        producerAccountSyncDAO
            .getByOrganizationId(organizationId.toId<Organization>())
            .flatMap { producer -> productTypeDAO.getByProducerAccountId(producer.producerAccountId) }
            .map { ProductTypePayload(it) }

    private suspend fun isAuthorized(
        auth: AuthenticatedInfo,
        organizationId: String,
    ): Boolean {
        if (auth.roles.contains(Role.OWNER)) return true
        if (!auth.roles.contains(Role.ADMIN)) return false
        val callerOrganizationId =
            auth.organizationId ?: memberSyncDAO.findOrganizationIdBySub(auth.memberId)?.id
        return callerOrganizationId == organizationId
    }
}

sealed interface ExportOutcome {
    data class Success(
        val export: OrganizationExport,
    ) : ExportOutcome

    data object Forbidden : ExportOutcome

    data object NotFound : ExportOutcome
}

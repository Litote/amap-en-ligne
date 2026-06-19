@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

/**
 * Versioned, self-contained archive of a single organization's data, in the native
 * wire format (reuses [EntityPayload] so the snapshot/mutation machinery and the
 * front/back serializers stay the single source of truth).
 *
 * Produced by the export endpoint and consumed by the import endpoint to back up an
 * organization or migrate it to another amap-en-ligne instance.
 */
@Serializable
data class OrganizationExport(
    @SerialName("format_version") val formatVersion: Int,
    @SerialName("exported_at") val exportedAt: Instant,
    @SerialName("source_instance") val sourceInstance: String? = null,
    @SerialName("organization_id") val organizationId: String,
    val scopes: OrganizationExportScopes,
) {
    companion object {
        const val CURRENT_FORMAT_VERSION: Int = 1
    }
}

/**
 * The exported payloads grouped by their originating sync scope.
 *
 * - [organization] holds the snapshot of the `organization:{id}` scope
 *   (Organization aggregate, ProducerAccount, Member, Contract, DeliveryTemplate,
 *   MemberInvitation, MemberJoinRequest, BasketExchange).
 * - [productTypes] holds the ProductType catalogs of the producers linked to the org;
 *   these live on `producer-account:{id}` scopes and are not part of the organization
 *   snapshot, so they are collected separately for backup fidelity.
 */
@Serializable
data class OrganizationExportScopes(
    val organization: List<EntityPayload>,
    @SerialName("product_types") val productTypes: List<EntityPayload> = emptyList(),
)

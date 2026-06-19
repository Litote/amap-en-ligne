@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package persistence.changes

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonClassDiscriminator

@Serializable
data class SyncResponse(
    @SerialName("authorized_scopes")
    val authorizedScopes: List<String>,
    val results: Map<String, ScopeSyncResult>,
    val mutations: List<MutationOutcome> = emptyList(),
)

@Serializable
@JsonClassDiscriminator("mode")
sealed interface ScopeSyncResult

@Serializable
@SerialName("bootstrap")
data class BootstrapScopeResult(
    val items: List<EntityPayload>,
    @SerialName("next_cursor")
    val nextCursor: String,
) : ScopeSyncResult

@Serializable
@SerialName("incremental")
data class IncrementalScopeResult(
    val changes: List<Change>,
    @SerialName("next_cursor")
    val nextCursor: String,
) : ScopeSyncResult

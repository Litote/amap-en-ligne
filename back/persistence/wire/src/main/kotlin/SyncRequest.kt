package persistence.changes

import kotlinx.serialization.Serializable

/**
 * Body of `POST /v1/sync`.
 *
 * [cursors] map key is the scope key (`producer-account:...`,
 * `organization:...`, `instance-owner`); the value is the last cursor the
 * client has seen for that scope, or `null` if the client is bootstrapping.
 *
 * [mutations] are the local pending writes the client wants to flush in this
 * round-trip. They are applied server-side before the read step, so any
 * change emitted by an applied mutation appears in the [SyncResponse.results]
 * returned in the same response.
 */
@Serializable
data class SyncRequest(
    val cursors: Map<String, String?> = emptyMap(),
    val mutations: List<ClientMutation> = emptyList(),
)

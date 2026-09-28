package deploy.jvm

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import persistence.changes.MutationStatus
import persistence.changes.SyncRequest
import persistence.model.EntityType

@Serializable
data class AcceptanceScenario(
    val id: String,
    val title: String,
    val targets: Set<AcceptanceTarget> = setOf(AcceptanceTarget.Server, AcceptanceTarget.Flutter),
    val given: AcceptanceGiven,
    @SerialName("when")
    val steps: List<AcceptanceStep>,
    val then: AcceptanceThen,
)

@Serializable
data class AcceptanceGiven(
    val backendState: String,
    val appState: String,
    // Members seeded directly in the `organization {id}` AMAP before the first step.
    val members: List<AcceptanceGivenMember> = emptyList(),
    // Account-backed producer accounts seeded directly (not linked to any AMAP).
    val producerAccounts: List<AcceptanceGivenProducerAccount> = emptyList(),
)

@Serializable
data class AcceptanceGivenMember(
    val memberId: String,
    val roles: List<String>,
)

@Serializable
data class AcceptanceGivenProducerAccount(
    val producerAccountId: String,
    val name: String,
)

@Serializable
data class AcceptanceStep(
    val actor: String,
    val action: String,
    // Caller identity the step's token is minted for: `producer` (default), `owner` or `admin:{organizationId}`.
    @SerialName("as")
    val caller: String? = null,
    val request: SyncRequest,
    val save: AcceptanceSave? = null,
    // Checked right after this step (same shape as `then.lastResponse`), for multi-actor stories.
    val expect: AcceptanceResponseExpectation? = null,
)

@Serializable
data class AcceptanceSave(
    @SerialName("cursorRefs")
    val cursorRefs: Map<String, String> = emptyMap(),
    // clientOpId -> ref name: saves the outcome's serverEntityId for later `$ref:` use.
    @SerialName("entityIdRefs")
    val entityIdRefs: Map<String, String> = emptyMap(),
)

@Serializable
data class AcceptanceThen(
    @SerialName("lastResponse")
    val lastResponse: AcceptanceResponseExpectation? = null,
)

@Serializable
data class AcceptanceResponseExpectation(
    val statusCode: Int,
    val mutationOutcomes: List<AcceptanceMutationOutcomeExpectation> = emptyList(),
    val snapshotByEntityType: Map<EntityType, AcceptanceSnapshotExpectation> = emptyMap(),
    val changesByEntityType: Map<EntityType, Int> = emptyMap(),
    val containsChanges: List<AcceptanceChangeExpectation> = emptyList(),
)

@Serializable
data class AcceptanceMutationOutcomeExpectation(
    val clientOpId: String,
    val status: MutationStatus,
    val serverEntityId: AcceptanceStringExpectation? = null,
    val error: AcceptanceMutationErrorExpectation? = null,
)

@Serializable
data class AcceptanceMutationErrorExpectation(
    val code: String,
)

@Serializable
data class AcceptanceSnapshotExpectation(
    val itemCount: Int? = null,
    val cursor: AcceptanceStringExpectation? = null,
    val contains: List<JsonObject> = emptyList(),
)

@Serializable
data class AcceptanceChangeExpectation(
    val entityType: EntityType,
    val entityId: String,
    val op: String,
    // When set, the change must come from this scope's result.
    val scopeKey: String? = null,
    // When set, the changed entity's JSON must hold these fields.
    val payload: JsonObject? = null,
)

@Serializable
data class AcceptanceStringExpectation(
    val kind: String,
    val value: String? = null,
)

@Serializable
enum class AcceptanceTarget {
    @SerialName("server")
    Server,

    @SerialName("flutter")
    Flutter,

    @SerialName("volunteer-flow")
    VolunteerFlow,

    @SerialName("coordinator-flow")
    CoordinatorFlow,

    @SerialName("time-slot-flow")
    TimeSlotFlow,

    @SerialName("contract-lifecycle")
    ContractLifecycle,
}

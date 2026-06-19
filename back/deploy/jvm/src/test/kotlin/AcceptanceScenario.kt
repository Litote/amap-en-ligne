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
)

@Serializable
data class AcceptanceStep(
    val actor: String,
    val action: String,
    val request: SyncRequest,
    val save: AcceptanceSave? = null,
)

@Serializable
data class AcceptanceSave(
    @SerialName("cursorRefs")
    val cursorRefs: Map<EntityType, String> = emptyMap(),
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

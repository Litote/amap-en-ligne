package deploy.jvm

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import persistence.model.EntityType

@Serializable
data class OrganizationFlowScenario(
    val id: String,
    val title: String,
    val targets: Set<OrganizationFlowTarget> = setOf(OrganizationFlowTarget.OrganizationFlow),
    val given: OrganizationFlowGiven,
    @SerialName("when")
    val steps: List<OrganizationFlowStep>,
    val then: OrganizationFlowThen,
)

/** Supported `backendState` values: `empty`, or `organization {organizationId}` (the AMAP exists with an ADMIN). */
@Serializable
data class OrganizationFlowGiven(
    val backendState: String,
)

@Serializable
data class OrganizationFlowStep(
    val actor: String,
    val action: String,
    val request: JsonObject? = null,
    val params: Map<String, String>? = null,
    val save: OrganizationFlowSave? = null,
)

@Serializable
data class OrganizationFlowSave(
    @SerialName("requestIdRef")
    val requestIdRef: String? = null,
)

@Serializable
data class OrganizationFlowThen(
    @SerialName("lastResponse")
    val lastResponse: OrganizationFlowResponseExpectation? = null,
)

@Serializable
data class OrganizationFlowResponseExpectation(
    val statusCode: Int,
    // Entities the last response's bootstrap snapshots must contain (field subset match on the entity JSON).
    val snapshotContains: List<OrganizationFlowEntityExpectation> = emptyList(),
)

@Serializable
data class OrganizationFlowEntityExpectation(
    val entityType: EntityType,
    val fields: JsonObject,
)

@Serializable
enum class OrganizationFlowTarget {
    @SerialName("organization-flow")
    OrganizationFlow,

    @SerialName("flutter")
    Flutter,
}

package deploy.jvm

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

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
)

@Serializable
enum class OrganizationFlowTarget {
    @SerialName("organization-flow")
    OrganizationFlow,

    @SerialName("flutter")
    Flutter,
}

package deploy.jvm

import id.Id
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.OrganizationRequestPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import serialization.json
import java.net.URI
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class OrganizationFlowScenariosTest : JvmSyncTestSupport() {
    @Test
    fun `documented organization flow scenarios pass`() =
        runTest {
            loadOrganizationFlowScenarios()
                .filter { OrganizationFlowTarget.OrganizationFlow in it.targets }
                .forEach { scenario ->
                    resetDb()
                    executeScenario(scenario)
                }
        }

    private fun executeScenario(scenario: OrganizationFlowScenario) {
        assertEquals("empty", scenario.given.backendState, "Unsupported backendState in ${scenario.id}")

        val savedRefs = mutableMapOf<String, String>()
        var lastResponse: HttpResponse<String>? = null

        val ownerToken =
            mintGoTrueToken(
                subject = "00000000-0000-0000-0000-000000000002",
                email = "owner@example.com",
                roles = listOf("OWNER"),
                producerAccountId = null,
            )

        for (step in scenario.steps) {
            val resolvedParams =
                step.params?.mapValues { (_, v) ->
                    if (v.startsWith("\$ref:")) savedRefs.getValue(v.removePrefix("\$ref:")) else v
                } ?: emptyMap()

            val response =
                when (step.action) {
                    "submit_organization_request" -> {
                        val body = requireNotNull(step.request) { "submit_organization_request requires a request body in ${scenario.id}" }
                        val resp = postRaw("/v1/organization-requests", body.toString())
                        if (resp.statusCode() == 201) {
                            val responseBody = json.parseToJsonElement(resp.body()).jsonObject
                            step.save?.requestIdRef?.let { ref ->
                                savedRefs[ref] = responseBody.getValue("request_id").jsonPrimitive.content
                            }
                        }
                        resp
                    }

                    "approve_organization_request" -> {
                        val requestId =
                            resolvedParams["requestId"]
                                ?: error("Missing requestId param in ${scenario.id}")
                        val snapshotResponse =
                            postSyncWithToken(
                                SyncRequest(cursors = emptyMap(), mutations = emptyList()),
                                ownerToken,
                            )
                        val snapshot =
                            assertNotNull(
                                snapshotResponse.results[SyncScope.InstanceOwner.key] as? BootstrapScopeResult,
                                "No OrganizationRequest snapshot in response for ${scenario.id}",
                            )
                        val requestPayload =
                            snapshot.items
                                .filterIsInstance<OrganizationRequestPayload>()
                                .find { it.organizationRequest.requestId == Id<OrganizationRequest>(requestId) }
                                ?: error("Request $requestId not found in snapshot for ${scenario.id}")
                        val updatedRequest =
                            requestPayload.organizationRequest.copy(
                                status = OrganizationRequestStatus.APPROVED,
                            )
                        val approvalResponse =
                            postSyncWithTokenRaw(
                                SyncRequest(
                                    cursors = emptyMap(),
                                    mutations =
                                        listOf(
                                            ClientMutation(
                                                clientOpId = "approve-$requestId",
                                                op = Upsert(OrganizationRequestPayload(updatedRequest)),
                                            ),
                                        ),
                                ),
                                ownerToken,
                            )
                        approvalResponse
                    }

                    "list_organization_requests" -> {
                        postSyncWithTokenRaw(
                            SyncRequest(cursors = emptyMap(), mutations = emptyList()),
                            ownerToken,
                        )
                    }

                    else -> {
                        error("Unsupported action '${step.action}' in ${scenario.id}")
                    }
                }
            lastResponse = response
        }

        val expectation =
            scenario.then.lastResponse
                ?: error("Scenario ${scenario.id} targets organization-flow but has no lastResponse expectation")
        assertEquals(
            expectation.statusCode,
            requireNotNull(lastResponse) { "No steps executed in ${scenario.id}" }.statusCode(),
            "Unexpected HTTP status in ${scenario.id}",
        )
    }

    private fun postRaw(
        path: String,
        body: String,
    ): HttpResponse<String> {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port$path"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    private fun postSyncWithTokenRaw(
        syncRequest: SyncRequest,
        token: String,
    ): HttpResponse<String> {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/sync"))
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json.encodeToString(SyncRequest.serializer(), syncRequest)))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    private fun postSyncWithToken(
        syncRequest: SyncRequest,
        token: String,
    ): SyncResponse {
        val response = postSyncWithTokenRaw(syncRequest, token)
        assertEquals(200, response.statusCode())
        return json.decodeFromString(SyncResponse.serializer(), response.body())
    }
}

private fun loadOrganizationFlowScenarios(): List<OrganizationFlowScenario> =
    Files
        .list(resolveOrganizationFlowScenariosDir())
        .use { paths ->
            paths
                .filter { Files.isRegularFile(it) && it.fileName.toString().endsWith(".json") }
                .sorted(compareBy<Path> { it.fileName.toString() })
                .map { Files.readString(it) }
                .filter { content ->
                    json
                        .parseToJsonElement(content)
                        .jsonObject["targets"]
                        ?.jsonArray
                        ?.any { it.jsonPrimitive.content == "organization-flow" }
                        ?: false
                }.map { json.decodeFromString(OrganizationFlowScenario.serializer(), it) }
                .toList()
        }

private fun resolveOrganizationFlowScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

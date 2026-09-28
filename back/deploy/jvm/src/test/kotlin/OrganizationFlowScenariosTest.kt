package deploy.jvm

import id.Id
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.EntityPayload
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.MutationStatus
import persistence.changes.OrganizationRequestPayload
import persistence.changes.ProducerRequestPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.MemberJoinRequestStatus
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.ProducerRequestStatus
import serialization.json
import java.net.URI
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

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
        val organizationId = applyBackendState(scenario)

        val savedRefs = mutableMapOf<String, String>()
        var lastResponse: HttpResponse<String>? = null

        val ownerToken =
            mintGoTrueToken(
                subject = "00000000-0000-0000-0000-000000000002",
                email = "owner@example.com",
                roles = listOf("OWNER"),
                producerAccountId = null,
            )
        val adminToken = organizationId?.let(::adminTokenFor)

        for (step in scenario.steps) {
            val resolvedParams =
                step.params?.mapValues { (_, v) ->
                    if (v.startsWith("\$ref:")) savedRefs.getValue(v.removePrefix("\$ref:")) else v
                } ?: emptyMap()

            val response =
                when (step.action) {
                    in PUBLIC_SUBMISSION_PATHS -> {
                        val body = requireNotNull(step.request) { "${step.action} requires a request body in ${scenario.id}" }
                        val resp = postRaw(PUBLIC_SUBMISSION_PATHS.getValue(step.action), body.toString())
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

                    "review_producer_request" -> {
                        val requestId = resolvedParams["requestId"] ?: error("Missing requestId param in ${scenario.id}")
                        val status =
                            ProducerRequestStatus.valueOf(resolvedParams["status"] ?: error("Missing status param in ${scenario.id}"))
                        val request =
                            postSyncWithToken(SyncRequest(), ownerToken)
                                .bootstrapItems()
                                .filterIsInstance<ProducerRequestPayload>()
                                .find { it.producerRequest.requestId.id == requestId }
                                ?.producerRequest
                                ?: error("Producer request $requestId not found in owner snapshot for ${scenario.id}")
                        postAppliedMutation(
                            scenarioId = scenario.id,
                            token = ownerToken,
                            mutation =
                                ClientMutation(
                                    clientOpId = "review-$requestId",
                                    op = Upsert(ProducerRequestPayload(request.copy(status = status))),
                                ),
                        )
                    }

                    "review_member_join_request" -> {
                        val token =
                            requireNotNull(adminToken) { "review_member_join_request needs an organization backendState in ${scenario.id}" }
                        val requestId = resolvedParams["requestId"] ?: error("Missing requestId param in ${scenario.id}")
                        val status =
                            MemberJoinRequestStatus.valueOf(resolvedParams["status"] ?: error("Missing status param in ${scenario.id}"))
                        val request =
                            postSyncWithToken(SyncRequest(), token)
                                .bootstrapItems()
                                .filterIsInstance<MemberJoinRequestPayload>()
                                .find { it.memberJoinRequest.requestId.id == requestId }
                                ?.memberJoinRequest
                                ?: error("Member join request $requestId not found in admin snapshot for ${scenario.id}")
                        postAppliedMutation(
                            scenarioId = scenario.id,
                            token = token,
                            mutation =
                                ClientMutation(
                                    clientOpId = "review-$requestId",
                                    op = Upsert(MemberJoinRequestPayload(request.copy(status = status))),
                                ),
                        )
                    }

                    "list_organization_requests", "owner_sync" -> {
                        postSyncWithTokenRaw(
                            SyncRequest(cursors = emptyMap(), mutations = emptyList()),
                            ownerToken,
                        )
                    }

                    "admin_sync" -> {
                        val token = requireNotNull(adminToken) { "admin_sync needs an organization backendState in ${scenario.id}" }
                        postSyncWithTokenRaw(SyncRequest(), token)
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
        val finalResponse = requireNotNull(lastResponse) { "No steps executed in ${scenario.id}" }
        assertEquals(
            expectation.statusCode,
            finalResponse.statusCode(),
            "Unexpected HTTP status in ${scenario.id}",
        )
        if (expectation.snapshotContains.isNotEmpty()) {
            val items = json.decodeFromString(SyncResponse.serializer(), finalResponse.body()).bootstrapItems()
            expectation.snapshotContains.forEach { expected ->
                assertTrue(
                    items.any { it.entityType == expected.entityType && it.entityJsonContains(expected.fields) },
                    "Snapshot in ${scenario.id} does not contain ${expected.entityType} ${expected.fields}; got " +
                        items.filter { it.entityType == expected.entityType },
                )
            }
        }
    }

    /** Returns the organization id of an `organization {id}` backend state (seeded with an ADMIN), null for `empty`. */
    private fun applyBackendState(scenario: OrganizationFlowScenario): String? {
        val backendState = scenario.given.backendState
        return when {
            backendState == "empty" -> {
                null
            }

            backendState.startsWith(ORGANIZATION_STATE_PREFIX) -> {
                backendState.removePrefix(ORGANIZATION_STATE_PREFIX).also(::insertOrganizationDirectly)
            }

            else -> {
                error("Unsupported backendState `$backendState` in ${scenario.id}")
            }
        }
    }

    private fun adminTokenFor(organizationId: String): String {
        val adminSub = "organization-flow-admin-$organizationId"
        insertMemberDirectly(memberId = adminSub, organizationId = organizationId, roles = listOf("ADMIN"))
        return mintGoTrueToken(
            subject = adminSub,
            email = "$adminSub@example.com",
            roles = listOf("ADMIN"),
            organizationId = organizationId,
            producerAccountId = null,
        )
    }

    /** Posts a single review mutation; a documented review step must be APPLIED for the story to continue. */
    private fun postAppliedMutation(
        scenarioId: String,
        token: String,
        mutation: ClientMutation,
    ): HttpResponse<String> {
        val response = postSyncWithTokenRaw(SyncRequest(mutations = listOf(mutation)), token)
        assertEquals(200, response.statusCode(), "Unexpected review status in $scenarioId")
        val outcome = json.decodeFromString(SyncResponse.serializer(), response.body()).mutations.single()
        assertEquals(MutationStatus.APPLIED, outcome.status, "Review ${mutation.clientOpId} not applied in $scenarioId: $outcome")
        return response
    }

    private fun SyncResponse.bootstrapItems(): List<EntityPayload> =
        results.values.filterIsInstance<BootstrapScopeResult>().flatMap { it.items }

    /** True when the payload's entity object (the single object-valued field next to `type`) holds every expected field. */
    private fun EntityPayload.entityJsonContains(expectedFields: JsonObject): Boolean {
        val entity =
            json
                .encodeToJsonElement(EntityPayload.serializer(), this)
                .jsonObject
                .values
                .filterIsInstance<JsonObject>()
                .single()
        return expectedFields.all { (key, value) -> entity[key] == value }
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

private const val ORGANIZATION_STATE_PREFIX = "organization "

/** Unauthenticated onboarding submissions; each answers `201` with the created `request_id`. */
private val PUBLIC_SUBMISSION_PATHS =
    mapOf(
        "submit_organization_request" to "/v1/organization-requests",
        "submit_producer_request" to "/v1/producer-requests",
        "submit_member_join_request" to "/v1/public/member-join-requests",
    )

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

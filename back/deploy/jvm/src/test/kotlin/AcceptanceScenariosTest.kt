package deploy.jvm

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BootstrapScopeResult
import persistence.changes.EntityPayload
import persistence.changes.IncrementalScopeResult
import persistence.changes.ScopeSyncResult
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.model.EntityType
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class AcceptanceScenariosTest : JvmSyncTestSupport() {
    @Test
    fun `documented server acceptance scenarios pass`() =
        runTest {
            loadAcceptanceScenarios()
                .filter { AcceptanceTarget.Server in it.targets }
                .forEach { scenario ->
                    resetDb()
                    executeScenario(scenario)
                }
        }

    private fun executeScenario(scenario: AcceptanceScenario) {
        applyBackendState(scenario)
        assertEquals("fresh", scenario.given.appState, "Unsupported appState in ${scenario.id}")

        val savedRefs = mutableMapOf<String, String>()
        var lastRawResponse: java.net.http.HttpResponse<String>? = null
        var lastDecodedResponse: SyncResponse? = null

        for (step in scenario.steps) {
            assertEquals("client", step.actor, "Unsupported actor in ${scenario.id}")
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")

            val request = resolveRefs(step.request, savedRefs)
            val rawResponse =
                postRawSyncAs(
                    token = tokenFor(step.caller, scenario.id),
                    body = json.encodeToString(SyncRequest.serializer(), request),
                )
            lastRawResponse = rawResponse
            lastDecodedResponse =
                if (rawResponse.statusCode() == 200) {
                    json.decodeFromString(SyncResponse.serializer(), rawResponse.body())
                } else {
                    null
                }

            step.expect?.let { stepExpectation ->
                assertEquals(stepExpectation.statusCode, rawResponse.statusCode(), "Unexpected step status in ${scenario.id}")
                if (stepExpectation.statusCode == 200) {
                    assertSyncResponse(
                        scenarioId = scenario.id,
                        actual = assertNotNull(lastDecodedResponse),
                        expected = stepExpectation,
                        savedRefs = savedRefs,
                    )
                }
            }

            step.save?.cursorRefs?.forEach { (scopeKey, refName) ->
                val cursor = lastDecodedResponse?.cursorFor(scopeKey)
                assertNotNull(cursor, "Missing cursor for $scopeKey in ${scenario.id}")
                savedRefs[refName] = cursor
            }
            step.save?.entityIdRefs?.forEach { (clientOpId, refName) ->
                val outcome = lastDecodedResponse?.mutations?.find { it.clientOpId == clientOpId }
                val serverEntityId = outcome?.serverEntityId
                assertNotNull(serverEntityId, "Missing serverEntityId for $clientOpId in ${scenario.id}: $outcome")
                savedRefs[refName] = serverEntityId
            }
        }

        val lastResponseExpectation =
            assertNotNull(
                scenario.then.lastResponse,
                "Scenario ${scenario.id} targets the server but has no lastResponse expectation",
            )
        val rawResponse = assertNotNull(lastRawResponse, "Scenario ${scenario.id} executed no steps")
        assertEquals(lastResponseExpectation.statusCode, rawResponse.statusCode(), "Unexpected status in ${scenario.id}")

        if (lastResponseExpectation.statusCode == 200) {
            assertSyncResponse(
                scenarioId = scenario.id,
                actual = assertNotNull(lastDecodedResponse),
                expected = lastResponseExpectation,
                savedRefs = savedRefs,
            )
        }
    }

    /**
     * Supported `given.backendState` values: `empty`, or `organization {organizationId}` (the AMAP exists, with the
     * optional `given.members` seeded in it).
     */
    private fun applyBackendState(scenario: AcceptanceScenario) {
        scenario.given.producerAccounts.forEach { insertProducerAccountDirectly(it.producerAccountId, it.name) }
        val backendState = scenario.given.backendState
        when {
            backendState == "empty" -> {
                Unit
            }

            backendState.startsWith(ORGANIZATION_STATE_PREFIX) -> {
                val organizationId = backendState.removePrefix(ORGANIZATION_STATE_PREFIX)
                insertOrganizationDirectly(organizationId)
                scenario.given.members.forEach { member ->
                    insertMemberDirectly(memberId = member.memberId, organizationId = organizationId, roles = member.roles)
                }
            }

            else -> {
                error("Unsupported backendState `$backendState` in ${scenario.id}")
            }
        }
    }

    /** Mints the token for a step's `as` caller; an admin is backed by an ADMIN member row of its AMAP. */
    private fun tokenFor(
        caller: String?,
        scenarioId: String,
    ): String =
        when {
            caller == null || caller == "producer" -> {
                bearerToken
            }

            caller == "owner" -> {
                mintGoTrueToken(
                    subject = "acceptance-owner",
                    email = "acceptance-owner@example.com",
                    roles = listOf("OWNER"),
                    producerAccountId = null,
                )
            }

            caller.startsWith(ADMIN_CALLER_PREFIX) -> {
                val organizationId = caller.removePrefix(ADMIN_CALLER_PREFIX)
                val adminSub = "acceptance-admin-$organizationId"
                insertMemberDirectly(memberId = adminSub, organizationId = organizationId, roles = listOf("ADMIN"))
                mintGoTrueToken(
                    subject = adminSub,
                    email = "$adminSub@example.com",
                    roles = listOf("ADMIN"),
                    organizationId = organizationId,
                    producerAccountId = null,
                )
            }

            else -> {
                error("Unsupported caller `$caller` in $scenarioId")
            }
        }

    /** Replaces every `$ref:{name}` string of the request (cursors, entity ids…) by the value saved by an earlier step. */
    private fun resolveRefs(
        request: SyncRequest,
        savedRefs: Map<String, String>,
    ): SyncRequest =
        json.decodeFromJsonElement(
            SyncRequest.serializer(),
            json.encodeToJsonElement(SyncRequest.serializer(), request).resolveRefs(savedRefs),
        )

    private fun JsonElement.resolveRefs(savedRefs: Map<String, String>): JsonElement =
        when (this) {
            is JsonObject -> JsonObject(mapValues { (_, value) -> value.resolveRefs(savedRefs) })
            is JsonArray -> JsonArray(map { it.resolveRefs(savedRefs) })
            is JsonPrimitive -> if (isString) JsonPrimitive(savedRefs.resolveRef(content)) else this
        }

    private fun assertSyncResponse(
        scenarioId: String,
        actual: SyncResponse,
        expected: AcceptanceResponseExpectation,
        savedRefs: Map<String, String>,
    ) {
        assertEquals(
            expected.mutationOutcomes.size,
            actual.mutations.size,
            "Unexpected mutation outcome count in $scenarioId",
        )
        expected.mutationOutcomes.forEach { expectedOutcome ->
            val actualOutcome =
                assertNotNull(
                    actual.mutations.find { it.clientOpId == expectedOutcome.clientOpId },
                    "Missing mutation outcome ${expectedOutcome.clientOpId} in $scenarioId",
                )
            assertEquals(expectedOutcome.status, actualOutcome.status, "Unexpected mutation status in $scenarioId: $actualOutcome")
            expectedOutcome.error?.let { expectedError ->
                assertEquals(
                    expectedError.code,
                    actualOutcome.error?.code?.name,
                    "Unexpected error code for ${expectedOutcome.clientOpId} in $scenarioId",
                )
            }
            expectedOutcome.serverEntityId?.let { expectation ->
                assertStringExpectation(
                    expectation = expectation.copy(value = expectation.value?.let(savedRefs::resolveRef)),
                    actual = actualOutcome.serverEntityId,
                    label = "serverEntityId for ${expectedOutcome.clientOpId} in $scenarioId",
                )
            }
        }

        if (expected.snapshotByEntityType.isEmpty()) {
            assertTrue(actual.results.values.none { it is BootstrapScopeResult }, "Expected no snapshots in $scenarioId")
        }
        expected.snapshotByEntityType.forEach { (entityType, snapshotExpectation) ->
            val snapshot =
                assertNotNull(actual.bootstrapResultFor(entityType), "Missing snapshot for $entityType in $scenarioId")
            val items = snapshot.items.filter { it.entityType == entityType }
            snapshotExpectation.itemCount?.let { count ->
                assertEquals(count, items.size, "Unexpected snapshot itemCount for $entityType in $scenarioId")
            }
            snapshotExpectation.cursor?.let { expectation ->
                assertStringExpectation(
                    expectation = expectation,
                    actual = snapshot.nextCursor,
                    label = "cursor for $entityType in $scenarioId",
                )
            }
            snapshotExpectation.contains.forEach { expectedItem ->
                assertTrue(
                    items.any { payloadMatches(it, expectedItem) },
                    "Snapshot for $entityType in $scenarioId does not contain $expectedItem",
                )
            }
        }

        expected.changesByEntityType.forEach { (entityType, expectedCount) ->
            val actualCount = actual.incrementalChanges().count { it.entityType == entityType }
            assertEquals(expectedCount, actualCount, "Unexpected change count for $entityType in $scenarioId")
        }

        expected.containsChanges.forEach { expectedChange ->
            val scopedChanges =
                actual.results
                    .filterKeys { expectedChange.scopeKey == null || it == expectedChange.scopeKey }
                    .values
                    .filterIsInstance<IncrementalScopeResult>()
                    .flatMap { it.changes }
            assertTrue(
                scopedChanges.any {
                    it.entityType == expectedChange.entityType &&
                        it.entityId == savedRefs.resolveRef(expectedChange.entityId) &&
                        it.op.name == expectedChange.op &&
                        (expectedChange.payload == null || it.payload?.let { p -> payloadMatches(p, expectedChange.payload) } == true)
                },
                "Missing change $expectedChange in $scenarioId",
            )
        }
    }

    private fun assertStringExpectation(
        expectation: AcceptanceStringExpectation,
        actual: String?,
        label: String,
    ) {
        when (expectation.kind) {
            "non-empty-string" -> {
                assertTrue(!actual.isNullOrBlank(), "Expected non-empty $label")
            }

            "present-and-not-equal" -> {
                val unexpected = assertNotNull(expectation.value, "Missing comparison value for $label")
                assertNotNull(actual, "Expected present $label")
                assertTrue(actual != unexpected, "Expected $label to differ from $unexpected")
            }

            "equals" -> {
                assertEquals(expectation.value, actual, "Unexpected $label")
            }

            else -> {
                error("Unsupported string expectation kind `${expectation.kind}` for $label")
            }
        }
    }

    private fun SyncResponse.cursorFor(scopeKey: String): String? {
        val result = results[scopeKey] ?: return null
        return when (result) {
            is BootstrapScopeResult -> result.nextCursor
            is IncrementalScopeResult -> result.nextCursor
        }
    }

    private fun SyncResponse.bootstrapResultFor(entityType: EntityType): BootstrapScopeResult? =
        resultFor(entityType) as? BootstrapScopeResult

    private fun SyncResponse.resultFor(entityType: EntityType): ScopeSyncResult? {
        val defaultScopeKey =
            when (entityType) {
                EntityType.ProductType -> SyncScope.ProducerAccount(tenantId).key

                EntityType.OrganizationRequest,
                EntityType.Owner,
                EntityType.OwnerInvitation,
                EntityType.Member,
                EntityType.MemberInvitation,
                -> SyncScope.InstanceOwner.key

                else -> null
            }
        return defaultScopeKey?.let(results::get)
            ?: results.values.firstOrNull { result ->
                when (result) {
                    is BootstrapScopeResult -> result.items.any { it.entityType == entityType }
                    is IncrementalScopeResult -> result.changes.any { it.entityType == entityType }
                }
            }
    }

    private fun SyncResponse.incrementalChanges() =
        results.values.flatMap { result ->
            when (result) {
                is BootstrapScopeResult -> emptyList()
                is IncrementalScopeResult -> result.changes
            }
        }

    /** Matches the entity object of [payload] (the object-valued field next to `type`) against [expectedSubset]. */
    private fun payloadMatches(
        payload: EntityPayload,
        expectedSubset: JsonObject,
    ): Boolean {
        val actualObject =
            json
                .encodeToJsonElement(EntityPayload.serializer(), payload)
                .jsonObject
                .values
                .filterIsInstance<JsonObject>()
                .single()
        return expectedSubset.entries.all { (key, expectedValue) -> actualObject[key] == expectedValue }
    }
}

private const val ORGANIZATION_STATE_PREFIX = "organization "
private const val REF_PREFIX = "\$ref:"

private fun Map<String, String>.resolveRef(value: String): String =
    if (value.startsWith(REF_PREFIX)) getValue(value.removePrefix(REF_PREFIX)) else value

private const val ADMIN_CALLER_PREFIX = "admin:"

private fun loadAcceptanceScenarios(): List<AcceptanceScenario> =
    Files
        .list(resolveAcceptanceScenariosDir())
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
                        ?.any { it.jsonPrimitive.content == "server" }
                        ?: false
                }.map { json.decodeFromString(AcceptanceScenario.serializer(), it) }
                .toList()
        }

private fun resolveAcceptanceScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

package deploy.jvm

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
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
import persistence.changes.ProductTypePayload
import persistence.changes.ScopeSyncResult
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.model.EntityType
import persistence.model.ProductType
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
        assertEquals("empty", scenario.given.backendState, "Unsupported backendState in ${scenario.id}")
        assertEquals("fresh", scenario.given.appState, "Unsupported appState in ${scenario.id}")

        val savedCursorRefs = mutableMapOf<String, String>()
        var lastRawResponse: java.net.http.HttpResponse<String>? = null
        var lastDecodedResponse: SyncResponse? = null

        for (step in scenario.steps) {
            assertEquals("client", step.actor, "Unsupported actor in ${scenario.id}")
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")

            val request = resolveRefs(step.request, savedCursorRefs)
            val rawResponse = postRawSync(request)
            lastRawResponse = rawResponse
            lastDecodedResponse =
                if (rawResponse.statusCode() == 200) {
                    json.decodeFromString(SyncResponse.serializer(), rawResponse.body())
                } else {
                    null
                }

            step.save?.cursorRefs?.forEach { (entityType, refName) ->
                val cursor = lastDecodedResponse?.cursorFor(entityType)
                assertNotNull(cursor, "Missing cursor for $entityType in ${scenario.id}")
                savedCursorRefs[refName] = cursor
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
            )
        }
    }

    private fun resolveRefs(
        request: SyncRequest,
        savedCursorRefs: Map<String, String>,
    ): SyncRequest =
        request.copy(
            cursors =
                request.cursors.entries.associate { (rawKey, rawCursor) ->
                    val scopeKey = legacyCursorKeyToScopeKey(rawKey)
                    val cursor =
                        rawCursor?.let {
                            if (it.startsWith("\$ref:")) {
                                savedCursorRefs.getValue(it.removePrefix("\$ref:"))
                            } else {
                                it
                            }
                        }
                    scopeKey to cursor
                },
        )

    private fun legacyCursorKeyToScopeKey(rawKey: String): String =
        when (runCatching { EntityType.valueOf(rawKey) }.getOrNull()) {
            EntityType.ProductType -> SyncScope.ProducerAccount(tenantId).key

            EntityType.OrganizationRequest,
            EntityType.Owner,
            EntityType.OwnerInvitation,
            EntityType.Member,
            -> SyncScope.InstanceOwner.key

            null -> rawKey

            else -> rawKey
        }

    private fun assertSyncResponse(
        scenarioId: String,
        actual: SyncResponse,
        expected: AcceptanceResponseExpectation,
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
            assertEquals(expectedOutcome.status, actualOutcome.status, "Unexpected mutation status in $scenarioId")
            expectedOutcome.serverEntityId?.let { expectation ->
                assertStringExpectation(
                    expectation = expectation,
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

        val allChanges = actual.incrementalChanges()
        expected.containsChanges.forEach { expectedChange ->
            assertTrue(
                allChanges.any {
                    it.entityType == expectedChange.entityType &&
                        it.entityId == expectedChange.entityId &&
                        it.op.name == expectedChange.op
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

    private fun SyncResponse.cursorFor(entityType: EntityType): String? =
        when (val result = resultFor(entityType)) {
            is BootstrapScopeResult -> result.nextCursor
            is IncrementalScopeResult -> result.nextCursor
            null -> null
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

    private fun payloadMatches(
        payload: EntityPayload,
        expectedSubset: JsonObject,
    ): Boolean {
        val actualObject =
            when (payload) {
                is ProductTypePayload -> {
                    json
                        .encodeToJsonElement(ProductType.serializer(), payload.productType)
                        .jsonObject
                }

                else -> {
                    error("Unsupported payload type for acceptance scenario matching: ${payload::class.simpleName}")
                }
            }
        return expectedSubset.entries.all { (key, expectedValue) -> actualObject[key] == expectedValue }
    }
}

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

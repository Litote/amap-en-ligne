package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.ClientMutation
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.Organization
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Executes acceptance scenarios tagged with "coordinator-flow" from
 * `acceptance/scenarios/`.
 *
 * These scenarios require a pre-seeded organization with a PLANNED delivery
 * whose [DeliveryContract] has an empty `coordinators` list, then a role-
 * specific token (coordinator or admin) submits the actual mutation under
 * test. The generic [AcceptanceScenariosTest] cannot run them because its
 * harness assumes an empty backend state and a single "client" actor.
 *
 * Each scenario's `actor` field selects the token used to replay the step
 * ("coordinator" or "admin"). The shared seed state is the same in both
 * scenarios: org-1 with delivery-1 (PLANNED) + contract-1 (no coordinators).
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class CoordinatorAssignmentScenariosTest : JvmSyncTestSupport() {
    private val organizationId = "org-1"
    private val deliveryId = "delivery-1"
    private val contractId = "contract-1"
    private val coordinatorMemberId = "coordinator-1"
    private val adminMemberId = "admin-1"

    @Test
    fun `documented coordinator-flow acceptance scenarios pass`() =
        runTest {
            loadCoordinatorFlowScenarios()
                .forEach { scenario ->
                    resetDb()
                    executeCoordinatorScenario(scenario)
                }
        }

    private fun executeCoordinatorScenario(scenario: AcceptanceScenario) {
        // Seed the organization with a PLANNED delivery + empty coordinators
        // via an ADMIN token. ADMIN is a privileged caller in OrganizationService
        // so the MISSING_COORDINATOR guard is bypassed on PLANNED status.
        seedOrganizationWithEmptyCoordinator()

        // Each scenario step is replayed under a role-specific token.
        var lastRawResponse: java.net.http.HttpResponse<String>? = null

        for (step in scenario.steps) {
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")

            val token =
                when (step.actor) {
                    "coordinator" -> coordinatorToken
                    "admin" -> adminToken
                    else -> error("Unsupported actor `${step.actor}` in ${scenario.id}")
                }

            val rawResponse = postRawSyncAs(token, step.request)
            lastRawResponse = rawResponse
        }

        val expectation =
            assertNotNull(
                scenario.then.lastResponse,
                "Scenario ${scenario.id} has no lastResponse expectation",
            )
        val rawResponse = assertNotNull(lastRawResponse, "Scenario ${scenario.id} executed no steps")
        assertEquals(
            expectation.statusCode,
            rawResponse.statusCode(),
            "Unexpected status in ${scenario.id}: ${rawResponse.body()}",
        )

        if (expectation.statusCode == 200) {
            val decoded = json.decodeFromString(SyncResponse.serializer(), rawResponse.body())
            assertEquals(
                expectation.mutationOutcomes.size,
                decoded.mutations.size,
                "Unexpected mutation outcome count in ${scenario.id}",
            )
            expectation.mutationOutcomes.forEach { expectedOutcome ->
                val actualOutcome =
                    assertNotNull(
                        decoded.mutations.find { it.clientOpId == expectedOutcome.clientOpId },
                        "Missing mutation outcome ${expectedOutcome.clientOpId} in ${scenario.id}",
                    )
                assertEquals(
                    expectedOutcome.status,
                    actualOutcome.status,
                    "Unexpected mutation status for ${expectedOutcome.clientOpId} in ${scenario.id}: " +
                        "error=${actualOutcome.error}",
                )
                expectedOutcome.error?.let { expectedError ->
                    assertEquals(
                        expectedError.code,
                        actualOutcome.error?.code?.name,
                        "Unexpected error code for ${expectedOutcome.clientOpId} in ${scenario.id}",
                    )
                }
                expectedOutcome.serverEntityId?.let { expectation ->
                    when (expectation.kind) {
                        "equals" -> {
                            assertEquals(
                                expectation.value,
                                actualOutcome.serverEntityId,
                                "Unexpected serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        else -> {
                            error("Unsupported string expectation kind `${expectation.kind}` in ${scenario.id}")
                        }
                    }
                }
            }
        }
    }

    private val coordinatorToken: String
        get() =
            mintGoTrueToken(
                subject = coordinatorMemberId,
                email = "coordinator@example.com",
                roles = listOf("COORDINATOR"),
                organizationId = organizationId,
                producerAccountId = null,
            )

    private val adminToken: String
        get() =
            mintGoTrueToken(
                subject = adminMemberId,
                email = "admin@example.com",
                roles = listOf("ADMIN"),
                organizationId = organizationId,
                producerAccountId = null,
            )

    private fun seedMembers() {
        // Organization must exist before members (FK constraint).
        // After sub/id unification: memberId == sub. Insert member rows so that
        // AuthorizedScopeResolver can resolve the organization scope for each caller.
        insertOrganizationDirectly(organizationId)
        insertMemberDirectly(adminMemberId, organizationId, listOf("ADMIN"))
        insertMemberDirectly(coordinatorMemberId, organizationId, listOf("COORDINATOR"))
    }

    private fun seedOrganizationWithEmptyCoordinator() {
        seedMembers()
        val orgTimestamp: Instant = Instant.parse("2025-01-01T00:00:00Z")
        val contract =
            DeliveryContract(
                contractId = contractId.toId(),
                coordinators = emptyList(),
                basketQuantity = 10,
                deliveryDescription = "Weekly basket",
                status = DeliveryContractStatus.PENDING,
                slots = emptyList(),
            )

        val delivery =
            persistence.model.Delivery(
                deliveryId = deliveryId.toId(),
                organizationId = organizationId.toId(),
                scheduledDate = LocalDateTime.parse("2099-06-15T18:00:00"),
                status = DeliveryStatus.PLANNED,
                minVolunteersRequired = 2,
                contracts = listOf(contract),
            )

        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP des Collines",
                contactEmail = "contact@amap.example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = orgTimestamp,
                lastUpdatedInstant = orgTimestamp,
                deliveries = listOf(delivery),
            )

        val request =
            SyncRequest(
                cursors = mapOf(SyncScope.Organization(organizationId).key to null),
                mutations =
                    listOf(
                        ClientMutation(
                            clientOpId = "seed-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
            )

        val rawResponse = postRawSyncAs(adminToken, request)
        assertEquals(
            200,
            rawResponse.statusCode(),
            "Seed request failed (${rawResponse.statusCode()}): ${rawResponse.body()}",
        )
        val decoded = json.decodeFromString(SyncResponse.serializer(), rawResponse.body())
        val outcome = decoded.mutations.firstOrNull { it.clientOpId == "seed-org" }
        assertNotNull(outcome, "Seed mutation outcome missing")
        assertEquals(
            MutationStatus.APPLIED,
            outcome.status,
            "Seed mutation was not APPLIED: ${outcome.status}",
        )
    }

    private fun postRawSyncAs(
        token: String,
        request: SyncRequest,
    ): java.net.http.HttpResponse<String> {
        val bodyStr = json.encodeToString(SyncRequest.serializer(), request)
        val httpRequest =
            java.net.http.HttpRequest
                .newBuilder()
                .uri(java.net.URI("http://127.0.0.1:$port/v1/sync"))
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .POST(
                    java.net.http.HttpRequest.BodyPublishers
                        .ofString(bodyStr),
                ).build()
        return httpClient.send(
            httpRequest,
            java.net.http.HttpResponse.BodyHandlers
                .ofString(),
        )
    }
}

private fun loadCoordinatorFlowScenarios(): List<AcceptanceScenario> =
    Files
        .list(resolveCoordinatorScenariosDir())
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
                        ?.any { it.jsonPrimitive.content == "coordinator-flow" }
                        ?: false
                }.map { json.decodeFromString(AcceptanceScenario.serializer(), it) }
                .toList()
        }

private fun resolveCoordinatorScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

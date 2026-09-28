package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.MutationStatus
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.MemberContractStatus
import persistence.model.MemberSubscription
import persistence.model.ProductPrice
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Executes acceptance scenarios tagged with "contract-lifecycle" from
 * `acceptance/scenarios/`.
 *
 * These scenarios require a pre-seeded organization with a persisted [Contract]
 * whose [Contract.maxDeliveryDate] is in the past, along with at least one
 * existing [ContractMember]. The generic [AcceptanceScenariosTest] cannot run
 * them because its harness assumes an empty backend state and a single "client"
 * actor.
 *
 * Each scenario's `actor` field selects the token used to replay the step.
 * Supported actors: "admin" (ADMIN role), "member" (MEMBER role, no COORDINATOR).
 * The shared seed state is: org-1 with contract-1 (season 2020, ended) containing
 * member-1 as an existing subscriber; contract-2 (IN_PREPARATION, future dates)
 * with no members.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class ContractLifecycleScenariosTest : JvmSyncTestSupport() {
    private val organizationId = "org-1"
    private val contractId = "contract-1"
    private val adminMemberId = "admin-1"
    private val existingMemberId = "member-1"

    @Test
    fun `documented contract-lifecycle acceptance scenarios pass`() =
        runTest {
            loadContractLifecycleScenarios()
                .forEach { scenario ->
                    resetDb()
                    executeContractLifecycleScenario(scenario)
                }
        }

    private fun executeContractLifecycleScenario(scenario: AcceptanceScenario) {
        // GIVEN: org-1 with a persisted ended contract (season 2020) containing member-1.
        seedEndedContractWithOneMember()

        // WHEN: replay each step under the actor's token.
        var lastRawResponse: java.net.http.HttpResponse<String>? = null
        for (step in scenario.steps) {
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")
            val token =
                when (step.actor) {
                    "admin" -> adminToken
                    "member" -> memberToken
                    else -> error("Unsupported actor `${step.actor}` in ${scenario.id}")
                }
            lastRawResponse = postRawSyncAs(token, step.request)
        }

        // THEN: verify the last HTTP response matches the scenario expectation.
        val expectation =
            assertNotNull(
                scenario.then.lastResponse,
                "Scenario ${scenario.id} has no lastResponse expectation",
            )
        val rawResponse = assertNotNull(lastRawResponse, "Scenario ${scenario.id} executed no steps")
        assertEquals(
            expectation.statusCode,
            rawResponse.statusCode(),
            "Unexpected HTTP status in ${scenario.id}: ${rawResponse.body()}",
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
                    // Pin the exact wire string so any renaming of the enum constant breaks the test.
                    assertEquals(
                        expectedError.code,
                        actualOutcome.error?.code?.name,
                        "Unexpected error code for ${expectedOutcome.clientOpId} in ${scenario.id}",
                    )
                }
                expectedOutcome.serverEntityId?.let { expectation ->
                    when (expectation.kind) {
                        "non-empty-string" -> {
                            assertTrue(
                                !actualOutcome.serverEntityId.isNullOrBlank(),
                                "Expected non-empty serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        "present-and-not-equal" -> {
                            val unexpected =
                                assertNotNull(expectation.value, "Missing comparison value for serverEntityId in ${scenario.id}")
                            assertNotNull(
                                actualOutcome.serverEntityId,
                                "Expected present serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                            assertTrue(
                                actualOutcome.serverEntityId != unexpected,
                                "Expected serverEntityId to differ from $unexpected for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        "equals" -> {
                            assertEquals(
                                expectation.value,
                                actualOutcome.serverEntityId,
                                "Unexpected serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        else -> {
                            error("Unsupported serverEntityId expectation kind `${expectation.kind}` in ${scenario.id}")
                        }
                    }
                }
            }
        }
    }

    private val adminToken: String
        get() =
            mintGoTrueToken(
                subject = adminMemberId,
                email = "admin@example.com",
                roles = listOf("ADMIN"),
                organizationId = organizationId,
                producerAccountId = null,
            )

    /** Token for an ordinary member (VOLUNTEER role, no COORDINATOR/ADMIN). */
    private val memberToken: String
        get() =
            mintGoTrueToken(
                subject = existingMemberId,
                email = "member@example.com",
                roles = listOf("VOLUNTEER"),
                organizationId = organizationId,
                producerAccountId = null,
            )

    /**
     * Seeds org-1 with:
     * - contract-1 (season 2020, max_delivery_date = 2020-06-30, ended) containing member-1
     * - contract-2 (future dates, status = IN_PREPARATION) with no members
     *
     * Both contracts are created via sync mutations using their real ids so that they are
     * stored in the database before the scenario's mutation is applied.  Because
     * [Contract.isEffectivelyEnded] checks the persisted state, the seed upserts (no prior
     * row) bypass the guard and are always APPLIED.
     */
    private fun seedEndedContractWithOneMember() {
        insertOrganizationDirectly(organizationId)
        insertMemberDirectly(adminMemberId, organizationId, listOf("ADMIN"))
        insertMemberDirectly(existingMemberId, organizationId, listOf("VOLUNTEER"))

        val endedContract =
            Contract(
                contractId = contractId.toId(),
                name = "Saison 2020",
                organizationId = organizationId.toId(),
                producerAccountId = "producer-1".toId(),
                minDeliveryDate = LocalDate(2020, 1, 1),
                maxDeliveryDate = LocalDate(2020, 6, 30),
                deliveryCount = 26,
                seasonYear = 2020,
                productPrices =
                    listOf(
                        ProductPrice(productTypeId = "pt-tomato"),
                        ProductPrice(productTypeId = "pt-eggs"),
                    ),
                members =
                    listOf(
                        ContractMember(
                            memberId = existingMemberId.toId(),
                            subscriptionInstant = Instant.parse("2020-01-01T00:00:00Z"),
                            status = MemberContractStatus.ACTIVE,
                            subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                        ),
                    ),
            )

        val inPreparationContract =
            Contract(
                contractId = "contract-2".toId(),
                name = "Saison 2027 (in preparation)",
                organizationId = organizationId.toId(),
                producerAccountId = "producer-1".toId(),
                minDeliveryDate = LocalDate(2027, 1, 1),
                maxDeliveryDate = LocalDate(2027, 12, 31),
                deliveryCount = 52,
                seasonYear = 2027,
                status = ContractStatus.IN_PREPARATION,
                productPrices = listOf(ProductPrice(productTypeId = "pt-vegetables")),
                members = emptyList(),
            )

        val request =
            SyncRequest(
                cursors = mapOf(SyncScope.Organization(organizationId).key to null),
                mutations =
                    listOf(
                        ClientMutation(
                            clientOpId = "seed-contract",
                            op = Upsert(ContractPayload(endedContract)),
                        ),
                        ClientMutation(
                            clientOpId = "seed-contract-2",
                            op = Upsert(ContractPayload(inPreparationContract)),
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
        listOf("seed-contract", "seed-contract-2").forEach { opId ->
            val outcome = decoded.mutations.firstOrNull { it.clientOpId == opId }
            assertNotNull(outcome, "Seed mutation outcome missing for $opId")
            assertEquals(
                MutationStatus.APPLIED,
                outcome.status,
                "Seed mutation $opId was not APPLIED: ${outcome.status}",
            )
        }
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

private fun loadContractLifecycleScenarios(): List<AcceptanceScenario> =
    Files
        .list(resolveContractLifecycleScenariosDir())
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
                        ?.any { it.jsonPrimitive.content == "contract-lifecycle" }
                        ?: false
                }.map { json.decodeFromString(AcceptanceScenario.serializer(), it) }
                .toList()
        }

private fun resolveContractLifecycleScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

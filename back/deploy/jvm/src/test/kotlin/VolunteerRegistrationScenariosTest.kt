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
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.ActivityType
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EarlySlot
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Executes acceptance scenarios tagged with "volunteer-flow" from
 * `acceptance/scenarios/`.
 *
 * These scenarios require a multi-actor setup that the generic
 * [AcceptanceScenariosTest] does not support: a privileged coordinator pre-
 * seeds the database with an org + delivery, then a volunteer token submits
 * the registration mutation to test.
 *
 * Each scenario describes the setup state in its `given.backendState` field.
 * This test class reads that field to determine which helper to call before
 * executing the `when` steps.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class VolunteerRegistrationScenariosTest : JvmSyncTestSupport() {
    private val organizationId = "org-1"
    private val volunteerId = "volunteer-1"
    private val otherMemberId = "other-member"
    private val deliveryId = "delivery-1"
    private val contractId = "contract-1"

    /**
     * GoTrue token whose `app_metadata` carries VOLUNTEER role on org-1.
     *
     * The JWT subject is set to [volunteerId] so that [authentication.AuthenticatedInfo.memberId]
     * equals the `member_id` used in the acceptance scenario registration payloads.
     * The [insertMemberDirectly] call keeps the member table row consistent: since
     * `member_id == sub` by convention, the DAO lookup via [findOrganizationIdBySub] will
     * resolve to org-1 when the volunteer calls POST /v1/sync.
     */
    private val volunteerToken: String
        get() =
            mintGoTrueToken(
                subject = volunteerId,
                email = "volunteer@example.com",
                roles = listOf("VOLUNTEER"),
                organizationId = organizationId,
                producerAccountId = null,
            ).also {
                insertMemberDirectly(
                    memberId = volunteerId,
                    organizationId = organizationId,
                    roles = listOf("VOLUNTEER"),
                )
            }

    @Test
    fun `documented volunteer-flow acceptance scenarios pass`() =
        runTest {
            loadVolunteerFlowScenarios()
                .forEach { scenario ->
                    resetDb()
                    executeVolunteerScenario(scenario)
                }
        }

    private fun executeVolunteerScenario(scenario: AcceptanceScenario) {
        val backendState = scenario.given.backendState
        val coordinatorSubject = "00000000-0000-0000-0000-000000000005"

        // Seed org + member rows so AuthorizedScopeResolver can resolve org scopes.
        // Organization must exist before member (FK constraint). After sub/id unification: memberId == sub.
        insertOrganizationDirectly(organizationId)
        insertMemberDirectly(coordinatorSubject, organizationId, listOf("COORDINATOR"))

        // Seed the shared coordinator token to set up the initial org state.
        val coordinatorToken =
            mintGoTrueToken(
                subject = coordinatorSubject,
                email = "coordinator@example.com",
                roles = listOf("COORDINATOR"),
                organizationId = organizationId,
                producerAccountId = null,
            )

        when {
            backendState.contains("delivery-level early_slot override") -> {
                // Seed a template-less delivery whose own early_slot override (not a
                // template) sets the EARLY-slot capacity, plus an empty EARLY slot.
                seedOrganizationWithEarlySlotOverrideDelivery(coordinatorToken)
            }

            backendState.contains("org-1") && backendState.contains("delivery-1") -> {
                // Seed the organization + delivery via sync as COORDINATOR.
                val hasExistingRegistration =
                    backendState.contains("existing registration for member:volunteer-1")
                seedOrganizationWithDelivery(coordinatorToken, hasExistingRegistration)
            }

            else -> {
                error("Unsupported backendState in scenario ${scenario.id}: $backendState")
            }
        }

        // Now execute each step using the volunteer token.
        val volunteerBearerToken = volunteerToken
        var lastRawResponse: java.net.http.HttpResponse<String>? = null

        for (step in scenario.steps) {
            assertEquals("volunteer", step.actor, "Unsupported actor in ${scenario.id}")
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")

            val rawResponse = postRawSyncAs(volunteerBearerToken, step.request)
            lastRawResponse = rawResponse
        }

        val expectation =
            assertNotNull(
                scenario.then.lastResponse,
                "Scenario ${scenario.id} has no lastResponse expectation",
            )
        val rawResponse = assertNotNull(lastRawResponse, "Scenario ${scenario.id} executed no steps")
        assertEquals(expectation.statusCode, rawResponse.statusCode(), "Unexpected status in ${scenario.id}")

        if (expectation.statusCode == 200) {
            val decoded =
                json.decodeFromString(
                    persistence.changes.SyncResponse.serializer(),
                    rawResponse.body(),
                )
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
                    "Unexpected mutation status for ${expectedOutcome.clientOpId} in ${scenario.id}",
                )
                expectedOutcome.serverEntityId?.let { expectation ->
                    when (expectation.kind) {
                        "equals" -> {
                            assertEquals(
                                expectation.value,
                                actualOutcome.serverEntityId,
                                "Unexpected serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        "non-empty-string" -> {
                            assertTrue(
                                !actualOutcome.serverEntityId.isNullOrBlank(),
                                "Expected non-empty serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        else -> {
                            error("Unsupported string expectation kind '${expectation.kind}' in ${scenario.id}")
                        }
                    }
                }
            }
        }
    }

    private fun postRawSyncAs(
        token: String,
        request: persistence.changes.SyncRequest,
    ): java.net.http.HttpResponse<String> {
        val bodyStr = json.encodeToString(persistence.changes.SyncRequest.serializer(), request)
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
        return httpClient
            .send(
                httpRequest,
                java.net.http.HttpResponse.BodyHandlers
                    .ofString(),
            )
    }

    /**
     * Seeds org-1 with a future delivery containing a STANDARD slot.
     * [withExistingRegistration] adds volunteer-1's registration upfront when `true`.
     *
     * The organization [createdInstant] and [lastUpdatedInstant] are fixed to
     * `"2025-01-01T00:00:00Z"` so that the [VolunteerMutationValidator] structural
     * equality check passes when the acceptance scenario payload carries those same
     * fixed timestamps.
     */
    private fun seedOrganizationWithDelivery(
        coordinatorToken: String,
        withExistingRegistration: Boolean,
    ) {
        // Fixed timestamp that all volunteer-flow scenario payloads use for org fields.
        val orgTimestamp: Instant = Instant.parse("2025-01-01T00:00:00Z")
        val registrations =
            if (withExistingRegistration) {
                listOf(
                    MemberRegistration(
                        memberId = volunteerId.toId(),
                        displayName = "Alice Volunteer",
                        memberEmail = "volunteer@example.com",
                        registrationInstant = Instant.parse("2099-06-01T10:00:00Z"),
                        status = RegistrationStatus.REGISTERED,
                    ),
                )
            } else {
                emptyList()
            }

        val slot =
            MemberSlot(
                startTime = LocalDateTime.parse("2099-06-15T18:00:00"),
                endTime = LocalDateTime.parse("2099-06-15T20:00:00"),
                activityType = ActivityType.RECEPTION,
                requiredVolunteers = 2,
                currentRegistrations = registrations.size,
                status = SlotStatus.OPEN,
                slotKind = SlotKind.STANDARD,
                registrations = registrations,
            )

        val contract =
            DeliveryContract(
                contractId = contractId.toId(),
                coordinators = listOf("coordinator-1".toId()),
                basketQuantity = 10,
                deliveryDescription = "Weekly basket",
                status = DeliveryContractStatus.PENDING,
                slots = listOf(slot),
            )

        val delivery =
            Delivery(
                deliveryId = deliveryId.toId(),
                organizationId = organizationId.toId(),
                scheduledDate = LocalDateTime.parse("2099-06-15T18:00:00"),
                status = DeliveryStatus.CONFIRMED,
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

        val mutation =
            ClientMutation(
                clientOpId = "seed-org",
                op = Upsert(OrganizationPayload(organization)),
            )

        val request =
            SyncRequest(
                cursors = mapOf(SyncScope.Organization(organizationId).key to null),
                mutations = listOf(mutation),
            )

        val rawResponse = postRawSyncAs(coordinatorToken, request)
        assertEquals(
            200,
            rawResponse.statusCode(),
            "Seed request failed (${rawResponse.statusCode()}): ${rawResponse.body()}",
        )
        val decoded =
            json.decodeFromString(persistence.changes.SyncResponse.serializer(), rawResponse.body())
        val outcome = decoded.mutations.firstOrNull { it.clientOpId == "seed-org" }
        assertNotNull(outcome, "Seed mutation outcome missing")
        assertEquals(
            MutationStatus.APPLIED,
            outcome.status,
            "Seed mutation was not APPLIED: ${outcome.status}",
        )
    }

    /**
     * Seeds org-1 with a future delivery that has **no template** but carries a
     * delivery-level [Delivery.earlySlot] override, plus an empty EARLY slot.
     *
     * This proves the per-delivery override path: with no template the back used
     * to reject any EARLY-slot registration (FORBIDDEN); the override now supplies
     * the capacity so the volunteer registration is APPLIED.
     */
    private fun seedOrganizationWithEarlySlotOverrideDelivery(coordinatorToken: String) {
        val orgTimestamp: Instant = Instant.parse("2025-01-01T00:00:00Z")

        val slot =
            MemberSlot(
                startTime = LocalDateTime.parse("2099-06-15T16:30:00"),
                endTime = LocalDateTime.parse("2099-06-15T18:00:00"),
                activityType = ActivityType.PREPARATION,
                requiredVolunteers = 2,
                currentRegistrations = 0,
                status = SlotStatus.OPEN,
                slotKind = SlotKind.EARLY,
                registrations = emptyList(),
            )

        val contract =
            DeliveryContract(
                contractId = contractId.toId(),
                coordinators = listOf("coordinator-1".toId()),
                basketQuantity = 10,
                deliveryDescription = "Weekly basket",
                status = DeliveryContractStatus.PENDING,
                slots = listOf(slot),
            )

        val delivery =
            Delivery(
                deliveryId = deliveryId.toId(),
                organizationId = organizationId.toId(),
                scheduledDate = LocalDateTime.parse("2099-06-15T18:00:00"),
                status = DeliveryStatus.CONFIRMED,
                minVolunteersRequired = 2,
                earlySlot =
                    EarlySlot(
                        arrivalTime = "16:30",
                        explanation = "Réception des légumes",
                        maxVolunteers = 2,
                    ),
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

        val mutation =
            ClientMutation(
                clientOpId = "seed-org",
                op = Upsert(OrganizationPayload(organization)),
            )

        val request =
            SyncRequest(
                cursors = mapOf(SyncScope.Organization(organizationId).key to null),
                mutations = listOf(mutation),
            )

        val rawResponse = postRawSyncAs(coordinatorToken, request)
        assertEquals(
            200,
            rawResponse.statusCode(),
            "Seed request failed (${rawResponse.statusCode()}): ${rawResponse.body()}",
        )
        val decoded =
            json.decodeFromString(persistence.changes.SyncResponse.serializer(), rawResponse.body())
        val outcome = decoded.mutations.firstOrNull { it.clientOpId == "seed-org" }
        assertNotNull(outcome, "Seed mutation outcome missing")
        assertEquals(
            MutationStatus.APPLIED,
            outcome.status,
            "Seed mutation was not APPLIED: ${outcome.status}",
        )
    }
}

private fun loadVolunteerFlowScenarios(): List<AcceptanceScenario> =
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
                        ?.any { it.jsonPrimitive.content == "volunteer-flow" }
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

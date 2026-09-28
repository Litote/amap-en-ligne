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
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.MutationStatus
import persistence.changes.NotificationPayload
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.ActivityType
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
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
 * Executes acceptance scenarios tagged with "time-slot-flow" from
 * `acceptance/scenarios/`.
 *
 * These scenarios require a pre-seeded organization with a PLANNED delivery
 * whose contract carries one OPEN slot (`slot-1`) with two active registrations
 * (member-1, member-2), then a coordinator token submits the slot lifecycle
 * mutation under test (cancel / delete / reschedule). The generic
 * [AcceptanceScenariosTest] cannot run them because its harness assumes an
 * empty backend state and a single "client" actor.
 *
 * Beyond the per-scenario `then.lastResponse` expectations, this runner also
 * verifies the server-side post-conditions documented by each scenario:
 *  - `time-slot-cancel`: registrations cascaded to CANCELLED, counter reset,
 *    SLOT_CANCELLED notification on each registered member's private feed;
 *  - `time-slot-reschedule`: registrations preserved, SLOT_RESCHEDULED
 *    notification on each registered member's private feed;
 *  - `time-slot-delete-conflict`: the slot is still present after rejection.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class TimeSlotLifecycleScenariosTest : JvmSyncTestSupport() {
    private val organizationId = "org-1"
    private val deliveryId = "delivery-1"
    private val contractId = "contract-1"
    private val slotId = "slot-1"
    private val coordinatorMemberId = "coordinator-1"
    private val memberOneId = "member-1"
    private val memberTwoId = "member-2"

    @Test
    fun `documented time-slot-flow acceptance scenarios pass`() =
        runTest {
            loadTimeSlotFlowScenarios()
                .forEach { scenario ->
                    resetDb()
                    executeTimeSlotScenario(scenario)
                }
        }

    private fun executeTimeSlotScenario(scenario: AcceptanceScenario) {
        seedOrganizationWithRegisteredSlot()

        var lastRawResponse: java.net.http.HttpResponse<String>? = null
        for (step in scenario.steps) {
            assertEquals("sync", step.action, "Unsupported action in ${scenario.id}")
            assertEquals("coordinator", step.actor, "Unsupported actor `${step.actor}` in ${scenario.id}")
            lastRawResponse = postRawSyncAs(coordinatorToken, step.request)
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
                expectedOutcome.serverEntityId?.let { stringExpectation ->
                    when (stringExpectation.kind) {
                        "equals" -> {
                            assertEquals(
                                stringExpectation.value,
                                actualOutcome.serverEntityId,
                                "Unexpected serverEntityId for ${expectedOutcome.clientOpId} in ${scenario.id}",
                            )
                        }

                        else -> {
                            error("Unsupported string expectation kind `${stringExpectation.kind}` in ${scenario.id}")
                        }
                    }
                }
            }
        }

        when (scenario.id) {
            "time-slot-cancel" -> verifyCancelPostConditions(scenario.id)
            "time-slot-reschedule" -> verifyReschedulePostConditions(scenario.id)
            "time-slot-delete-conflict" -> verifyDeleteConflictPostConditions(scenario.id)
            else -> error("Unknown time-slot-flow scenario ${scenario.id}: add its post-condition verification")
        }
    }

    private fun verifyCancelPostConditions(scenarioId: String) {
        val slot = fetchSlot(scenarioId)
        assertEquals(SlotStatus.CANCELLED, slot.status, "Slot not CANCELLED after $scenarioId")
        assertEquals(0, slot.currentRegistrations, "current_registrations not reset after $scenarioId")
        assertTrue(
            slot.registrations.isNotEmpty() && slot.registrations.all { it.status == RegistrationStatus.CANCELLED },
            "Registrations not cascaded to CANCELLED after $scenarioId",
        )
        listOf(memberOneId, memberTwoId).forEach { memberId ->
            assertMemberFeedHasNotification(memberId, NotificationCategory.SLOT_CANCELLED, scenarioId)
        }
    }

    private fun verifyReschedulePostConditions(scenarioId: String) {
        val slot = fetchSlot(scenarioId)
        assertEquals(LocalDateTime.parse("2099-06-15T19:00:00"), slot.startTime, "Slot not rescheduled after $scenarioId")
        assertTrue(
            slot.registrations.size == 2 && slot.registrations.all { it.status == RegistrationStatus.REGISTERED },
            "Registrations not preserved after $scenarioId",
        )
        listOf(memberOneId, memberTwoId).forEach { memberId ->
            assertMemberFeedHasNotification(memberId, NotificationCategory.SLOT_RESCHEDULED, scenarioId)
        }
    }

    private fun verifyDeleteConflictPostConditions(scenarioId: String) {
        val slot = fetchSlot(scenarioId)
        assertEquals(SlotStatus.OPEN, slot.status, "Slot must be untouched after rejected $scenarioId")
        assertEquals(2, slot.registrations.size, "Registrations must be untouched after rejected $scenarioId")
    }

    private fun fetchSlot(scenarioId: String): MemberSlot {
        val request = SyncRequest(cursors = mapOf(SyncScope.Organization(organizationId).key to null), mutations = emptyList())
        val response = postRawSyncAs(coordinatorToken, request)
        assertEquals(200, response.statusCode(), "Post-condition bootstrap failed in $scenarioId: ${response.body()}")
        val decoded = json.decodeFromString(SyncResponse.serializer(), response.body())
        val scopeResult = assertNotNull(decoded.results[SyncScope.Organization(organizationId).key])
        assertTrue(scopeResult is BootstrapScopeResult, "Expected bootstrap result in $scenarioId")
        val organization =
            assertNotNull(
                scopeResult.items.filterIsInstance<OrganizationPayload>().firstOrNull(),
                "Organization snapshot missing in $scenarioId",
            ).organization
        return assertNotNull(
            organization.deliveries
                .find { it.deliveryId.id == deliveryId }
                ?.contracts
                ?.find { it.contractId.id == contractId }
                ?.slots
                ?.find { it.slotId == slotId },
            "slot $slotId not found in $scenarioId",
        )
    }

    private fun assertMemberFeedHasNotification(
        memberId: String,
        category: NotificationCategory,
        scenarioId: String,
    ) {
        val token =
            mintGoTrueToken(
                subject = memberId,
                email = "$memberId@example.com",
                roles = listOf("VOLUNTEER"),
                organizationId = organizationId,
                producerAccountId = null,
            )
        val feedKey = SyncScope.Member(memberId).key
        val request = SyncRequest(cursors = mapOf(feedKey to null), mutations = emptyList())
        val response = postRawSyncAs(token, request)
        assertEquals(200, response.statusCode(), "Member feed sync failed for $memberId in $scenarioId: ${response.body()}")
        val decoded = json.decodeFromString(SyncResponse.serializer(), response.body())
        val scopeResult = assertNotNull(decoded.results[feedKey], "No $feedKey result for $memberId in $scenarioId")
        assertTrue(scopeResult is BootstrapScopeResult, "Expected bootstrap result on $feedKey in $scenarioId")
        val notifications = scopeResult.items.filterIsInstance<NotificationPayload>().map { it.notification }
        assertTrue(
            notifications.any { it.category == category },
            "Expected a $category notification on $feedKey in $scenarioId, got ${notifications.map { it.category }}",
        )
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

    private fun seedOrganizationWithRegisteredSlot() {
        // Organization must exist before members (FK constraint). memberId == sub by convention.
        insertOrganizationDirectly(organizationId)
        insertMemberDirectly(coordinatorMemberId, organizationId, listOf("COORDINATOR"))
        insertMemberDirectly(memberOneId, organizationId, listOf("VOLUNTEER"))
        insertMemberDirectly(memberTwoId, organizationId, listOf("VOLUNTEER"))

        val orgTimestamp: Instant = Instant.parse("2025-01-01T00:00:00Z")
        val slot =
            MemberSlot(
                slotId = slotId,
                startTime = LocalDateTime.parse("2099-06-15T18:00:00"),
                endTime = LocalDateTime.parse("2099-06-15T20:00:00"),
                activityType = ActivityType.RECEPTION,
                requiredVolunteers = 2,
                currentRegistrations = 2,
                status = SlotStatus.OPEN,
                slotKind = SlotKind.STANDARD,
                registrations =
                    listOf(
                        MemberRegistration(
                            memberId = memberOneId.toId(),
                            displayName = "Alice Volunteer",
                            memberEmail = "member-1@example.com",
                            registrationInstant = Instant.parse("2099-06-01T10:00:00Z"),
                            status = RegistrationStatus.REGISTERED,
                        ),
                        MemberRegistration(
                            memberId = memberTwoId.toId(),
                            displayName = "Bob Volunteer",
                            memberEmail = "member-2@example.com",
                            registrationInstant = Instant.parse("2099-06-01T11:00:00Z"),
                            status = RegistrationStatus.REGISTERED,
                        ),
                    ),
            )

        val contract =
            DeliveryContract(
                contractId = contractId.toId(),
                coordinators = listOf(coordinatorMemberId.toId()),
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

        val rawResponse = postRawSyncAs(coordinatorToken, request)
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

private fun loadTimeSlotFlowScenarios(): List<AcceptanceScenario> =
    Files
        .list(resolveTimeSlotScenariosDir())
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
                        ?.any { it.jsonPrimitive.content == "time-slot-flow" }
                        ?: false
                }.map { json.decodeFromString(AcceptanceScenario.serializer(), it) }
                .toList()
        }

private fun resolveTimeSlotScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

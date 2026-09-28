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
import persistence.changes.BasketExchangePayload
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.Organization
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/** Runs the `basket-exchange-flow` stories of `acceptance/scenarios` over real HTTP + Postgres. */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class BasketExchangeFlowScenariosTest : JvmSyncTestSupport() {
    @Test
    fun `documented basket exchange flow scenarios pass`() =
        runTest {
            val scenarios = loadBasketExchangeFlowScenarios()
            assertTrue(scenarios.isNotEmpty(), "No basket-exchange-flow scenario found")
            scenarios.forEach { scenario ->
                resetDb()
                executeScenario(scenario)
            }
        }

    private fun executeScenario(scenario: BasketExchangeFlowScenario) {
        val given = scenario.given
        insertOrganizationDirectly(given.organizationId)
        given.members.forEach { insertMemberDirectly(it.memberId, given.organizationId, it.roles) }
        val rolesByMember = given.members.associate { it.memberId to it.roles }
        seedDeliveries(given)

        val offerIds = mutableMapOf<String, String>()
        scenario.steps.forEach { step ->
            val actor = Actor(step.actor, rolesByMember[step.actor] ?: error("Unknown actor ${step.actor} in ${scenario.id}"))
            val label = "${step.action} by ${step.actor} in ${scenario.id}"
            val exchange =
                when (step.action) {
                    "create_offer" -> {
                        BasketExchange(
                            basketExchangeId = "tmp_offer".toId(),
                            organizationId = given.organizationId.toId(),
                            deliveryId = step.param("deliveryId").toId(),
                            contractId = step.param("contractId").toId(),
                            offeringMemberId = step.actor.toId(),
                            status = BasketExchangeStatus.OPEN,
                            createdAt = Clock.System.now(),
                        )
                    }

                    "submit_request" -> {
                        val offer = readExchange(given.organizationId, actor, offerIds.getValue(step.param("offer")))
                        offer.copy(
                            requests =
                                offer.requests +
                                    BasketExchangeRequest(
                                        requestId = "tmp_request".toId(),
                                        requesterMemberId = step.actor.toId(),
                                        createdAt = Clock.System.now(),
                                        status = BasketExchangeRequestStatus.PENDING,
                                        proposedDeliveryId = step.param("proposedDeliveryId").toId(),
                                        proposedContractId = step.param("proposedContractId").toId(),
                                    ),
                        )
                    }

                    "accept_request" -> {
                        val offer = readExchange(given.organizationId, actor, offerIds.getValue(step.param("offer")))
                        val accepted =
                            offer.requests.singleOrNull { it.requesterMemberId.id == step.param("requester") }
                                ?: error("No request from ${step.param("requester")} for $label")
                        offer.copy(status = BasketExchangeStatus.ACCEPTED, acceptedRequestId = accepted.requestId)
                    }

                    else -> {
                        error("Unsupported action '${step.action}' in ${scenario.id}")
                    }
                }
            val outcome = upsert(actor, given.organizationId, exchange, clientOpId = "${step.action}-${step.actor}")
            assertEquals(step.expect.status, outcome.status, "Unexpected outcome for $label: $outcome")
            step.expect.errorCode?.let { assertEquals(it, outcome.error?.code?.name, "Unexpected error code for $label") }
            step.save?.offerRef?.let { ref ->
                offerIds[ref] = assertNotNull(outcome.serverEntityId, "Missing offer id for $label")
            }
        }

        val expected = scenario.then.exchange
        val viewer = Actor(expected.viewedBy, rolesByMember.getValue(expected.viewedBy))
        val final = readExchange(given.organizationId, viewer, offerIds.getValue(expected.offer))
        assertEquals(expected.status, final.status, "Unexpected exchange status in ${scenario.id}")
        expected.acceptedRequester?.let { requester ->
            val acceptedRequest = final.requests.singleOrNull { it.requestId == final.acceptedRequestId }
            assertEquals(requester, acceptedRequest?.requesterMemberId?.id, "Unexpected accepted requester in ${scenario.id}")
        }
        assertEquals(
            expected.requestStatuses,
            final.requests.associate { it.requesterMemberId.id to it.status },
            "Unexpected request statuses in ${scenario.id}",
        )
    }

    private class Actor(
        val memberId: String,
        val roles: List<String>,
    )

    private fun BasketExchangeFlowStep.param(name: String): String = params[name] ?: error("Missing param $name for $action")

    private fun tokenFor(
        actor: Actor,
        organizationId: String,
    ): String =
        mintGoTrueToken(
            subject = actor.memberId,
            email = "${actor.memberId}@example.com",
            roles = actor.roles,
            organizationId = organizationId,
            producerAccountId = null,
        )

    private fun upsert(
        actor: Actor,
        organizationId: String,
        exchange: BasketExchange,
        clientOpId: String,
    ): MutationOutcome =
        sync(
            actor,
            organizationId,
            SyncRequest(mutations = listOf(ClientMutation(clientOpId, Upsert(BasketExchangePayload(exchange))))),
        ).mutations.single()

    /** The exchange as the actor's own organization bootstrap serves it. */
    private fun readExchange(
        organizationId: String,
        actor: Actor,
        exchangeId: String,
    ): BasketExchange {
        val scopeKey = SyncScope.Organization(organizationId).key
        val result = sync(actor, organizationId, SyncRequest(cursors = mapOf(scopeKey to null))).results[scopeKey]
        return (result as BootstrapScopeResult)
            .items
            .filterIsInstance<BasketExchangePayload>()
            .map { it.basketExchange }
            .singleOrNull { it.basketExchangeId.id == exchangeId }
            ?: error("Exchange $exchangeId not visible to ${actor.memberId}")
    }

    private fun sync(
        actor: Actor,
        organizationId: String,
        request: SyncRequest,
    ): SyncResponse {
        val raw = postRawSyncAs(tokenFor(actor, organizationId), json.encodeToString(SyncRequest.serializer(), request))
        assertEquals(200, raw.statusCode(), "sync failed: ${raw.body()}")
        return json.decodeFromString(SyncResponse.serializer(), raw.body())
    }

    /** Seeds the future deliveries through a coordinator's `Organization` upsert, like the delivery form. */
    private fun seedDeliveries(given: BasketExchangeFlowGiven) {
        val coordinator = Actor("basket-exchange-flow-coordinator", listOf("COORDINATOR"))
        insertMemberDirectly(coordinator.memberId, given.organizationId, coordinator.roles)
        val now = Instant.parse("2025-01-01T00:00:00Z")
        val organization =
            Organization(
                organizationId = given.organizationId.toId(),
                name = "Test Organization",
                contactEmail = "test@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = now,
                lastUpdatedInstant = now,
                deliveries =
                    given.deliveries.map { delivery ->
                        Delivery(
                            deliveryId = delivery.deliveryId.toId(),
                            organizationId = given.organizationId.toId(),
                            scheduledDate = LocalDateTime.parse(delivery.scheduledDate),
                            status = DeliveryStatus.PLANNED,
                            minVolunteersRequired = 1,
                            contracts =
                                listOf(
                                    DeliveryContract(
                                        contractId = delivery.contractId.toId(),
                                        basketQuantity = 10,
                                        deliveryDescription = "Weekly basket",
                                        status = DeliveryContractStatus.PENDING,
                                    ),
                                ),
                        )
                    },
            )
        val outcome =
            sync(
                coordinator,
                given.organizationId,
                SyncRequest(mutations = listOf(ClientMutation("seed-deliveries", Upsert(OrganizationPayload(organization))))),
            ).mutations.single()
        assertEquals(MutationStatus.APPLIED, outcome.status, "Delivery seeding failed: $outcome")
    }
}

private fun loadBasketExchangeFlowScenarios(): List<BasketExchangeFlowScenario> =
    Files
        .list(resolveBasketExchangeFlowScenariosDir())
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
                        ?.any { it.jsonPrimitive.content == "basket-exchange-flow" }
                        ?: false
                }.map { json.decodeFromString(BasketExchangeFlowScenario.serializer(), it) }
                .toList()
        }

private fun resolveBasketExchangeFlowScenariosDir(): Path {
    var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
    repeat(6) {
        val candidate = current.resolve("acceptance").resolve("scenarios")
        if (Files.isDirectory(candidate)) return candidate
        current = current.parent ?: return@repeat
    }
    error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
}

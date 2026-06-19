package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BasketExchangePayload
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
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
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * End-to-end reciprocal-swap flow over real HTTP + Postgres:
 *
 *  1. A coordinator seeds an org with two future deliveries (D1, D2).
 *  2. Member A (offerer) creates an exchange offer on D1.
 *  3. Member B (requester) submits a request proposing D2 in return.
 *  4. Member A validates the request — the exchange is confirmed.
 *
 * Also covers the basket double-booking guard (A cannot re-offer D1 once committed).
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class BasketExchangeFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-ex"
    private val coordinatorId = "00000000-0000-0000-0000-000000000005"
    private val offererId = "offerer-1"
    private val requesterId = "requester-1"
    private val d1 = "delivery-d1"
    private val d2 = "delivery-d2"
    private val c1 = "contract-c1"
    private val c2 = "contract-c2"
    private val orgScope = SyncScope.Organization(organizationId).key

    @Test
    fun `reciprocal swap is created, requested with a counter-delivery, and validated`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            insertMemberDirectly(coordinatorId, organizationId, listOf("COORDINATOR"))
            insertMemberDirectly(offererId, organizationId, listOf("VOLUNTEER"))
            insertMemberDirectly(requesterId, organizationId, listOf("VOLUNTEER"))

            val coordinatorToken = token(coordinatorId, "COORDINATOR")
            val offererToken = token(offererId, "VOLUNTEER")
            val requesterToken = token(requesterId, "VOLUNTEER")

            seedOrgWithTwoDeliveries(coordinatorToken)

            // 1. Offerer creates an offer on D1.
            val createOutcome =
                applyMutation(
                    offererToken,
                    ClientMutation(
                        clientOpId = "create-offer",
                        op =
                            Upsert(
                                BasketExchangePayload(
                                    BasketExchange(
                                        basketExchangeId = "tmp_be".toId(),
                                        organizationId = organizationId.toId(),
                                        deliveryId = d1.toId(),
                                        contractId = c1.toId(),
                                        offeringMemberId = offererId.toId(),
                                        status = BasketExchangeStatus.OPEN,
                                        createdAt = Instant.parse("2025-01-01T00:00:00Z"),
                                    ),
                                ),
                            ),
                    ),
                )
            assertEquals(MutationStatus.APPLIED, createOutcome.first.status)
            val offerId = assertNotNull(createOutcome.first.serverEntityId)
            assertTrue(!offerId.startsWith("tmp_"))

            // 2. Requester submits a request proposing D2 in return.
            val offerForRequester =
                bootstrapExchanges(requesterToken).single { it.basketExchangeId.id == offerId }
            val requestSubmit =
                applyMutation(
                    requesterToken,
                    ClientMutation(
                        clientOpId = "submit-request",
                        op =
                            Upsert(
                                BasketExchangePayload(
                                    offerForRequester.copy(
                                        requests =
                                            listOf(
                                                BasketExchangeRequest(
                                                    requestId = "tmp_req".toId(),
                                                    requesterMemberId = requesterId.toId(),
                                                    createdAt = Instant.parse("2025-01-02T00:00:00Z"),
                                                    status = BasketExchangeRequestStatus.PENDING,
                                                    proposedDeliveryId = d2.toId(),
                                                    proposedContractId = c2.toId(),
                                                ),
                                            ),
                                    ),
                                ),
                            ),
                    ),
                )
            assertEquals(MutationStatus.APPLIED, requestSubmit.first.status)

            // 3. Offerer reads the offer (real request id) and validates it.
            val offerWithRequest =
                bootstrapExchanges(offererToken).single { it.basketExchangeId.id == offerId }
            val pendingRequest = offerWithRequest.requests.single()
            assertEquals(BasketExchangeRequestStatus.PENDING, pendingRequest.status)
            assertEquals(d2, pendingRequest.proposedDeliveryId?.id)

            val acceptOutcome =
                applyMutation(
                    offererToken,
                    ClientMutation(
                        clientOpId = "validate-request",
                        op =
                            Upsert(
                                BasketExchangePayload(
                                    offerWithRequest.copy(
                                        status = BasketExchangeStatus.ACCEPTED,
                                        acceptedRequestId = pendingRequest.requestId,
                                    ),
                                ),
                            ),
                    ),
                )
            assertEquals(MutationStatus.APPLIED, acceptOutcome.first.status)

            // 4. Final state: confirmed exchange, accepted request.
            val finalOffer =
                bootstrapExchanges(offererToken).single { it.basketExchangeId.id == offerId }
            assertEquals(BasketExchangeStatus.ACCEPTED, finalOffer.status)
            assertEquals(pendingRequest.requestId, finalOffer.acceptedRequestId)
            assertEquals(
                BasketExchangeRequestStatus.ACCEPTED,
                finalOffer.requests.single().status,
            )

            // Double-booking guard: D1 is now committed, a new offer on D1 is rejected.
            val duplicate =
                applyMutation(
                    offererToken,
                    ClientMutation(
                        clientOpId = "duplicate-offer",
                        op =
                            Upsert(
                                BasketExchangePayload(
                                    BasketExchange(
                                        basketExchangeId = "tmp_be2".toId(),
                                        organizationId = organizationId.toId(),
                                        deliveryId = d1.toId(),
                                        contractId = c1.toId(),
                                        offeringMemberId = offererId.toId(),
                                        status = BasketExchangeStatus.OPEN,
                                        createdAt = Instant.parse("2025-01-03T00:00:00Z"),
                                    ),
                                ),
                            ),
                    ),
                )
            assertEquals(MutationStatus.REJECTED, duplicate.first.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, duplicate.first.error?.code)
        }

    private fun token(
        subject: String,
        role: String,
    ): String =
        mintGoTrueToken(
            subject = subject,
            email = "$subject@example.com",
            roles = listOf(role),
            organizationId = organizationId,
            producerAccountId = null,
        )

    private fun applyMutation(
        token: String,
        mutation: ClientMutation,
    ): Pair<persistence.changes.MutationOutcome, SyncResponse> {
        val request = SyncRequest(cursors = emptyMap(), mutations = listOf(mutation))
        val raw = postRawSyncAs(token, request)
        assertEquals(200, raw.statusCode(), "sync failed: ${raw.body()}")
        val decoded = json.decodeFromString(SyncResponse.serializer(), raw.body())
        val outcome =
            assertNotNull(
                decoded.mutations.firstOrNull { it.clientOpId == mutation.clientOpId },
                "missing outcome for ${mutation.clientOpId}",
            )
        return outcome to decoded
    }

    private fun bootstrapExchanges(token: String): List<BasketExchange> {
        val request = SyncRequest(cursors = mapOf(orgScope to null), mutations = emptyList())
        val raw = postRawSyncAs(token, request)
        assertEquals(200, raw.statusCode(), "bootstrap failed: ${raw.body()}")
        val decoded = json.decodeFromString(SyncResponse.serializer(), raw.body())
        val result = decoded.results[orgScope]
        val items = (result as? BootstrapScopeResult)?.items ?: emptyList()
        return items.filterIsInstance<BasketExchangePayload>().map { it.basketExchange }
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

    private fun seedOrgWithTwoDeliveries(coordinatorToken: String) {
        val ts = Instant.parse("2025-01-01T00:00:00Z")

        fun delivery(
            deliveryId: String,
            contractId: String,
            date: String,
        ) = Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = organizationId.toId(),
            scheduledDate = LocalDateTime.parse(date),
            status = DeliveryStatus.PLANNED,
            minVolunteersRequired = 1,
            contracts =
                listOf(
                    DeliveryContract(
                        contractId = contractId.toId(),
                        basketQuantity = 10,
                        deliveryDescription = "Weekly basket",
                        status = DeliveryContractStatus.PENDING,
                    ),
                ),
        )

        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP des Collines",
                contactEmail = "contact@amap.example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = ts,
                lastUpdatedInstant = ts,
                deliveries =
                    listOf(
                        delivery(d1, c1, "2099-06-15T18:00:00"),
                        delivery(d2, c2, "2099-06-22T18:00:00"),
                    ),
            )

        val request =
            SyncRequest(
                cursors = mapOf(orgScope to null),
                mutations =
                    listOf(
                        ClientMutation(
                            clientOpId = "seed-org",
                            op = Upsert(OrganizationPayload(organization)),
                        ),
                    ),
            )
        val raw = postRawSyncAs(coordinatorToken, request)
        assertEquals(200, raw.statusCode(), "seed failed: ${raw.body()}")
        val decoded = json.decodeFromString(SyncResponse.serializer(), raw.body())
        assertEquals(
            MutationStatus.APPLIED,
            decoded.mutations.single { it.clientOpId == "seed-org" }.status,
        )
    }
}

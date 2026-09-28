package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.GlobalContext
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.EntityPayload
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerSchedulePayload
import persistence.changes.ProductTypePayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketDeliveryDescription
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryItem
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.ItemType
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.Product
import persistence.model.ProductType
import serialization.json
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Basket composition edited by both the coordinator and the producer, over real HTTP + Postgres:
 *
 *  1. An AMAP links the producer (its contract on a future delivery, its catalog with an icon).
 *  2. The producer composes its product through its `ProducerSchedule`.
 *  3. Members get the composition (and the icon) on the organization scope.
 *  4. A coordinator saving the whole organization from a copy that predates the producer's edit
 *     does not erase it.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class ProducerCompositionFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-compo"
    private val coordinatorId = "00000000-0000-0000-0000-000000000007"
    private val deliveryId = "delivery-compo"
    private val orgScope = SyncScope.Organization(organizationId).key
    private val producerScope = SyncScope.ProducerAccount(tenantId).key
    private val epoch = Instant.parse("2025-01-01T00:00:00Z")

    @Test
    fun `the producer composes its basket and a stale coordinator save keeps it`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            insertMemberDirectly(coordinatorId, organizationId, listOf("COORDINATOR"))
            seed()
            val coordinatorToken =
                mintGoTrueToken(
                    subject = coordinatorId,
                    email = "coordo@example.com",
                    roles = listOf("COORDINATOR"),
                    organizationId = organizationId,
                    producerAccountId = null,
                )
            val producerToken = mintGoTrueToken()

            // The coordinator's cached copy, taken before the producer's edit.
            val staleOrganization = bootstrap(coordinatorToken, orgScope).filterIsInstance<OrganizationPayload>().single().organization

            // 2. The producer composes its product through its schedule.
            val schedule = bootstrap(producerToken, producerScope).filterIsInstance<ProducerSchedulePayload>().single().producerSchedule
            val composed =
                schedule.copy(
                    deliveries =
                        schedule.deliveries.map { delivery ->
                            delivery.copy(
                                basketDescriptions =
                                    listOf(
                                        BasketDeliveryDescription(
                                            productTypeId = "pt-cheese".toId(),
                                            basketSizeName = "Petit",
                                            items = listOf(DeliveryItem("it-brie".toId(), name = "Brie", weight = "200 g")),
                                            itemsUpdatedAt = Instant.parse("2025-06-01T10:00:00Z"),
                                        ),
                                    ),
                            )
                        },
                )
            assertEquals(MutationStatus.APPLIED, mutate(producerToken, "compose", ProducerSchedulePayload(composed)))

            // 3. Members read it on the organization scope, icon included.
            val afterProducer = bootstrap(coordinatorToken, orgScope).filterIsInstance<OrganizationPayload>().single().organization
            assertEquals(listOf("Brie"), afterProducer.brieItems())
            assertEquals("<svg/>", afterProducer.itemTypes.single { it.id.id == "it-brie" }.imageSvg)

            // 4. A save from the stale copy (another change) keeps the producer's composition.
            val staleSave =
                staleOrganization.copy(
                    deliveries = staleOrganization.deliveries.map { it.copy(minVolunteersRequired = 3) },
                )
            assertEquals(MutationStatus.APPLIED, mutate(coordinatorToken, "stale-save", OrganizationPayload(staleSave)))
            val finalOrganization = bootstrap(coordinatorToken, orgScope).filterIsInstance<OrganizationPayload>().single().organization
            assertEquals(3, finalOrganization.deliveries.single().minVolunteersRequired)
            assertEquals(listOf("Brie"), finalOrganization.brieItems())
            assertNotNull(finalOrganization.itemTypes.singleOrNull { it.id.id == "it-brie" })
        }

    private fun Organization.brieItems(): List<String> =
        deliveries
            .single()
            .basketDescriptions
            .single { it.productTypeId.id == "pt-cheese" }
            .items
            .map { it.name }

    /** The AMAP, the producer's contract on its delivery and the producer's catalog. */
    private suspend fun seed() {
        val koin = GlobalContext.get()
        koin.get<ProducerAccountSyncDAO>().createStandalone(
            ProducerAccount(
                producerAccountId = tenantId.toId(),
                name = "Ferme Composition",
                activeStatus = true,
                createdInstant = epoch,
                lastUpdatedInstant = epoch,
            ),
            emptyList(),
        )
        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP Composition",
                contactEmail = "amap@example.com",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = epoch,
                lastUpdatedInstant = epoch,
                producers = listOf(OrganizationProducer(tenantId.toId(), epoch, OrganizationProducerStatus.ACTIVE)),
                products = listOf(Product("Fromages", "pt-cheese".toId(), tenantId.toId(), listOf(BasketSize("Petit")))),
                deliveries =
                    listOf(
                        Delivery(
                            deliveryId = deliveryId.toId(),
                            organizationId = organizationId.toId(),
                            scheduledDate = LocalDateTime.parse("2099-06-15T18:00:00"),
                            status = DeliveryStatus.PLANNED,
                            minVolunteersRequired = 1,
                            contracts =
                                listOf(
                                    DeliveryContract(
                                        contractId = "contract-cheese".toId(),
                                        basketQuantity = 10,
                                        deliveryDescription = "",
                                        status = DeliveryContractStatus.PENDING,
                                    ),
                                ),
                            basketDescriptions =
                                listOf(BasketDeliveryDescription(productTypeId = "pt-cheese".toId(), basketSizeName = "Petit")),
                        ),
                    ),
            )
        koin.get<OrganizationSyncDAO>().put(
            organization,
            change(EntityType.Organization, organizationId, orgScope, OrganizationPayload(organization)),
        )
        val contract =
            Contract(
                contractId = "contract-cheese".toId(),
                name = "Fromages 2099",
                organizationId = organizationId.toId(),
                producerAccountId = tenantId.toId(),
                minDeliveryDate = LocalDate.parse("2099-01-01"),
                maxDeliveryDate = LocalDate.parse("2099-12-31"),
                deliveryCount = 10,
                seasonYear = 2099,
            )
        koin.get<ContractSyncDAO>().put(contract, change(EntityType.Contract, "contract-cheese", orgScope, ContractPayload(contract)))
        val productType =
            ProductType(
                productTypeId = "pt-cheese".toId(),
                producerAccountId = tenantId.toId(),
                supportedBasketSizes = listOf(BasketSize("Petit")),
                name = "Fromages",
                itemTypes = listOf(ItemType("it-brie".toId(), "Brie", imageSvg = "<svg/>")),
            )
        koin.get<ProductTypeSyncDAO>().put(
            productType,
            change(EntityType.ProductType, "pt-cheese", producerScope, ProductTypePayload(productType)),
        )
    }

    private fun change(
        entityType: EntityType,
        entityId: String,
        scopeKey: String,
        payload: EntityPayload,
    ) = Change(
        cursor = Cursor.next(),
        entityType = entityType,
        entityId = entityId,
        scopeKey = scopeKey,
        op = ChangeOp.UPSERT,
        payload = payload,
        producedAt = System.currentTimeMillis(),
    )

    private fun mutate(
        token: String,
        clientOpId: String,
        payload: EntityPayload,
    ): MutationStatus {
        val response = post(token, SyncRequest(cursors = emptyMap(), mutations = listOf(ClientMutation(clientOpId, Upsert(payload)))))
        val outcome = response.mutations.single { it.clientOpId == clientOpId }
        assertEquals(null, outcome.error, "mutation $clientOpId rejected")
        return outcome.status
    }

    private fun bootstrap(
        token: String,
        scope: String,
    ): List<EntityPayload> {
        val result = post(token, SyncRequest(cursors = mapOf(scope to null), mutations = emptyList())).results[scope]
        return (result as? BootstrapScopeResult)?.items.orEmpty()
    }

    private fun post(
        token: String,
        request: SyncRequest,
    ): SyncResponse {
        val httpRequest =
            java.net.http.HttpRequest
                .newBuilder()
                .uri(java.net.URI("http://127.0.0.1:$port/v1/sync"))
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .POST(
                    java.net.http.HttpRequest.BodyPublishers
                        .ofString(json.encodeToString(SyncRequest.serializer(), request)),
                ).build()
        val raw =
            httpClient.send(
                httpRequest,
                java.net.http.HttpResponse.BodyHandlers
                    .ofString(),
            )
        assertEquals(200, raw.statusCode(), "sync failed: ${raw.body()}")
        return json.decodeFromString(SyncResponse.serializer(), raw.body())
    }
}

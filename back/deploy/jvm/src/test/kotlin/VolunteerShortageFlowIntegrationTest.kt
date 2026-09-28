package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.GlobalContext
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.EntityPayload
import persistence.changes.NotificationPayload
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncScope
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivityType
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.MemberSlot
import persistence.model.NotificationCategory
import persistence.model.Organization
import persistence.model.SlotStatus
import volunteershortage.VolunteerShortageService
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Volunteer shortage alert over real Postgres + HTTP: a delivery starting in a bit less than
 * 24 hours still lacks volunteers, the scheduled job runs (twice) and the member reads exactly
 * one urgent alert on their private `member:{sub}` feed.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class VolunteerShortageFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-shortage"
    private val memberId = "00000000-0000-0000-0000-000000000042"
    private val orgScope = SyncScope.Organization(organizationId).key
    private val epoch = Instant.parse("2025-01-01T00:00:00Z")

    @Test
    fun `an understaffed delivery tomorrow sends one urgent alert to the member feed`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            insertMemberDirectly(memberId, organizationId, listOf("VOLUNTEER"))
            val now = Clock.System.now()
            seed(deliveryStart = now + 24.hours - 5.minutes)
            val service = GlobalContext.get().get<VolunteerShortageService>()

            service.run(now)
            service.run(now + 1.minutes)

            val token =
                mintGoTrueToken(
                    subject = memberId,
                    email = "member@example.com",
                    roles = listOf("VOLUNTEER"),
                    organizationId = organizationId,
                    producerAccountId = null,
                )
            val memberScope = SyncScope.Member(memberId).key
            val result = postSyncAs(token, SyncRequest(cursors = mapOf(memberScope to null), mutations = emptyList())).results[memberScope]
            val alerts =
                (result as BootstrapScopeResult)
                    .items
                    .filterIsInstance<NotificationPayload>()
                    .map { it.notification }
                    .filter { it.category == NotificationCategory.VOLUNTEER_URGENT_NEED }
            assertEquals(1, alerts.size)
            assertEquals("Besoin urgent de bénévoles", alerts.single().title)
            assertEquals("delivery-shortage", alerts.single().relatedEntityId)
        }

    private suspend fun seed(deliveryStart: Instant) {
        val koin = GlobalContext.get()
        val timezone = TimeZone.of("Europe/Paris")
        val start = deliveryStart.toLocalDateTime(timezone)
        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP Shortage",
                contactEmail = "amap@example.com",
                activeStatus = true,
                timezone = timezone,
                defaultLanguage = "fr",
                createdInstant = epoch,
                lastUpdatedInstant = epoch,
                deliveries =
                    listOf(
                        Delivery(
                            deliveryId = "delivery-shortage".toId(),
                            organizationId = organizationId.toId(),
                            scheduledDate = start,
                            status = DeliveryStatus.CONFIRMED,
                            minVolunteersRequired = 2,
                            contracts =
                                listOf(
                                    DeliveryContract(
                                        contractId = "contract-veg".toId(),
                                        coordinators = listOf("coordinator-1".toId()),
                                        basketQuantity = 10,
                                        deliveryDescription = "",
                                        status = DeliveryContractStatus.PENDING,
                                        slots =
                                            listOf(
                                                MemberSlot(
                                                    slotId = "slot-1",
                                                    startTime = start,
                                                    endTime = (deliveryStart + 2.hours).toLocalDateTime(timezone),
                                                    activityType = ActivityType.DISTRIBUTION,
                                                    requiredVolunteers = 2,
                                                    currentRegistrations = 0,
                                                    status = SlotStatus.OPEN,
                                                ),
                                            ),
                                    ),
                                ),
                        ),
                    ),
            )
        koin.get<OrganizationSyncDAO>().put(
            organization,
            change(EntityType.Organization, organizationId, OrganizationPayload(organization)),
        )
        val contract =
            Contract(
                contractId = "contract-veg".toId(),
                name = "Légumes",
                organizationId = organizationId.toId(),
                producerAccountId = tenantId.toId(),
                minDeliveryDate = LocalDate(2000, 1, 1),
                maxDeliveryDate = LocalDate(2999, 12, 31),
                deliveryCount = 10,
                seasonYear = 2026,
                status = ContractStatus.ACTIVE,
                isMainContract = true,
            )
        koin.get<ContractSyncDAO>().put(contract, change(EntityType.Contract, "contract-veg", ContractPayload(contract)))
    }

    private fun change(
        entityType: EntityType,
        entityId: String,
        payload: EntityPayload,
    ) = Change(
        cursor = Cursor.next(),
        entityType = entityType,
        entityId = entityId,
        scopeKey = orgScope,
        op = ChangeOp.UPSERT,
        payload = payload,
        producedAt = System.currentTimeMillis(),
    )
}

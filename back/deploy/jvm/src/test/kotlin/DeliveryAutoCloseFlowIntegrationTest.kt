package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atTime
import kotlinx.datetime.minus
import kotlinx.datetime.plus
import kotlinx.datetime.todayIn
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.GlobalContext
import organization.DeliveryAutoCloseService
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivityType
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import kotlin.test.assertEquals
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Auto-close of past deliveries over real Postgres + HTTP: the scheduled job closes
 * yesterday's delivery (not tomorrow's), members read it COMPLETED on their next sync, the
 * unrecorded registration is untouched, and the coordinator can still record the presence
 * and the collection afterwards.
 */
@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class DeliveryAutoCloseFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-autoclose"
    private val coordinatorId = "00000000-0000-0000-0000-000000000051"
    private val volunteerId = "00000000-0000-0000-0000-000000000052"
    private val orgScope = SyncScope.Organization(organizationId).key
    private val epoch = Instant.parse("2025-01-01T00:00:00Z")
    private val timezone = TimeZone.of("Europe/Paris")

    @Test
    fun `a past delivery is auto-closed and can still be pointed afterwards`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            insertMemberDirectly(coordinatorId, organizationId, listOf("COORDINATOR"))
            insertMemberDirectly(volunteerId, organizationId, listOf("VOLUNTEER"))
            val today = Clock.System.todayIn(timezone)
            val yesterday = today.minus(1, DateTimeUnit.DAY).atTime(19, 0)
            val tomorrow = today.plus(1, DateTimeUnit.DAY).atTime(19, 0)
            seed(delivery("delivery-past", yesterday), delivery("delivery-next", tomorrow))

            GlobalContext.get().get<DeliveryAutoCloseService>().run(Clock.System.now())

            val coordinatorToken = token(coordinatorId, "COORDINATOR")
            val closed = organization(coordinatorToken)
            val past = closed.deliveries.single { it.deliveryId.id == "delivery-past" }
            assertEquals(DeliveryStatus.COMPLETED, past.status)
            assertEquals(DeliveryStatus.PLANNED, closed.deliveries.single { it.deliveryId.id == "delivery-next" }.status)
            assertEquals(
                RegistrationStatus.REGISTERED,
                past.contracts
                    .single()
                    .slots
                    .single()
                    .registrations
                    .single()
                    .status,
            )

            // The coordinator points the closed delivery after the fact.
            val pointed =
                closed.copy(
                    deliveries =
                        closed.deliveries.map { delivery ->
                            if (delivery.deliveryId.id != "delivery-past") {
                                delivery
                            } else {
                                delivery.copy(
                                    contracts =
                                        delivery.contracts.map { link ->
                                            link.copy(
                                                status = DeliveryContractStatus.DISTRIBUTED,
                                                slots =
                                                    link.slots.map { slot ->
                                                        slot.copy(
                                                            registrations =
                                                                slot.registrations.map {
                                                                    it.copy(status = RegistrationStatus.CONFIRMED)
                                                                },
                                                        )
                                                    },
                                            )
                                        },
                                )
                            }
                        },
                )
            val response =
                postSyncAs(
                    coordinatorToken,
                    SyncRequest(
                        cursors = emptyMap(),
                        mutations = listOf(ClientMutation(clientOpId = "point-after-close", op = Upsert(OrganizationPayload(pointed)))),
                    ),
                )
            assertEquals(MutationStatus.APPLIED, response.mutations.single { it.clientOpId == "point-after-close" }.status)

            val after = organization(coordinatorToken).deliveries.single { it.deliveryId.id == "delivery-past" }
            assertEquals(DeliveryStatus.COMPLETED, after.status)
            assertEquals(DeliveryContractStatus.DISTRIBUTED, after.contracts.single().status)
            assertEquals(
                RegistrationStatus.CONFIRMED,
                after.contracts
                    .single()
                    .slots
                    .single()
                    .registrations
                    .single()
                    .status,
            )
        }

    private fun token(
        subject: String,
        role: String,
    ) = mintGoTrueToken(
        subject = subject,
        email = "$subject@example.com",
        roles = listOf(role),
        organizationId = organizationId,
        producerAccountId = null,
    )

    private fun organization(token: String): Organization =
        (
            postSyncAs(
                token,
                SyncRequest(cursors = mapOf(orgScope to null), mutations = emptyList()),
            ).results[orgScope] as BootstrapScopeResult
        ).items
            .filterIsInstance<OrganizationPayload>()
            .single()
            .organization

    private fun delivery(
        id: String,
        scheduledDate: LocalDateTime,
    ) = Delivery(
        deliveryId = id.toId(),
        organizationId = organizationId.toId(),
        scheduledDate = scheduledDate,
        status = DeliveryStatus.PLANNED,
        minVolunteersRequired = 1,
        contracts =
            listOf(
                DeliveryContract(
                    contractId = "contract-veg".toId(),
                    coordinators = listOf(coordinatorId.toId()),
                    basketQuantity = 10,
                    deliveryDescription = "",
                    status = DeliveryContractStatus.PENDING,
                    slots =
                        listOf(
                            MemberSlot(
                                slotId = "slot-$id",
                                startTime = scheduledDate,
                                endTime = scheduledDate,
                                activityType = ActivityType.DISTRIBUTION,
                                requiredVolunteers = 2,
                                currentRegistrations = 1,
                                status = SlotStatus.OPEN,
                                registrations =
                                    listOf(
                                        MemberRegistration(
                                            memberId = volunteerId.toId(),
                                            displayName = "Volunteer",
                                            memberEmail = "volunteer@example.com",
                                            registrationInstant = epoch,
                                            status = RegistrationStatus.REGISTERED,
                                        ),
                                    ),
                            ),
                        ),
                ),
            ),
    )

    private suspend fun seed(vararg deliveries: Delivery) {
        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP Auto-close",
                contactEmail = "amap@example.com",
                activeStatus = true,
                timezone = timezone,
                defaultLanguage = "fr",
                createdInstant = epoch,
                lastUpdatedInstant = epoch,
                deliveries = deliveries.toList(),
            )
        GlobalContext.get().get<OrganizationSyncDAO>().put(
            organization,
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.Organization,
                entityId = organizationId,
                scopeKey = orgScope,
                op = ChangeOp.UPSERT,
                payload = OrganizationPayload(organization),
                producedAt = System.currentTimeMillis(),
            ),
        )
    }
}

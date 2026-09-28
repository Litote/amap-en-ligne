package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.ProducerSchedulePayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.Contract
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerSchedule
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Instant

internal class ProducerScheduleServiceTest {
    private val epoch = Instant.fromEpochMilliseconds(0)

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "sub-1",
            firstName = "Pierre",
            lastName = "Martin",
            email = "ferme@example.com",
            producerAccountId = "pa-1",
            roles = listOf(Role.PRODUCER),
        )

    private fun organization(
        id: String,
        vararg producers: String,
    ) = Organization(
        organizationId = id.toId(),
        name = "AMAP $id",
        contactEmail = "$id@example.com",
        activeStatus = true,
        timezone = TimeZone.of("Europe/Paris"),
        defaultLanguage = "fr",
        createdInstant = epoch,
        lastUpdatedInstant = epoch,
        producers = producers.map { OrganizationProducer(it.toId(), epoch, OrganizationProducerStatus.ACTIVE) },
        deliveries =
            listOf(
                Delivery(
                    deliveryId = "d-$id".toId(),
                    organizationId = id.toId(),
                    scheduledDate = LocalDateTime.parse("2026-10-01T18:00:00"),
                    status = DeliveryStatus.PLANNED,
                    minVolunteersRequired = 2,
                    contracts =
                        listOf(
                            DeliveryContract(
                                contractId = "c-$id".toId(),
                                basketQuantity = 12,
                                deliveryDescription = "",
                                status = DeliveryContractStatus.PENDING,
                            ),
                        ),
                ),
            ),
    )

    private fun contract(organizationId: String) =
        Contract(
            contractId = "c-$organizationId".toId(),
            name = "Fromages $organizationId",
            organizationId = organizationId.toId(),
            producerAccountId = "pa-1".toId(),
            minDeliveryDate = LocalDate.parse("2026-01-01"),
            maxDeliveryDate = LocalDate.parse("2026-12-31"),
            deliveryCount = 10,
            seasonYear = 2026,
        )

    private val service =
        ProducerScheduleService(
            organizationSyncDAO =
                mockk<OrganizationSyncDAO> {
                    coEvery { listAll() } returns listOf(organization("org-1", "pa-1"), organization("org-2", "pa-other"))
                },
            contractSyncDAO =
                mockk<ContractSyncDAO> {
                    coEvery { getByOrganizationId(any()) } answers { listOf(contract(firstArg<String>())) }
                },
            productTypeDAO = mockk(),
        )

    @Test
    fun `GIVEN a producer linked to one AMAP WHEN bootstrapping its feed THEN one schedule for that AMAP only`() =
        runTest {
            val schedules = service.snapshot(producerAuth, SyncScope.ProducerAccount("pa-1"))

            val schedule = schedules.single().producerSchedule
            assertEquals("org-1", schedule.organizationId.id)
            assertEquals(
                "Fromages org-1",
                schedule.deliveries
                    .single()
                    .contracts
                    .single()
                    .contractName,
            )
        }

    @Test
    fun `GIVEN any other scope WHEN snapshot THEN nothing`() =
        runTest {
            assertTrue(service.snapshot(producerAuth, SyncScope.Organization("org-1")).isEmpty())
            assertTrue(service.snapshot(producerAuth).isEmpty())
        }

    @Test
    fun `GIVEN a delete WHEN applied THEN FORBIDDEN (derived projection)`() =
        runTest {
            val op = Delete(EntityType.ProducerSchedule, "org-1")
            val delete = service.applyDelete(producerAuth, ClientMutation("op-2", op), op)

            assertEquals(MutationStatus.REJECTED, delete.status)
            assertEquals(MutationErrorCode.FORBIDDEN, delete.error?.code)
        }
}

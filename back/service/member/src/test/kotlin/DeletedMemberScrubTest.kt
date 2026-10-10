@file:OptIn(ExperimentalTime::class)

package member

import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.model.ActivityType
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

class DeletedMemberScrubTest {
    private val deleted = "deleted-sub"
    private val today = LocalDate.parse("2026-10-10")

    private fun registration(
        memberId: String,
        status: RegistrationStatus = RegistrationStatus.REGISTERED,
    ) = MemberRegistration(
        memberId = memberId.toId(),
        displayName = "Name $memberId",
        memberEmail = "$memberId@example.org",
        registrationInstant = Instant.fromEpochMilliseconds(1_000L),
        status = status,
    )

    private fun delivery(
        id: String,
        date: String,
        status: DeliveryStatus,
        registrations: List<MemberRegistration>,
        coordinators: List<String> = listOf(deleted, "other-coordinator"),
    ) = Delivery(
        deliveryId = id.toId(),
        organizationId = "org-1".toId(),
        scheduledDate = LocalDateTime.parse("${date}T19:00:00"),
        status = status,
        minVolunteersRequired = 2,
        contracts =
            listOf(
                DeliveryContract(
                    contractId = "contract-1".toId(),
                    coordinators = coordinators.map { it.toId() },
                    basketQuantity = 10,
                    deliveryDescription = "Légumes",
                    status = DeliveryContractStatus.PENDING,
                    slots =
                        listOf(
                            MemberSlot(
                                slotId = "slot-$id",
                                startTime = LocalDateTime.parse("${date}T19:00:00"),
                                endTime = LocalDateTime.parse("${date}T20:30:00"),
                                activityType = ActivityType.RECEPTION,
                                requiredVolunteers = 3,
                                currentRegistrations = registrations.count { it.status != RegistrationStatus.CANCELLED },
                                status = SlotStatus.OPEN,
                                registrations = registrations,
                            ),
                        ),
                ),
            ),
    )

    private fun organization(vararg deliveries: Delivery) =
        Organization(
            organizationId = "org-1".toId(),
            name = "AMAP",
            contactEmail = "amap@example.org",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = Instant.fromEpochMilliseconds(0),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(0),
            deliveries = deliveries.toList(),
        )

    private fun Organization.slotOf(id: String) =
        deliveries
            .single { it.deliveryId.id == id }
            .contracts
            .single()
            .slots
            .single()

    private fun Organization.coordinatorsOf(id: String) =
        deliveries
            .single { it.deliveryId.id == id }
            .contracts
            .single()
            .coordinators
            .map { it.id }

    @Test
    fun `GIVEN a past delivery WHEN the member is deleted THEN their registration loses name and email but stays counted`() {
        val org =
            organization(
                delivery(
                    "past",
                    "2026-09-30",
                    DeliveryStatus.COMPLETED,
                    listOf(registration(deleted, RegistrationStatus.CONFIRMED), registration("neighbour")),
                ),
            )

        val scrubbed = DeletedMemberScrub.scrub(org, deleted.toId(), today)

        val slot = scrubbed.slotOf("past")
        assertEquals(
            listOf(registration(deleted, RegistrationStatus.CONFIRMED).copy(displayName = "", memberEmail = ""), registration("neighbour")),
            slot.registrations,
        )
        assertEquals(2, slot.currentRegistrations)
        // History keeps the (pseudonymous) coordinator id.
        assertEquals(listOf(deleted, "other-coordinator"), scrubbed.coordinatorsOf("past"))
    }

    @Test
    fun `GIVEN an upcoming delivery WHEN the member is deleted THEN their registration and coordinator role are removed`() {
        val org =
            organization(
                delivery("today", "2026-10-10", DeliveryStatus.CONFIRMED, listOf(registration(deleted), registration("neighbour"))),
            )

        val scrubbed = DeletedMemberScrub.scrub(org, deleted.toId(), today)

        val slot = scrubbed.slotOf("today")
        assertEquals(listOf(registration("neighbour")), slot.registrations)
        assertEquals(1, slot.currentRegistrations)
        assertEquals(listOf("other-coordinator"), scrubbed.coordinatorsOf("today"))
    }

    @Test
    fun `GIVEN a cancelled future delivery WHEN the member is deleted THEN it is treated as history`() {
        val org = organization(delivery("cancelled", "2026-11-04", DeliveryStatus.CANCELLED, listOf(registration(deleted))))

        val scrubbed = DeletedMemberScrub.scrub(org, deleted.toId(), today)

        assertEquals(listOf(registration(deleted).copy(displayName = "", memberEmail = "")), scrubbed.slotOf("cancelled").registrations)
        assertEquals(listOf(deleted, "other-coordinator"), scrubbed.coordinatorsOf("cancelled"))
    }

    @Test
    fun `GIVEN an organization the member never touched WHEN scrubbed THEN it is unchanged`() {
        val org =
            organization(
                delivery("past", "2026-09-30", DeliveryStatus.COMPLETED, listOf(registration("neighbour")), coordinators = listOf("c")),
                delivery("next", "2026-10-14", DeliveryStatus.PLANNED, emptyList(), coordinators = listOf("c")),
            )

        assertEquals(org, DeletedMemberScrub.scrub(org, deleted.toId(), today))
    }
}

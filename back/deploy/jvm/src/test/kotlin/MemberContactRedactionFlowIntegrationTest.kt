package deploy.jvm

import authentication.Role
import id.toId
import kotlinx.coroutines.test.runTest
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
import persistence.changes.Cursor
import persistence.changes.EntityPayload
import persistence.changes.MemberPayload
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivityType
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.Instant

/**
 * Members' contact details over real Postgres + HTTP: a plain member bootstraps the
 * organization without the other members' email / phone (a coordinator's phone stays), then
 * registers as a volunteer by writing back the masked organization — the stored emails are
 * kept, and a coordinator still reads every contact detail.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class MemberContactRedactionFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-contacts"
    private val volunteerId = "00000000-0000-0000-0000-000000000061"
    private val neighbourId = "00000000-0000-0000-0000-000000000062"
    private val coordinatorId = "00000000-0000-0000-0000-000000000063"
    private val orgScope = SyncScope.Organization(organizationId).key
    private val epoch = Instant.parse("2025-01-01T00:00:00Z")
    private val deliveryDate = LocalDateTime.parse("2099-01-14T19:00:00")

    @Test
    fun `a plain member gets no contact detail of the others and can still register`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            seed()

            val volunteerToken = token(volunteerId, "VOLUNTEER")
            val served = bootstrap(volunteerToken)
            val neighbour = served.member(neighbourId)
            assertEquals("Nina", neighbour.firstName)
            assertNull(neighbour.email)
            assertNull(neighbour.phone)
            val coordinator = served.member(coordinatorId)
            assertNull(coordinator.email)
            assertEquals("06 33 33 33 33", coordinator.phone)
            assertEquals("volunteer@example.org", served.member(volunteerId).email)
            val organization = served.filterIsInstance<OrganizationPayload>().single().organization
            assertEquals("", organization.registrations().single().memberEmail)

            // Self-registration writes the masked organization back.
            val registered =
                organization.withSlotRegistrations(
                    organization.registrations() +
                        MemberRegistration(
                            memberId = volunteerId.toId(),
                            displayName = "Victor Volunteer",
                            memberEmail = "volunteer@example.org",
                            registrationInstant = epoch,
                            status = RegistrationStatus.REGISTERED,
                        ),
                )
            val response =
                postSyncAs(
                    volunteerToken,
                    SyncRequest(
                        cursors = emptyMap(),
                        mutations = listOf(ClientMutation(clientOpId = "register-self", op = Upsert(OrganizationPayload(registered)))),
                    ),
                )
            assertEquals(MutationStatus.APPLIED, response.mutations.single { it.clientOpId == "register-self" }.status)

            val coordinatorView = bootstrap(token(coordinatorId, "COORDINATOR"))
            assertEquals("nina@example.org", coordinatorView.member(neighbourId).email)
            assertEquals("06 22 22 22 22", coordinatorView.member(neighbourId).phone)
            val stored =
                coordinatorView
                    .filterIsInstance<OrganizationPayload>()
                    .single()
                    .organization
                    .registrations()
                    .associate { it.memberId.id to it.memberEmail }
            assertEquals(mapOf(neighbourId to "nina@example.org", volunteerId to "volunteer@example.org"), stored)
        }

    private fun token(
        subject: String,
        role: String,
    ) = mintGoTrueToken(
        subject = subject,
        email = "$subject@example.org",
        roles = listOf(role),
        organizationId = organizationId,
        producerAccountId = null,
    )

    private fun bootstrap(token: String): List<EntityPayload> =
        (
            postSyncAs(
                token,
                SyncRequest(cursors = mapOf(orgScope to null), mutations = emptyList()),
            ).results[orgScope] as BootstrapScopeResult
        ).items

    private fun List<EntityPayload>.member(id: String) = filterIsInstance<MemberPayload>().single { it.member.memberId.id == id }.member

    private fun Organization.registrations() =
        deliveries
            .single()
            .contracts
            .single()
            .slots
            .single()
            .registrations

    private fun Organization.withSlotRegistrations(registrations: List<MemberRegistration>) =
        copy(
            deliveries =
                deliveries.map { delivery ->
                    delivery.copy(
                        contracts =
                            delivery.contracts.map { link ->
                                link.copy(
                                    slots =
                                        link.slots.map {
                                            it.copy(registrations = registrations, currentRegistrations = registrations.size)
                                        },
                                )
                            },
                    )
                },
        )

    private fun member(
        id: String,
        firstName: String,
        email: String,
        phone: String,
        roles: Set<Role>,
    ) = Member(
        memberId = id.toId(),
        organizationId = organizationId.toId(),
        roles = roles,
        firstName = firstName,
        lastName = "Test",
        email = email,
        phone = phone,
        memberPreferences = MemberPreferences(deliveryRemindersEnabled = true, volunteerAlertsEnabled = true, lastUpdatedInstant = epoch),
        userPreferences = UserPreferences(emailNotificationsEnabled = true, pushNotificationsEnabled = false, lastUpdatedInstant = epoch),
        userSettings =
            UserSettings(
                language = "fr",
                timezone = TimeZone.of("Europe/Paris"),
                serverId = "default".toId(),
                lastUpdatedInstant = epoch,
            ),
    )

    private suspend fun seed() {
        val koin = GlobalContext.get()
        val members =
            listOf(
                member(volunteerId, "Victor", "volunteer@example.org", "06 11 11 11 11", setOf(Role.VOLUNTEER)),
                member(neighbourId, "Nina", "nina@example.org", "06 22 22 22 22", setOf(Role.VOLUNTEER)),
                member(coordinatorId, "Colette", "colette@example.org", "06 33 33 33 33", setOf(Role.VOLUNTEER, Role.COORDINATOR)),
            )
        members.forEach { koin.get<MemberSyncDAO>().put(it, listOf(change(EntityType.Member, it.memberId.id, MemberPayload(it)))) }
        val organization =
            Organization(
                organizationId = organizationId.toId(),
                name = "AMAP Contacts",
                contactEmail = "amap@example.org",
                activeStatus = true,
                timezone = TimeZone.of("Europe/Paris"),
                defaultLanguage = "fr",
                createdInstant = epoch,
                lastUpdatedInstant = epoch,
                deliveries =
                    listOf(
                        Delivery(
                            deliveryId = "delivery-contacts".toId(),
                            organizationId = organizationId.toId(),
                            scheduledDate = deliveryDate,
                            status = DeliveryStatus.PLANNED,
                            minVolunteersRequired = 2,
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
                                                    slotId = "slot-contacts",
                                                    startTime = deliveryDate,
                                                    endTime = deliveryDate,
                                                    activityType = ActivityType.DISTRIBUTION,
                                                    requiredVolunteers = 3,
                                                    currentRegistrations = 1,
                                                    status = SlotStatus.OPEN,
                                                    registrations =
                                                        listOf(
                                                            MemberRegistration(
                                                                memberId = neighbourId.toId(),
                                                                displayName = "Nina Test",
                                                                memberEmail = "nina@example.org",
                                                                registrationInstant = epoch,
                                                                status = RegistrationStatus.REGISTERED,
                                                            ),
                                                        ),
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

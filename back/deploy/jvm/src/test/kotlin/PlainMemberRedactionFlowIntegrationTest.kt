package deploy.jvm

import authentication.Role
import core.PlainMemberRedaction
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
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberPayload
import persistence.changes.MutationStatus
import persistence.changes.OrganizationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.ActivityType
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberContractStatus
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

/**
 * The plain-member view over real Postgres + HTTP: a plain member bootstraps the organization
 * without the other members' email / phone (a coordinator's phone stays), with the others'
 * past registrations anonymous and the anonymous participation counts, then registers as a
 * volunteer by writing back the masked organization — nothing stored is lost, and a
 * coordinator still reads everything.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class PlainMemberRedactionFlowIntegrationTest : JvmSyncTestSupport() {
    private val organizationId = "org-contacts"
    private val volunteerId = "00000000-0000-0000-0000-000000000061"
    private val neighbourId = "00000000-0000-0000-0000-000000000062"
    private val coordinatorId = "00000000-0000-0000-0000-000000000063"
    private val orgScope = SyncScope.Organization(organizationId).key
    private val epoch = Instant.parse("2025-01-01T00:00:00Z")
    private val deliveryDate = LocalDateTime.parse("2099-01-14T19:00:00")
    private val pastDate = LocalDateTime.parse("2026-01-07T19:00:00")

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
            // Past attendance is anonymous, and the ranking comes from anonymous counts.
            val past = organization.registrations("delivery-past").single()
            assertEquals(PlainMemberRedaction.ANONYMOUS_MEMBER_ID, past.memberId.id)
            assertEquals("", past.displayName)
            assertEquals(mapOf(2026 to listOf(1, 0, 0)), organization.participationCountsBySeason)
            assertEquals(
                listOf(volunteerId),
                served
                    .filterIsInstance<ContractPayload>()
                    .single()
                    .contract.members
                    .map { it.memberId.id },
            )

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
            val storedPast =
                coordinatorView
                    .filterIsInstance<OrganizationPayload>()
                    .single()
                    .organization
                    .registrations("delivery-past")
            assertEquals(listOf(neighbourId), storedPast.map { it.memberId.id })
        }

    @Test
    fun `a cache synced before the masking is bootstrapped masked once, then diffed`() =
        runTest {
            resetDb()
            insertOrganizationDirectly(organizationId)
            seed()
            val volunteerToken = token(volunteerId, "VOLUNTEER")
            // A cursor issued with the full view (older server, or while coordinator).
            val fullViewCursor =
                (
                    postSyncAs(token(coordinatorId, "COORDINATOR"), SyncRequest(cursors = mapOf(orgScope to null), mutations = emptyList()))
                        .results[orgScope] as BootstrapScopeResult
                ).nextCursor

            val first =
                postSyncAs(
                    volunteerToken,
                    SyncRequest(cursors = mapOf(orgScope to fullViewCursor), mutations = emptyList()),
                ).results[orgScope]
            val rebootstrap = assertIs<BootstrapScopeResult>(first)
            assertNull(rebootstrap.items.member(neighbourId).email)
            assertTrue(rebootstrap.nextCursor.startsWith(PlainMemberRedaction.CURSOR_MARK))

            val second =
                postSyncAs(volunteerToken, SyncRequest(cursors = mapOf(orgScope to rebootstrap.nextCursor), mutations = emptyList()))
                    .results[orgScope]
            assertTrue(assertIs<IncrementalScopeResult>(second).changes.isEmpty())
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

    private fun Organization.registrations(deliveryId: String = "delivery-contacts") =
        deliveries
            .single { it.deliveryId.id == deliveryId }
            .contracts
            .single()
            .slots
            .single()
            .registrations

    private fun Organization.withSlotRegistrations(registrations: List<MemberRegistration>) =
        copy(
            deliveries =
                deliveries.map { delivery ->
                    if (delivery.deliveryId.id != "delivery-contacts") return@map delivery
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
        val pastDelivery =
            organization.deliveries.single().let { next ->
                next.copy(
                    deliveryId = "delivery-past".toId(),
                    scheduledDate = pastDate,
                    contracts =
                        next.contracts.map { link ->
                            link.copy(
                                slots =
                                    link.slots.map { slot ->
                                        slot.copy(
                                            slotId = "slot-past",
                                            startTime = pastDate,
                                            endTime = pastDate,
                                            registrations = slot.registrations.map { it.copy(status = RegistrationStatus.CONFIRMED) },
                                        )
                                    },
                            )
                        },
                )
            }
        koin.get<OrganizationSyncDAO>().put(
            organization.copy(deliveries = listOf(pastDelivery) + organization.deliveries),
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
                members =
                    listOf(volunteerId, neighbourId).map {
                        ContractMember(memberId = it.toId(), subscriptionInstant = epoch, status = MemberContractStatus.ACTIVE)
                    },
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

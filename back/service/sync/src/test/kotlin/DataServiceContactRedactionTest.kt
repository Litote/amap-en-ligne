package sync

import authentication.AuthenticatedInfo
import authentication.Role
import core.AuthorizedScopeResolver
import core.EntityTypeService
import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import notification.DeviceTokenService
import notification.NotificationService
import org.junit.jupiter.api.Test
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.EntityPayload
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberPayload
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.changes.SyncScope
import persistence.dao.ChangeDAO
import persistence.dao.MemberSyncDAO
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
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.time.Instant

/**
 * A plain member (VOLUNTEER only) never receives the other members' contact details on the
 * organization scope: neither in their `Member` rows nor in the volunteer registrations of
 * the `Organization`. Coordinators, admins and owners keep everything.
 */
internal class DataServiceContactRedactionTest {
    private val organizationId = "org-contacts"
    private val scope = SyncScope.Organization(organizationId)
    private val epoch = Instant.fromEpochMilliseconds(0)
    private val callerId = "caller"

    private fun member(
        id: String,
        roles: Set<Role>,
    ) = Member(
        memberId = id.toId(),
        organizationId = organizationId.toId(),
        roles = roles,
        firstName = "First-$id",
        lastName = "Last-$id",
        email = "$id@example.org",
        phone = "06 00 00 00 ${id.length}0",
        memberPreferences =
            MemberPreferences(
                deliveryRemindersEnabled = true,
                volunteerAlertsEnabled = true,
                lastUpdatedInstant = Instant.fromEpochMilliseconds(5),
                planningChangesAlertsEnabled = false,
            ),
        userPreferences =
            UserPreferences(
                emailNotificationsEnabled = true,
                pushNotificationsEnabled = true,
                lastUpdatedInstant = Instant.fromEpochMilliseconds(5),
            ),
        userSettings =
            UserSettings(
                language = "fr",
                timezone = TimeZone.of("Europe/Paris"),
                serverId = "server-1".toId(),
                lastUpdatedInstant = epoch,
            ),
        registeredAt = Instant.fromEpochMilliseconds(7),
    )

    private val me = member(callerId, setOf(Role.VOLUNTEER))
    private val coordinator = member("coord", setOf(Role.VOLUNTEER, Role.COORDINATOR))
    private val neighbour = member("neighbour", setOf(Role.VOLUNTEER))

    private fun registration(memberId: String) =
        MemberRegistration(
            memberId = memberId.toId(),
            displayName = "Name $memberId",
            memberEmail = "$memberId@example.org",
            registrationInstant = epoch,
            status = RegistrationStatus.REGISTERED,
        )

    private val organization =
        Organization(
            organizationId = organizationId.toId(),
            name = "AMAP",
            contactEmail = "amap@example.org",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = epoch,
            lastUpdatedInstant = epoch,
            deliveries =
                listOf(
                    Delivery(
                        deliveryId = "d-1".toId(),
                        organizationId = organizationId.toId(),
                        scheduledDate = LocalDateTime.parse("2026-10-14T19:00:00"),
                        status = DeliveryStatus.PLANNED,
                        minVolunteersRequired = 2,
                        contracts =
                            listOf(
                                DeliveryContract(
                                    contractId = "c-1".toId(),
                                    coordinators = listOf("coord".toId()),
                                    basketQuantity = 10,
                                    deliveryDescription = "",
                                    status = DeliveryContractStatus.PENDING,
                                    slots =
                                        listOf(
                                            MemberSlot(
                                                slotId = "s-1",
                                                startTime = LocalDateTime.parse("2026-10-14T19:00:00"),
                                                endTime = LocalDateTime.parse("2026-10-14T20:30:00"),
                                                activityType = ActivityType.RECEPTION,
                                                requiredVolunteers = 5,
                                                currentRegistrations = 2,
                                                status = SlotStatus.OPEN,
                                                registrations = listOf(registration(callerId), registration("neighbour")),
                                            ),
                                        ),
                                ),
                            ),
                    ),
                ),
        )

    private fun auth(vararg roles: Role) =
        AuthenticatedInfo(
            memberId = callerId,
            firstName = "C",
            lastName = "Aller",
            email = "$callerId@example.org",
            organizationId = organizationId,
            roles = roles.toList(),
        )

    private fun scopeResolver(): AuthorizedScopeResolver {
        val dao = mockk<MemberSyncDAO>(relaxed = true)
        coEvery { dao.findOrganizationIdBySub(callerId) } returns organizationId.toId()
        return AuthorizedScopeResolver(dao, mockk(relaxed = true))
    }

    private fun dataService(changeDAO: ChangeDAO = mockk(relaxed = true)) =
        DataService(
            services =
                scope.entityTypes.map { type ->
                    FixedItemsService(
                        type,
                        when (type) {
                            EntityType.Member -> listOf(me, coordinator, neighbour).map { MemberPayload(it) }
                            EntityType.Organization -> listOf(OrganizationPayload(organization))
                            else -> emptyList()
                        },
                    )
                } +
                    listOf(
                        NotificationService(notificationSyncDAO = mockk(relaxed = true), authorizedScopeResolver = scopeResolver()),
                        DeviceTokenService(deviceTokenSyncDAO = mockk(relaxed = true), authorizedScopeResolver = scopeResolver()),
                    ),
            changeDAO = changeDAO,
            appliedClientOpDAO = mockk(relaxed = true),
            memberSyncDAO = mockk(relaxed = true),
            authorizedScopeResolver = scopeResolver(),
        )

    private fun bootstrap(auth: AuthenticatedInfo): List<EntityPayload> =
        kotlinx.coroutines.runBlocking {
            assertIs<BootstrapScopeResult>(dataService().sync(auth, mapOf(scope.key to null)).results.getValue(scope.key)).items
        }

    private fun List<EntityPayload>.member(id: String) = filterIsInstance<MemberPayload>().single { it.member.memberId.id == id }.member

    private fun List<EntityPayload>.registrations() =
        filterIsInstance<OrganizationPayload>()
            .single()
            .organization.deliveries
            .single()
            .contracts
            .single()
            .slots
            .single()
            .registrations

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN the other members are served without contact details`() =
        runTest {
            val items = bootstrap(auth(Role.VOLUNTEER))

            val other = items.member("neighbour")
            assertEquals("First-neighbour", other.firstName)
            assertEquals("Last-neighbour", other.lastName)
            assertNull(other.email)
            assertNull(other.phone)
            assertNull(other.registeredAt)
            assertEquals(false, other.memberPreferences.deliveryRemindersEnabled)
            assertEquals(false, other.userPreferences.emailNotificationsEnabled)
            // A coordinator stays reachable by phone (delivery cards), never by email.
            val coord = items.member("coord")
            assertEquals(coordinator.phone, coord.phone)
            assertNull(coord.email)
            // The caller's own row is complete.
            assertEquals(me, items.member(callerId))
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN only their own registration keeps its email`() =
        runTest {
            val registrations = bootstrap(auth(Role.VOLUNTEER)).registrations()

            assertEquals("$callerId@example.org", registrations.single { it.memberId.id == callerId }.memberEmail)
            val other = registrations.single { it.memberId.id == "neighbour" }
            assertEquals("", other.memberEmail)
            assertEquals("Name neighbour", other.displayName)
        }

    @Test
    fun `GIVEN a coordinator WHEN bootstrapping THEN every contact detail is served`() =
        runTest {
            val items = bootstrap(auth(Role.VOLUNTEER, Role.COORDINATOR))

            assertEquals(neighbour, items.member("neighbour"))
            assertEquals("neighbour@example.org", items.registrations().single { it.memberId.id == "neighbour" }.memberEmail)
        }

    @Test
    fun `GIVEN a plain member WHEN syncing incrementally THEN member and organization changes are redacted too`() =
        runTest {
            val changeDAO = mockk<ChangeDAO>()
            val memberChange =
                Change(
                    cursor = "c2",
                    entityType = EntityType.Member,
                    entityId = "neighbour",
                    scopeKey = scope.key,
                    op = ChangeOp.UPSERT,
                    payload = MemberPayload(neighbour),
                    producedAt = 1,
                )
            val organizationChange =
                memberChange.copy(
                    cursor = "c3",
                    entityType = EntityType.Organization,
                    entityId = organizationId,
                    payload = OrganizationPayload(organization),
                )
            val tombstone = memberChange.copy(cursor = "c4", op = ChangeOp.DELETE, payload = null)
            coEvery { changeDAO.countSince(scope.key, "c1", any()) } returns 3
            coEvery { changeDAO.since(scope.key, "c1") } returns listOf(memberChange, organizationChange, tombstone)

            val result =
                assertIs<IncrementalScopeResult>(
                    dataService(changeDAO).sync(auth(Role.VOLUNTEER), mapOf(scope.key to "c1")).results.getValue(scope.key),
                )

            assertEquals(3, result.changes.size)
            assertNull(assertIs<MemberPayload>(result.changes[0].payload).member.email)
            assertEquals(
                "",
                assertIs<OrganizationPayload>(result.changes[1].payload)
                    .organization.deliveries
                    .single()
                    .contracts
                    .single()
                    .slots
                    .single()
                    .registrations
                    .single { it.memberId.id == "neighbour" }
                    .memberEmail,
            )
            assertNull(result.changes[2].payload)
            assertEquals("c4", result.nextCursor)
        }
}

private class FixedItemsService(
    type: EntityType,
    private val items: List<EntityPayload>,
) : EntityTypeService<EntityPayload>(type) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: EntityPayload,
    ): MutationOutcome = error("unused")

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = error("unused")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<EntityPayload> = items
}

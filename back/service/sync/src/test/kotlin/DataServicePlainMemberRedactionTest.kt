package sync

import authentication.AuthenticatedInfo
import authentication.Role
import core.AuthorizedScopeResolver
import core.EntityTypeService
import core.PlainMemberRedaction
import id.toId
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atTime
import kotlinx.datetime.minus
import kotlinx.datetime.plus
import kotlinx.datetime.todayIn
import notification.DeviceTokenService
import notification.NotificationService
import org.junit.jupiter.api.Test
import persistence.changes.BasketExchangePayload
import persistence.changes.BootstrapScopeResult
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.Delete
import persistence.changes.EntityPayload
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberPayload
import persistence.changes.MutationOutcome
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.dao.ChangeDAO
import persistence.dao.MemberSyncDAO
import persistence.model.ActivityType
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberContractStatus
import persistence.model.MemberPreferences
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant

/**
 * A plain member (VOLUNTEER only) only receives on the organization scope what their screens
 * need about the others ([PlainMemberRedaction]): no contact details, no subscriptions, no
 * cancellations / absences, anonymous past registrations, no preparation notes — plus the
 * anonymous participation counts for the ranking. Coordinators, admins and owners keep
 * everything.
 */
internal class DataServicePlainMemberRedactionTest {
    private val organizationId = "org-contacts"
    private val scope = SyncScope.Organization(organizationId)
    private val epoch = Instant.fromEpochMilliseconds(0)
    private val callerId = "caller"
    private val timezone = TimeZone.of("Europe/Paris")
    private val today = Clock.System.todayIn(timezone)

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
                timezone = timezone,
                serverId = "server-1".toId(),
                lastUpdatedInstant = epoch,
            ),
        registeredAt = Instant.fromEpochMilliseconds(7),
    )

    private val me = member(callerId, setOf(Role.VOLUNTEER))
    private val coordinator = member("coord", setOf(Role.VOLUNTEER, Role.COORDINATOR))
    private val neighbour = member("neighbour", setOf(Role.VOLUNTEER))
    private val absentee = member("absentee", setOf(Role.VOLUNTEER))
    private val suspended = member("suspended", setOf(Role.VOLUNTEER)).copy(accountStatus = MemberAccountStatus.SUSPENDED)

    private val producer =
        ProducerAccount(
            producerAccountId = "pa-1".toId(),
            name = "Ferme du Pré",
            contactEmail = "ferme@example.org",
            address = "1 chemin du Pré",
            website = "https://ferme.example.org",
            activeStatus = true,
            createdInstant = epoch,
            lastUpdatedInstant = epoch,
            managementMode = ProducerManagementMode.NO_ACCOUNT,
        )

    private fun exchange(
        id: String,
        offerer: String,
        status: BasketExchangeStatus,
        requester: String? = null,
    ) = BasketExchange(
        basketExchangeId = id.toId(),
        organizationId = organizationId.toId(),
        deliveryId = "next".toId(),
        contractId = "c-1".toId(),
        offeringMemberId = offerer.toId(),
        status = status,
        createdAt = epoch,
        requests =
            listOfNotNull(
                requester?.let {
                    BasketExchangeRequest(
                        requestId = "r-$id".toId(),
                        requesterMemberId = it.toId(),
                        createdAt = epoch,
                        status = BasketExchangeRequestStatus.PENDING,
                    )
                },
            ),
    )

    private val openOfferOfOthers = exchange("open-other", "neighbour", BasketExchangeStatus.OPEN)
    private val dealBetweenOthers = exchange("deal-others", "neighbour", BasketExchangeStatus.ACCEPTED, requester = "coord")
    private val myDeal = exchange("deal-mine", "neighbour", BasketExchangeStatus.ACCEPTED, requester = callerId)

    private fun registration(
        memberId: String,
        status: RegistrationStatus = RegistrationStatus.REGISTERED,
    ) = MemberRegistration(
        memberId = memberId.toId(),
        displayName = "Name $memberId",
        memberEmail = "$memberId@example.org",
        registrationInstant = Instant.fromEpochMilliseconds(42),
        status = status,
    )

    private fun delivery(
        id: String,
        day: LocalDate,
        registrations: List<MemberRegistration>,
    ) = Delivery(
        deliveryId = id.toId(),
        organizationId = organizationId.toId(),
        scheduledDate = day.atTime(19, 0),
        status = DeliveryStatus.PLANNED,
        minVolunteersRequired = 2,
        contracts =
            listOf(
                DeliveryContract(
                    contractId = "c-1".toId(),
                    coordinators = listOf("coord".toId()),
                    basketQuantity = 10,
                    deliveryDescription = "",
                    preparationNotes = "Clé chez la gardienne",
                    status = DeliveryContractStatus.PENDING,
                    slots =
                        listOf(
                            MemberSlot(
                                slotId = "s-$id",
                                startTime = day.atTime(19, 0),
                                endTime = day.atTime(20, 30),
                                activityType = ActivityType.RECEPTION,
                                requiredVolunteers = 5,
                                currentRegistrations = registrations.size,
                                status = SlotStatus.OPEN,
                                registrations = registrations,
                            ),
                        ),
                ),
            ),
    )

    private val organization =
        Organization(
            organizationId = organizationId.toId(),
            name = "AMAP",
            contactEmail = "amap@example.org",
            activeStatus = true,
            timezone = timezone,
            defaultLanguage = "fr",
            createdInstant = epoch,
            lastUpdatedInstant = epoch,
            deliveries =
                listOf(
                    delivery(
                        "past",
                        today.minus(7, DateTimeUnit.DAY),
                        listOf(
                            registration(callerId, RegistrationStatus.CONFIRMED),
                            registration("neighbour", RegistrationStatus.CONFIRMED),
                            registration("absentee", RegistrationStatus.CANCELLED),
                            registration("coord", RegistrationStatus.CONFIRMED),
                        ),
                    ),
                    delivery(
                        "next",
                        today.plus(7, DateTimeUnit.DAY),
                        listOf(
                            registration(callerId),
                            registration("neighbour"),
                            registration("absentee", RegistrationStatus.CANCELLED),
                        ),
                    ),
                ),
        )

    private val contract =
        Contract(
            contractId = "c-1".toId(),
            name = "Légumes",
            organizationId = organizationId.toId(),
            producerAccountId = "pa-1".toId(),
            minDeliveryDate = LocalDate(2000, 1, 1),
            maxDeliveryDate = LocalDate(2999, 12, 31),
            deliveryCount = 30,
            seasonYear = 2026,
            status = ContractStatus.ACTIVE,
            members =
                listOf(callerId, "neighbour").map {
                    ContractMember(memberId = it.toId(), subscriptionInstant = epoch, status = MemberContractStatus.ACTIVE)
                },
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
                            EntityType.Member -> {
                                listOf(me, coordinator, neighbour, absentee, suspended).map { MemberPayload(it) }
                            }

                            EntityType.Organization -> {
                                listOf(OrganizationPayload(organization))
                            }

                            EntityType.Contract -> {
                                listOf(ContractPayload(contract))
                            }

                            EntityType.ProducerAccount -> {
                                listOf(ProducerAccountPayload(producer))
                            }

                            EntityType.BasketExchange -> {
                                listOf(
                                    openOfferOfOthers,
                                    dealBetweenOthers,
                                    myDeal,
                                ).map { BasketExchangePayload(it) }
                            }

                            else -> {
                                emptyList()
                            }
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
        runBlocking {
            assertIs<BootstrapScopeResult>(dataService().sync(auth, mapOf(scope.key to null)).results.getValue(scope.key)).items
        }

    private fun List<EntityPayload>.member(id: String) = filterIsInstance<MemberPayload>().single { it.member.memberId.id == id }.member

    private fun List<EntityPayload>.organization() = filterIsInstance<OrganizationPayload>().single().organization

    private fun Organization.registrationsOf(deliveryId: String) =
        deliveries
            .single { it.deliveryId.id == deliveryId }
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
    fun `GIVEN a plain member WHEN bootstrapping THEN upcoming registrations of the others keep their name only`() =
        runTest {
            val registrations = bootstrap(auth(Role.VOLUNTEER)).organization().registrationsOf("next")

            assertEquals(registration(callerId), registrations.single { it.memberId.id == callerId })
            val other = registrations.single { it.memberId.id == "neighbour" }
            assertEquals("Name neighbour", other.displayName)
            assertEquals("", other.memberEmail)
            assertEquals(epoch, other.registrationInstant)
            // An unregistration (or an absence) of another member is not served.
            assertTrue(registrations.none { it.memberId.id == "absentee" })
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN past registrations of the others are anonymous`() =
        runTest {
            val registrations = bootstrap(auth(Role.VOLUNTEER)).organization().registrationsOf("past")

            assertEquals(registration(callerId, RegistrationStatus.CONFIRMED), registrations.single { it.memberId.id == callerId })
            // The link's coordinator keeps a public identity, without email.
            assertEquals("Name coord", registrations.single { it.memberId.id == "coord" }.displayName)
            val anonymous = registrations.filter { it.memberId.id == PlainMemberRedaction.ANONYMOUS_MEMBER_ID }
            assertEquals(1, anonymous.size, "the absentee is dropped, the neighbour anonymised")
            assertEquals("", anonymous.single().displayName)
            assertEquals(RegistrationStatus.CONFIRMED, anonymous.single().status)
            assertTrue(registrations.none { it.memberId.id == "neighbour" || it.memberId.id == "absentee" })
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN preparation notes and the others' subscriptions are dropped`() =
        runTest {
            val items = bootstrap(auth(Role.VOLUNTEER))

            assertTrue(
                items
                    .organization()
                    .deliveries
                    .flatMap { it.contracts }
                    .all { it.preparationNotes == null },
            )
            val served = items.filterIsInstance<ContractPayload>().single().contract
            assertEquals(listOf(callerId), served.members.map { it.memberId.id })
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN the anonymous participation counts are served for the ranking`() =
        runTest {
            val organization = bootstrap(auth(Role.VOLUNTEER)).organization()

            // Season 2026: caller, neighbour and coordinator present once, absentee never.
            assertEquals(mapOf(2026 to listOf(1, 1, 1, 0)), organization.participationCountsBySeason)
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN suspended members are left out and settings neutralised`() =
        runTest {
            val items = bootstrap(auth(Role.VOLUNTEER))

            assertTrue(items.filterIsInstance<MemberPayload>().none { it.member.memberId.id == "suspended" })
            val settings = items.member("neighbour").userSettings
            assertEquals("", settings.language)
            assertEquals(TimeZone.UTC, settings.timezone)
            assertEquals("", settings.serverId.id)
            // The caller's own settings stay.
            assertEquals(me.userSettings, items.member(callerId).userSettings)
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN producers are served without their contact details`() =
        runTest {
            val served = bootstrap(auth(Role.VOLUNTEER)).filterIsInstance<ProducerAccountPayload>().single().producerAccount

            assertEquals("Ferme du Pré", served.name)
            assertNull(served.contactEmail)
            assertNull(served.address)
            assertNull(served.website)
            assertEquals(ProducerManagementMode.NO_ACCOUNT, served.managementMode)
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN only open offers and their own exchanges are served`() =
        runTest {
            val served =
                bootstrap(
                    auth(Role.VOLUNTEER),
                ).filterIsInstance<BasketExchangePayload>().map { it.basketExchange.basketExchangeId.id }

            assertEquals(listOf("open-other", "deal-mine"), served)
        }

    @Test
    fun `GIVEN a plain member WHEN a deal between others or a suspension changes THEN a tombstone is served instead`() =
        runTest {
            val changeDAO = mockk<ChangeDAO>()
            val dealChange =
                Change(
                    cursor = "c2",
                    entityType = EntityType.BasketExchange,
                    entityId = "deal-others",
                    scopeKey = scope.key,
                    op = ChangeOp.UPSERT,
                    payload = BasketExchangePayload(dealBetweenOthers),
                    producedAt = 1,
                )
            val suspensionChange =
                dealChange.copy(
                    cursor = "c3",
                    entityType = EntityType.Member,
                    entityId = "suspended",
                    payload = MemberPayload(suspended),
                )
            coEvery { changeDAO.countSince(scope.key, "c1", any()) } returns 2
            coEvery { changeDAO.since(scope.key, "c1") } returns listOf(dealChange, suspensionChange)

            val result =
                assertIs<IncrementalScopeResult>(
                    dataService(changeDAO).sync(auth(Role.VOLUNTEER), mapOf(scope.key to "pm.c1")).results.getValue(scope.key),
                )

            // The offer the member saw open, and the suspended member, leave their cache.
            assertEquals(listOf(ChangeOp.DELETE, ChangeOp.DELETE), result.changes.map { it.op })
            assertEquals(listOf("deal-others", "suspended"), result.changes.map { it.entityId })
            assertTrue(result.changes.all { it.payload == null })
        }

    @Test
    fun `GIVEN a coordinator WHEN bootstrapping THEN everything is served as stored`() =
        runTest {
            val items = bootstrap(auth(Role.VOLUNTEER, Role.COORDINATOR))

            assertEquals(neighbour, items.member("neighbour"))
            assertEquals(organization, items.organization())
            assertEquals(contract, items.filterIsInstance<ContractPayload>().single().contract)
            assertEquals(producer, items.filterIsInstance<ProducerAccountPayload>().single().producerAccount)
            assertEquals(3, items.filterIsInstance<BasketExchangePayload>().size)
            assertEquals(suspended, items.member("suspended"))
        }

    @Test
    fun `GIVEN a plain member WHEN syncing incrementally THEN member, organization and contract changes are redacted too`() =
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
            val contractChange =
                memberChange.copy(
                    cursor = "c4",
                    entityType = EntityType.Contract,
                    entityId = "c-1",
                    payload = ContractPayload(contract),
                )
            val tombstone = memberChange.copy(cursor = "c5", op = ChangeOp.DELETE, payload = null)
            coEvery { changeDAO.countSince(scope.key, "c1", any()) } returns 4
            coEvery { changeDAO.since(scope.key, "c1") } returns listOf(memberChange, organizationChange, contractChange, tombstone)

            val result =
                assertIs<IncrementalScopeResult>(
                    dataService(changeDAO).sync(auth(Role.VOLUNTEER), mapOf(scope.key to "pm.c1")).results.getValue(scope.key),
                )

            assertEquals(4, result.changes.size)
            assertNull(assertIs<MemberPayload>(result.changes[0].payload).member.email)
            val servedOrganization = assertIs<OrganizationPayload>(result.changes[1].payload).organization
            assertTrue(servedOrganization.registrationsOf("past").none { it.memberId.id == "neighbour" })
            assertEquals(mapOf(2026 to listOf(1, 1, 1, 0)), servedOrganization.participationCountsBySeason)
            assertEquals(listOf(callerId), assertIs<ContractPayload>(result.changes[2].payload).contract.members.map { it.memberId.id })
            assertNull(result.changes[3].payload)
            // The diff reads the change log from the unmarked cursor and stays in the masked view.
            assertEquals("pm.c5", result.nextCursor)
        }

    @Test
    fun `GIVEN a plain member WHEN bootstrapping THEN the next cursor is marked with the masked view`() =
        runTest {
            val result =
                assertIs<BootstrapScopeResult>(
                    dataService().sync(auth(Role.VOLUNTEER), mapOf(scope.key to null)).results.getValue(scope.key),
                )

            assertTrue(result.nextCursor.startsWith(PlainMemberRedaction.CURSOR_MARK))
        }

    @Test
    fun `GIVEN a plain member WHEN syncing with a cursor issued before the masking THEN the scope is bootstrapped masked once`() =
        runTest {
            // A cache synced with the full view (older server, or the member was a coordinator).
            val changeDAO = mockk<ChangeDAO>(relaxed = true)

            val result =
                assertIs<BootstrapScopeResult>(
                    dataService(changeDAO).sync(auth(Role.VOLUNTEER), mapOf(scope.key to "c1")).results.getValue(scope.key),
                )

            assertNull(
                result.items
                    .filterIsInstance<MemberPayload>()
                    .single { it.member.memberId.id == "neighbour" }
                    .member.email,
            )
            assertTrue(result.nextCursor.startsWith(PlainMemberRedaction.CURSOR_MARK))
        }

    @Test
    fun `GIVEN a coordinator WHEN syncing with a masked-view cursor THEN the scope is bootstrapped in full once`() =
        runTest {
            // A plain member promoted coordinator: their cache holds the masked view.
            val result =
                assertIs<BootstrapScopeResult>(
                    dataService().sync(auth(Role.VOLUNTEER, Role.COORDINATOR), mapOf(scope.key to "pm.c1")).results.getValue(scope.key),
                )

            assertEquals(
                neighbour,
                result.items
                    .filterIsInstance<MemberPayload>()
                    .single { it.member.memberId.id == "neighbour" }
                    .member,
            )
            assertFalse(result.nextCursor.startsWith(PlainMemberRedaction.CURSOR_MARK))
        }

    @Test
    fun `GIVEN a coordinator WHEN syncing with a full-view cursor THEN the diff is served as before`() =
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
            coEvery { changeDAO.countSince(scope.key, "c1", any()) } returns 1
            coEvery { changeDAO.since(scope.key, "c1") } returns listOf(memberChange)

            val result =
                assertIs<IncrementalScopeResult>(
                    dataService(
                        changeDAO,
                    ).sync(auth(Role.VOLUNTEER, Role.COORDINATOR), mapOf(scope.key to "c1")).results.getValue(scope.key),
                )

            assertEquals(listOf(memberChange), result.changes)
            assertEquals("c2", result.nextCursor)
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

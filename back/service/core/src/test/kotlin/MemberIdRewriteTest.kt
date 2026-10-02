package core

import id.Id
import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.model.ActivityType
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.Exchange
import persistence.model.ExchangeStatus
import persistence.model.Member
import persistence.model.MemberContractStatus
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.RegistrationStatus
import persistence.model.SharedBasket
import persistence.model.SlotStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame
import kotlin.time.Instant

internal class MemberIdRewriteTest {
    private val epoch = Instant.fromEpochMilliseconds(0)
    private val old: Id<Member> = "imported-1".toId()
    private val new: Id<Member> = "sub-1".toId()
    private val other: Id<Member> = "other".toId()

    private fun registration(memberId: Id<Member>) =
        MemberRegistration(
            memberId = memberId,
            displayName = "X",
            memberEmail = "x@example.com",
            registrationInstant = epoch,
            status = RegistrationStatus.CONFIRMED,
        )

    private fun organization(memberIds: List<Id<Member>>) =
        Organization(
            organizationId = "org-1".toId(),
            name = "AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = epoch,
            lastUpdatedInstant = epoch,
            deliveries =
                listOf(
                    Delivery(
                        deliveryId = "delivery-1".toId(),
                        organizationId = "org-1".toId(),
                        scheduledDate = LocalDateTime.parse("2026-10-01T18:00"),
                        status = DeliveryStatus.CONFIRMED,
                        minVolunteersRequired = 2,
                        contracts =
                            listOf(
                                DeliveryContract(
                                    contractId = "contract-1".toId(),
                                    coordinators = memberIds,
                                    basketQuantity = 10,
                                    deliveryDescription = "Légumes",
                                    status = DeliveryContractStatus.PENDING,
                                    slots =
                                        listOf(
                                            MemberSlot(
                                                startTime = LocalDateTime.parse("2026-10-01T18:00"),
                                                endTime = LocalDateTime.parse("2026-10-01T20:00"),
                                                activityType = ActivityType.DISTRIBUTION,
                                                requiredVolunteers = 2,
                                                currentRegistrations = memberIds.size,
                                                status = SlotStatus.OPEN,
                                                registrations = memberIds.map { registration(it) },
                                            ),
                                        ),
                                    exchanges =
                                        memberIds.map {
                                            Exchange(
                                                memberId = it,
                                                targetMemberId = it,
                                                exchangeInstant = epoch,
                                                status = ExchangeStatus.PENDING,
                                            )
                                        },
                                ),
                            ),
                    ),
                ),
        )

    private fun contract(memberIds: List<Id<Member>>) =
        Contract(
            contractId = "contract-1".toId(),
            name = "Légumes",
            organizationId = "org-1".toId(),
            producerAccountId = "producer-1".toId(),
            minDeliveryDate = LocalDate.parse("2026-01-01"),
            maxDeliveryDate = LocalDate.parse("2026-12-31"),
            deliveryCount = 40,
            seasonYear = 2026,
            coordinators = memberIds,
            members = memberIds.map { ContractMember(it, epoch, MemberContractStatus.ACTIVE) },
            sharedBaskets = listOf(SharedBasket("basket-1".toId(), memberIds)),
        )

    private fun exchange(memberIds: List<Id<Member>>) =
        BasketExchange(
            basketExchangeId = "exchange-1".toId(),
            organizationId = "org-1".toId(),
            deliveryId = "delivery-1".toId(),
            contractId = "contract-1".toId(),
            offeringMemberId = memberIds.first(),
            status = BasketExchangeStatus.OPEN,
            createdAt = epoch,
            requests =
                memberIds.mapIndexed { index, memberId ->
                    BasketExchangeRequest(
                        requestId = "request-$index".toId(),
                        requesterMemberId = memberId,
                        createdAt = epoch,
                        status = BasketExchangeRequestStatus.PENDING,
                    )
                },
        )

    @Test
    fun `GIVEN an organization referencing the member THEN coordinators, registrations and exchanges are rewritten`() {
        assertEquals(organization(listOf(new, other)), organization(listOf(old, other)).withMemberIdReplaced(old, new))
    }

    @Test
    fun `GIVEN a contract referencing the member THEN coordinators, subscriptions and shared baskets are rewritten`() {
        assertEquals(contract(listOf(new, other)), contract(listOf(old, other)).withMemberIdReplaced(old, new))
    }

    @Test
    fun `GIVEN a basket exchange referencing the member THEN offerer and requesters are rewritten`() {
        assertEquals(exchange(listOf(new, other)), exchange(listOf(old, other)).withMemberIdReplaced(old, new))
    }

    @Test
    fun `GIVEN no reference to the member THEN the same instances are returned`() {
        val organization = organization(listOf(other))
        val contract = contract(listOf(other))
        val exchange = exchange(listOf(other))

        assertSame(organization, organization.withMemberIdReplaced(old, new))
        assertSame(contract, contract.withMemberIdReplaced(old, new))
        assertSame(exchange, exchange.withMemberIdReplaced(old, new))
    }
}

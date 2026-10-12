@file:OptIn(ExperimentalTime::class)

package member

import id.toId
import kotlinx.datetime.LocalDate
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.MemberContractStatus
import persistence.model.SharedBasket
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

class DeletedMemberContractsTest {
    private val deleted = "deleted-sub"
    private val today = LocalDate.parse("2026-10-10")

    private fun subscription(
        memberId: String,
        status: MemberContractStatus = MemberContractStatus.ACTIVE,
    ) = ContractMember(memberId = memberId.toId(), subscriptionInstant = Instant.fromEpochMilliseconds(1_000L), status = status)

    private fun contract(
        maxDeliveryDate: String = "2026-12-23",
        status: ContractStatus = ContractStatus.ACTIVE,
        members: List<ContractMember> = listOf(subscription(deleted), subscription("neighbour")),
        coordinators: List<String> = listOf(deleted, "coordinator"),
        sharedBaskets: List<SharedBasket> = emptyList(),
    ) = Contract(
        contractId = "contract-1".toId(),
        name = "Légumes",
        organizationId = "org-1".toId(),
        producerAccountId = "producer-1".toId(),
        minDeliveryDate = LocalDate.parse("2026-04-08"),
        maxDeliveryDate = LocalDate.parse(maxDeliveryDate),
        deliveryCount = 37,
        seasonYear = 2026,
        coordinators = coordinators.map { it.toId() },
        members = members,
        status = status,
        sharedBaskets = sharedBaskets,
    )

    private fun basket(
        id: String,
        vararg memberIds: String,
    ) = SharedBasket(sharedBasketId = id.toId(), memberIds = memberIds.map { it.toId() })

    @Test
    fun `GIVEN an ongoing contract WHEN the member is deleted THEN the subscription is cancelled and the coordinator pool left`() {
        val closed = DeletedMemberContracts.close(contract(), deleted.toId(), today)

        assertEquals(
            contract(
                members = listOf(subscription(deleted, MemberContractStatus.CANCELLED), subscription("neighbour")),
                coordinators = listOf("coordinator"),
            ),
            closed,
        )
    }

    @Test
    fun `GIVEN shared baskets WHEN the member is deleted THEN they leave them and a basket left alone is dropped`() {
        val ongoing =
            contract(
                members = listOf(subscription(deleted), subscription("a"), subscription("b"), subscription("c")),
                sharedBaskets = listOf(basket("trio", deleted, "a", "b"), basket("pair", deleted, "c")),
            )

        val closed = DeletedMemberContracts.close(ongoing, deleted.toId(), today)

        assertEquals(listOf(basket("trio", "a", "b")), closed?.sharedBaskets)
    }

    @Test
    fun `GIVEN an ended contract WHEN the member is deleted THEN it is kept as history`() {
        assertNull(DeletedMemberContracts.close(contract(maxDeliveryDate = "2026-07-01"), deleted.toId(), today))
        assertNull(DeletedMemberContracts.close(contract(status = ContractStatus.ENDED), deleted.toId(), today))
    }

    @Test
    fun `GIVEN an already cancelled subscription and no role WHEN the member is deleted THEN the contract is unchanged`() {
        val untouched =
            contract(
                members = listOf(subscription(deleted, MemberContractStatus.CANCELLED), subscription("neighbour")),
                coordinators = listOf("coordinator"),
            )

        assertNull(DeletedMemberContracts.close(untouched, deleted.toId(), today))
    }
}

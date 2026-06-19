@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.datetime.LocalDate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Serializable
enum class ContractStatus {
    IN_PREPARATION,
    ACTIVE,
    ENDED,
}

/**
 * Season contract definition for a specific producer account with embedded member subscriptions.
 */
@Serializable
data class Contract(
    @SerialName("contract_id") val contractId: Id<Contract>,
    val name: String,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    @SerialName("min_delivery_date") val minDeliveryDate: LocalDate,
    @SerialName("max_delivery_date") val maxDeliveryDate: LocalDate,
    @SerialName("delivery_count") val deliveryCount: Int,
    @SerialName("season_year") val seasonYear: Int,
    @SerialName("product_prices") val productPrices: List<ProductPrice> = emptyList(),
    val coordinators: List<Id<Member>> = emptyList(),
    val members: List<ContractMember> = emptyList(),
    val status: ContractStatus = ContractStatus.IN_PREPARATION,
    @SerialName("delivery_template_id") val deliveryTemplateId: Id<DeliveryTemplate>? = null,
    @SerialName("shared_baskets") val sharedBaskets: List<SharedBasket> = emptyList(),
) {
    /**
     * Returns true when [today] is strictly after [maxDeliveryDate].
     *
     * The contract is active on the last day ([today] == [maxDeliveryDate] → false).
     */
    fun isEnded(today: LocalDate): Boolean = maxDeliveryDate < today

    /**
     * Returns true when the contract is effectively ended: either its [status] is [ContractStatus.ENDED]
     * or [maxDeliveryDate] is strictly before [today].
     */
    fun isEffectivelyEnded(today: LocalDate): Boolean = status == ContractStatus.ENDED || isEnded(today)
}

/**
 * Price entry for a given product type and optional basket size in a contract.
 */
@Serializable
data class ProductPrice(
    @SerialName("product_type_id") val productTypeId: String,
    @SerialName("basket_size") val basketSize: BasketSize? = null,
    val price: Double? = null,
)

/**
 * Member subscription to a contract (embedded in Contract).
 */
@Serializable
data class ContractMember(
    @SerialName("member_id") val memberId: Id<Member>,
    @SerialName("subscription_instant") val subscriptionInstant: Instant,
    val status: MemberContractStatus,
    val subscriptions: List<MemberSubscription> = emptyList(),
)

/**
 * A member's subscription to a specific product type and optional basket size within a contract.
 */
@Serializable
data class MemberSubscription(
    @SerialName("product_type_id") val productTypeId: String,
    @SerialName("basket_size") val basketSize: BasketSize? = null,
)

@Serializable
data class BasketSize(
    val name: String,
)

/**
 * A shared basket: several members ([memberIds]) share a single physical basket on this contract,
 * picking it up in round-robin alternation across the contract's deliveries.
 *
 * Overlay structure: the members keep their individual [ContractMember] subscriptions; this entry
 * only marks that they alternate on one basket. All members of a shared basket must hold an
 * identical subscription (enforced server-side).
 *
 * Alternation is anchored on a stable identity ([anchorDeliveryId]) rather than a positional index,
 * so inserting/removing other deliveries keeps the rotation start pinned. See SharedBasketAlternation.
 */
@Serializable
data class SharedBasket(
    @SerialName("shared_basket_id") val sharedBasketId: Id<SharedBasket>,
    @SerialName("member_ids") val memberIds: List<Id<Member>> = emptyList(),
    @SerialName("anchor_delivery_id") val anchorDeliveryId: Id<Delivery>? = null,
)

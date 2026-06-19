@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * A basket-exchange offer published by a member who cannot attend a delivery.
 * Requests are embedded in the offer as an aggregate root (1 mutation = 1 transaction).
 *
 * Scope: organization:{organizationId}
 */
@Serializable
data class BasketExchange(
    @SerialName("basket_exchange_id") val basketExchangeId: Id<BasketExchange>,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("delivery_id") val deliveryId: Id<Delivery>,
    @SerialName("contract_id") val contractId: Id<DeliveryContract>,
    @SerialName("offering_member_id") val offeringMemberId: Id<Member>,
    val motive: String? = null,
    val status: BasketExchangeStatus,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("decided_at") val decidedAt: Instant? = null,
    @SerialName("accepted_request_id") val acceptedRequestId: Id<BasketExchangeRequest>? = null,
    val requests: List<BasketExchangeRequest> = emptyList(),
)

@Serializable
enum class BasketExchangeStatus {
    OPEN,
    ACCEPTED,
    CANCELLED,
}

/**
 * A request sent by a member who wants to take a basket-exchange offer.
 * Embedded inside [BasketExchange.requests].
 *
 * Reciprocal swap: the requester proposes one of their own deliveries
 * ([proposedDeliveryId] / [proposedContractId]) in return — the offerer receives
 * that basket when validating the request. The fields are nullable on the wire
 * (robustness / legacy rows) but required at submission time by the service.
 */
@Serializable
data class BasketExchangeRequest(
    @SerialName("request_id") val requestId: Id<BasketExchangeRequest>,
    @SerialName("requester_member_id") val requesterMemberId: Id<Member>,
    @SerialName("created_at") val createdAt: Instant,
    val status: BasketExchangeRequestStatus,
    @SerialName("decided_at") val decidedAt: Instant? = null,
    @SerialName("proposed_delivery_id") val proposedDeliveryId: Id<Delivery>? = null,
    @SerialName("proposed_contract_id") val proposedContractId: Id<DeliveryContract>? = null,
)

@Serializable
enum class BasketExchangeRequestStatus {
    PENDING,
    ACCEPTED,
    REJECTED,
    WITHDRAWN,
}

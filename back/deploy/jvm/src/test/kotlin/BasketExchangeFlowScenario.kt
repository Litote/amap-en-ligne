package deploy.jvm

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import persistence.changes.MutationStatus
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus

/**
 * A `basket-exchange-flow` catalog story: members of one AMAP play offer / request / decision
 * steps. Every step reads the exchange from the actor's own bootstrap first, like a real client,
 * because the back diffs the whole aggregate it receives.
 */
@Serializable
data class BasketExchangeFlowScenario(
    val id: String,
    val title: String,
    val given: BasketExchangeFlowGiven,
    @SerialName("when")
    val steps: List<BasketExchangeFlowStep>,
    val then: BasketExchangeFlowThen,
)

@Serializable
data class BasketExchangeFlowGiven(
    val organizationId: String,
    val members: List<AcceptanceGivenMember>,
    val deliveries: List<BasketExchangeFlowDelivery>,
)

/** A future delivery seeded with a single contract link. */
@Serializable
data class BasketExchangeFlowDelivery(
    val deliveryId: String,
    val contractId: String,
    val scheduledDate: String,
)

/**
 * Supported actions: `create_offer` (params `deliveryId`, `contractId`; `save.offerRef`),
 * `submit_request` (params `offer`, `proposedDeliveryId`, `proposedContractId`) and
 * `accept_request` (params `offer`, `requester`). `actor` is the acting member id.
 */
@Serializable
data class BasketExchangeFlowStep(
    val actor: String,
    val action: String,
    val params: Map<String, String> = emptyMap(),
    val save: BasketExchangeFlowSave? = null,
    val expect: BasketExchangeFlowOutcomeExpectation = BasketExchangeFlowOutcomeExpectation(),
)

@Serializable
data class BasketExchangeFlowSave(
    val offerRef: String? = null,
)

@Serializable
data class BasketExchangeFlowOutcomeExpectation(
    val status: MutationStatus = MutationStatus.APPLIED,
    val errorCode: String? = null,
)

@Serializable
data class BasketExchangeFlowThen(
    val exchange: BasketExchangeFlowExchangeExpectation,
)

/** The final state of the `offer` exchange as served to `viewedBy`'s bootstrap. */
@Serializable
data class BasketExchangeFlowExchangeExpectation(
    val offer: String,
    val viewedBy: String,
    val status: BasketExchangeStatus,
    val acceptedRequester: String? = null,
    val requestStatuses: Map<String, BasketExchangeRequestStatus> = emptyMap(),
)

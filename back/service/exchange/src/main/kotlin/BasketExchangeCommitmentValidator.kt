package exchange

import id.Id
import org.koin.core.annotation.Single
import persistence.changes.ClientMutation
import persistence.changes.MutationError
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.dao.ContractSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.Member
import persistence.model.Organization
import persistence.model.holdsBasketOn
import persistence.model.orderedDeliveryIdsForContract

/**
 * Guards basket-commitment invariants for [BasketExchange]:
 *  - [isBasketCommitted] detects whether a (member, delivery) basket is already engaged.
 *  - [rejectIfNotBasketHolder] enforces the shared-basket alternation rule so only the
 *    family whose turn it is may offer or counter-offer a given delivery.
 */
@Single
class BasketExchangeCommitmentValidator(
    private val contractSyncDAO: ContractSyncDAO,
) {
    /**
     * Rejects (FORBIDDEN) when [memberId] does not hold the basket of the contract identified by
     * [contractId] on [deliveryId] this week — i.e. when the contract uses an alternating shared
     * basket and it is another family's turn. No-op when [contractId] is null, the contract is
     * unknown, or it has no shared baskets (the non-shared case is unchanged). [role] is "offer" or
     * "counter-delivery" for the message.
     */
    suspend fun rejectIfNotBasketHolder(
        mutation: ClientMutation,
        organization: Organization,
        contractId: Id<DeliveryContract>?,
        deliveryId: Id<Delivery>,
        memberId: Id<Member>,
        role: String,
    ): MutationOutcome? {
        if (contractId == null) return null
        val contract =
            contractSyncDAO
                .getByOrganizationId(organization.organizationId)
                .find { it.contractId.id == contractId.id } ?: return null
        if (contract.sharedBaskets.isEmpty()) return null
        val ordered = organization.orderedDeliveryIdsForContract(contract.contractId)
        if (contract.holdsBasketOn(memberId, ordered, deliveryId)) return null
        return MutationOutcome(
            clientOpId = mutation.clientOpId,
            status = MutationStatus.REJECTED,
            error =
                MutationError(
                    code = MutationErrorCode.FORBIDDEN,
                    message =
                        "member ${memberId.id} does not hold the shared basket of contract ${contract.contractId.id} " +
                            "on delivery ${deliveryId.id} this week ($role)",
                ),
        )
    }
}

/**
 * True when [memberId]'s basket for [deliveryId] is already engaged in another exchange so it
 * cannot be re-committed. A basket is committed when it is:
 *  - currently offered for exchange (OPEN/ACCEPTED), or
 *  - given away or received through a settled (ACCEPTED) exchange.
 *
 * In an ACCEPTED exchange both deliveries change hands: the offerer gives D1 and receives the
 * accepted counter-delivery D2, the requester gives D2 and receives D1. Both deliveries are
 * therefore committed for both parties — a basket already exchanged or received cannot be
 * re-offered or re-proposed.
 */
fun List<BasketExchange>.isBasketCommitted(
    memberId: Id<Member>,
    deliveryId: Id<Delivery>,
): Boolean =
    any { ex ->
        val offered =
            ex.offeringMemberId == memberId &&
                ex.deliveryId == deliveryId &&
                ex.status in setOf(BasketExchangeStatus.OPEN, BasketExchangeStatus.ACCEPTED)
        if (offered) return@any true
        if (ex.status != BasketExchangeStatus.ACCEPTED) return@any false
        val acceptedRequest =
            ex.acceptedRequestId?.let { id -> ex.requests.find { it.requestId == id } }
                ?: return@any false
        val involvesMember = memberId == ex.offeringMemberId || memberId == acceptedRequest.requesterMemberId
        involvesMember && (deliveryId == ex.deliveryId || deliveryId == acceptedRequest.proposedDeliveryId)
    }

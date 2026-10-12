package member

import id.Id
import kotlinx.datetime.LocalDate
import persistence.model.Contract
import persistence.model.Member
import persistence.model.MemberContractStatus

/**
 * What a deleted member leaves in the contracts still running (neither ENDED nor past their
 * last delivery): their subscription is CANCELLED — their baskets no longer count —, they leave
 * the coordinator pool and the shared baskets (a shared basket left with fewer than two members
 * is dropped). Ended contracts are history and stay as they are.
 */
internal object DeletedMemberContracts {
    private val OPEN_SUBSCRIPTION_STATUSES = setOf(MemberContractStatus.ACTIVE, MemberContractStatus.SUSPENDED)
    private const val MIN_SHARED_BASKET_MEMBERS = 2

    /** [contract] once [memberId] is deleted, or null when it does not change. */
    fun close(
        contract: Contract,
        memberId: Id<Member>,
        today: LocalDate,
    ): Contract? {
        if (contract.isEffectivelyEnded(today)) return null
        val closed =
            contract.copy(
                members =
                    contract.members.map {
                        if (it.memberId == memberId && it.status in OPEN_SUBSCRIPTION_STATUSES) {
                            it.copy(status = MemberContractStatus.CANCELLED)
                        } else {
                            it
                        }
                    },
                coordinators = contract.coordinators - memberId,
                sharedBaskets =
                    contract.sharedBaskets
                        .map { it.copy(memberIds = it.memberIds - memberId) }
                        .filter { it.memberIds.size >= MIN_SHARED_BASKET_MEMBERS },
            )
        return closed.takeIf { it != contract }
    }
}

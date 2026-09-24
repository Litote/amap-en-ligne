package member

import id.Id
import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.Contract
import persistence.model.ContractStatus
import persistence.model.Member
import kotlin.time.Clock

/**
 * Contract-lifecycle checks on the [Member.contracts] entries newly added by a member upsert.
 *
 * Only new contract ids (present in the updated row but absent in the existing one) are checked;
 * a null existing row means a new member — all its contract ids are considered new. Unknown
 * contract ids (not returned by the DAO) pass through without error.
 */
internal class MemberContractSubscriptionGuard(
    private val contractSyncDAO: ContractSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
) {
    /**
     * Returns the newly-added contract ids whose contract is effectively ended
     * ([persistence.model.Contract.maxDeliveryDate] in the past, or status ENDED).
     */
    suspend fun endedContractIds(
        organizationId: String,
        existing: Member?,
        updated: Member,
    ): List<Id<Contract>> {
        val newContractIds = newContractIds(existing, updated)
        if (newContractIds.isEmpty()) return emptyList()

        val today = resolveToday(organizationId)
        val orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
        return newContractIds.filter { contractId ->
            orgContracts.find { it.contractId == contractId }?.isEffectivelyEnded(today) == true
        }
    }

    /**
     * Returns the newly-added contract ids whose contract is still [ContractStatus.IN_PREPARATION].
     * Only non-privileged self-subscriptions are rejected on that ground — the caller decides.
     */
    suspend fun inPreparationContractIds(
        organizationId: String,
        existing: Member?,
        updated: Member,
    ): List<Id<Contract>> {
        val newContractIds = newContractIds(existing, updated)
        if (newContractIds.isEmpty()) return emptyList()

        val orgContracts = contractSyncDAO.getByOrganizationId(organizationId.toId())
        return newContractIds.filter { contractId ->
            orgContracts.find { it.contractId == contractId }?.status == ContractStatus.IN_PREPARATION
        }
    }

    private fun newContractIds(
        existing: Member?,
        updated: Member,
    ): Set<Id<Contract>> {
        val existingContractIds = existing?.contracts?.map { it.contractId }?.toSet() ?: emptySet()
        return updated.contracts.map { it.contractId }.toSet() - existingContractIds
    }

    private suspend fun resolveToday(organizationId: String): LocalDate {
        val timezone = organizationSyncDAO.getById(organizationId.toId())?.timezone ?: TimeZone.UTC
        return Clock.System.todayIn(timezone)
    }
}

package organization

import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.EntityType
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization

/**
 * Mirrors the `Organization.producers` links of account-backed producers onto their
 * [ProducerAccount] (`organizations` + the per-organization persisted row).
 *
 * Enrolling an account-backed producer is an `Organization` upsert only: without this, the
 * producer account row is never written for the organization, so the `organization:{id}`
 * scope never serves it (the admin sees its technical id instead of its name) and its
 * later profile / catalog changes are not fanned out to that organization.
 *
 * Only links that are new or whose status changed are written, so unrelated organization
 * writes (e.g. volunteer registrations) cost nothing. No-account producers keep their own
 * write path (`ProducerAccountService`).
 */
internal class AccountBackedProducerLinker(
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
) {
    suspend fun syncLinks(
        persistedOrg: Organization?,
        finalOrg: Organization,
    ) {
        val persistedLinks = persistedOrg?.producers.orEmpty().associateBy { it.producerAccountId }
        finalOrg.producers
            .filter { link -> persistedLinks[link.producerAccountId]?.status != link.status }
            .forEach { link -> writeLink(finalOrg, link) }
    }

    private suspend fun writeLink(
        organization: Organization,
        link: OrganizationProducer,
    ) {
        val account = producerAccountSyncDAO.findById(link.producerAccountId) ?: return
        if (account.managementMode != ProducerManagementMode.ACCOUNT_BACKED) return
        val organizationId = organization.organizationId
        val updated =
            account.copy(
                organizations =
                    account.organizations.filterNot { it.organizationId == organizationId } +
                        ProducerOrganization(organizationId, link.associationInstant, link.status),
            )
        val scopeKeys =
            updated.organizations.map { SyncScope.Organization(it.organizationId.id).key }.distinct() +
                SyncScope.InstanceOwner.key +
                SyncScope.ProducerAccount(updated.producerAccountId.id).key
        producerAccountSyncDAO.put(updated, organizationId, scopeKeys.map { upsertChange(updated, it) })
    }

    private fun upsertChange(
        producer: ProducerAccount,
        scopeKey: String,
    ) = Change(
        cursor = Cursor.next(),
        entityType = EntityType.ProducerAccount,
        entityId = producer.producerAccountId.id,
        scopeKey = scopeKey,
        op = ChangeOp.UPSERT,
        payload = ProducerAccountPayload(producer),
        producedAt = System.currentTimeMillis(),
    )
}

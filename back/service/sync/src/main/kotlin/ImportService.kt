@file:OptIn(kotlin.time.ExperimentalTime::class)

package sync

import authentication.AuthenticatedInfo
import authentication.Role
import id.Id
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.BasketExchangePayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.DeliveryTemplatePayload
import persistence.changes.MemberInvitationPayload
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.MemberPayload
import persistence.changes.OrganizationExport
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.ProductTypePayload
import persistence.changes.SyncScope
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.dao.DuplicatePendingInvitationException
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketExchange
import persistence.model.Contract
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberJoinRequest
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.ProductType
import kotlin.time.Clock

/**
 * Restores an [OrganizationExport] into a target organization (backup restore / instance migration).
 *
 * Trusted restore: the archive comes from our own export, so entities are written directly through
 * the sync DAOs (bypassing the interactive business guards that would reject a bulk import — role
 * exclusivity, ACCOUNT_BACKED producer creation, coordinator/contract checks, capacity caps…).
 *
 * Ids are **preserved** (globally-unique generated ids do not collide on a fresh instance); only the
 * source `organizationId` is rewritten to the target one. To keep the semantics unambiguous the
 * target organization must be **empty** (no members / contracts / producers / templates / deliveries /
 * basket exchanges / invitations / join requests); otherwise the import is rejected with a conflict.
 *
 * Imported [Member]s carry their PII but no auth identity (the JWT `sub` is never on the wire), so
 * they stay inert until (re)invited through the regular activation flow.
 */
@Single(createdAtStart = true)
class ImportService(
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val deliveryTemplateSyncDAO: DeliveryTemplateSyncDAO,
    private val basketExchangeSyncDAO: BasketExchangeSyncDAO,
    private val memberInvitationDAO: MemberInvitationSyncDAO,
    private val memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO,
    private val productTypeDAO: ProductTypeSyncDAO,
) {
    suspend fun importIntoOrganization(
        auth: AuthenticatedInfo,
        targetOrganizationId: String,
        export: OrganizationExport,
    ): ImportOutcome {
        if (export.formatVersion != OrganizationExport.CURRENT_FORMAT_VERSION) {
            return ImportOutcome.InvalidFormat("unsupported format_version ${export.formatVersion}")
        }
        if (!isAuthorized(auth, targetOrganizationId)) return ImportOutcome.Forbidden

        val targetId = targetOrganizationId.toId<Organization>()
        val targetOrganization = organizationSyncDAO.getById(targetId) ?: return ImportOutcome.NotFound

        nonEmptyReason(targetId, targetOrganization, auth.memberId)?.let {
            return ImportOutcome.Conflict(it)
        }

        val sourceId = export.organizationId.toId<Organization>()
        val scopeKey = SyncScope.Organization(targetOrganizationId).key

        // Dependency order: producers/templates/members/contracts before the Organization aggregate
        // (which embeds deliveries referencing them), then the transient aggregates.
        val productTypes =
            export.scopes.productTypes
                .filterIsInstance<ProductTypePayload>()
                .map { it.productType }
        val producerAccounts =
            export.scopes.organization
                .filterIsInstance<ProducerAccountPayload>()
                .map { it.producerAccount }
        val templates =
            export.scopes.organization
                .filterIsInstance<DeliveryTemplatePayload>()
                .map { it.deliveryTemplate }
        val members =
            export.scopes.organization
                .filterIsInstance<MemberPayload>()
                .map { it.member }
        val contracts =
            export.scopes.organization
                .filterIsInstance<ContractPayload>()
                .map { it.contract }
        val organizations =
            export.scopes.organization
                .filterIsInstance<OrganizationPayload>()
                .map { it.organization }
        val invitations =
            export.scopes.organization
                .filterIsInstance<MemberInvitationPayload>()
                .map { it.memberInvitation }
        val joinRequests =
            export.scopes.organization
                .filterIsInstance<MemberJoinRequestPayload>()
                .map { it.memberJoinRequest }
        val basketExchanges =
            export.scopes.organization
                .filterIsInstance<BasketExchangePayload>()
                .map { it.basketExchange }

        for (productType in productTypes) {
            val producerScopeKey = SyncScope.ProducerAccount(productType.producerAccountId.id).key
            productTypeDAO.put(
                productType,
                change(EntityType.ProductType, productType.productTypeId.id, producerScopeKey, ProductTypePayload(productType)),
            )
        }
        for (producerAccount in producerAccounts) {
            val rewritten = rewriteProducerAccount(producerAccount, sourceId, targetId)
            producerAccountSyncDAO.put(
                rewritten,
                targetId,
                listOf(change(EntityType.ProducerAccount, rewritten.producerAccountId.id, scopeKey, ProducerAccountPayload(rewritten))),
            )
        }
        for (template in templates) {
            val rewritten = template.copy(organizationId = targetId)
            deliveryTemplateSyncDAO.put(
                rewritten,
                change(EntityType.DeliveryTemplate, rewritten.deliveryTemplateId.id, scopeKey, DeliveryTemplatePayload(rewritten)),
            )
        }
        for (member in members) {
            val rewritten = member.copy(organizationId = targetId)
            memberSyncDAO.put(
                rewritten,
                listOf(change(EntityType.Member, rewritten.memberId.id, scopeKey, MemberPayload(rewritten))),
            )
        }
        for (contract in contracts) {
            val rewritten = contract.copy(organizationId = targetId)
            contractSyncDAO.put(rewritten, change(EntityType.Contract, rewritten.contractId.id, scopeKey, ContractPayload(rewritten)))
        }
        for (organization in organizations) {
            val rewritten = rewriteOrganization(organization, targetId)
            organizationSyncDAO.put(
                rewritten,
                change(EntityType.Organization, rewritten.organizationId.id, scopeKey, OrganizationPayload(rewritten)),
            )
        }
        var skippedInvitations = 0
        for (invitation in invitations) {
            val rewritten = invitation.copy(organizationId = targetId)
            try {
                memberInvitationDAO.put(
                    rewritten,
                    change(EntityType.MemberInvitation, rewritten.invitationId, scopeKey, MemberInvitationPayload(rewritten)),
                )
            } catch (e: DuplicatePendingInvitationException) {
                skippedInvitations++
                logger.warn(e) { "skipping invitation for already-pending email during import into $targetOrganizationId" }
            }
        }
        for (joinRequest in joinRequests) {
            val rewritten = joinRequest.copy(organizationId = targetId)
            memberJoinRequestSyncDAO.put(
                rewritten,
                change(EntityType.MemberJoinRequest, rewritten.requestId.id, scopeKey, MemberJoinRequestPayload(rewritten)),
            )
        }
        for (basketExchange in basketExchanges) {
            val rewritten = basketExchange.copy(organizationId = targetId)
            basketExchangeSyncDAO.put(
                rewritten,
                change(EntityType.BasketExchange, rewritten.basketExchangeId.id, scopeKey, BasketExchangePayload(rewritten)),
            )
        }

        return ImportOutcome.Success(
            ImportResult(
                organizationId = targetOrganizationId,
                productTypes = productTypes.size,
                producerAccounts = producerAccounts.size,
                deliveryTemplates = templates.size,
                members = members.size,
                contracts = contracts.size,
                organizations = organizations.size,
                memberInvitations = invitations.size - skippedInvitations,
                skippedInvitations = skippedInvitations,
                memberJoinRequests = joinRequests.size,
                basketExchanges = basketExchanges.size,
            ),
        )
    }

    private suspend fun nonEmptyReason(
        targetId: Id<Organization>,
        targetOrganization: Organization,
        callerMemberId: String,
    ): String? =
        when {
            // The caller's own member row (the org's bootstrap admin) is expected and ignored.
            memberSyncDAO.getByOrganizationId(targetId).any { it.memberId.id != callerMemberId } -> {
                "target organization already has members"
            }

            contractSyncDAO.getByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has contracts"
            }

            producerAccountSyncDAO.getByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has producers"
            }

            deliveryTemplateSyncDAO.getByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has delivery templates"
            }

            basketExchangeSyncDAO.getByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has basket exchanges"
            }

            memberInvitationDAO.listByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has invitations"
            }

            memberJoinRequestSyncDAO.listByOrganizationId(targetId).isNotEmpty() -> {
                "target organization already has join requests"
            }

            targetOrganization.deliveries.isNotEmpty() -> {
                "target organization already has deliveries"
            }

            else -> {
                null
            }
        }

    private fun rewriteOrganization(
        organization: Organization,
        targetId: Id<Organization>,
    ): Organization =
        organization.copy(
            organizationId = targetId,
            deliveries = organization.deliveries.map { it.copy(organizationId = targetId) },
        )

    private fun rewriteProducerAccount(
        producerAccount: ProducerAccount,
        sourceId: Id<Organization>,
        targetId: Id<Organization>,
    ): ProducerAccount =
        producerAccount.copy(
            organizations =
                producerAccount.organizations.map { link ->
                    if (link.organizationId == sourceId) link.copy(organizationId = targetId) else link
                },
        )

    private fun change(
        entityType: EntityType,
        entityId: String,
        scopeKey: String,
        payload: persistence.changes.EntityPayload,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = entityType,
            entityId = entityId,
            scopeKey = scopeKey,
            op = ChangeOp.UPSERT,
            payload = payload,
            producedAt = Clock.System.now().toEpochMilliseconds(),
        )

    private suspend fun isAuthorized(
        auth: AuthenticatedInfo,
        organizationId: String,
    ): Boolean {
        if (auth.roles.contains(Role.OWNER)) return true
        if (!auth.roles.contains(Role.ADMIN)) return false
        val callerOrganizationId =
            auth.organizationId ?: memberSyncDAO.findOrganizationIdBySub(auth.memberId)?.id
        return callerOrganizationId == organizationId
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

@kotlinx.serialization.Serializable
data class ImportResult(
    @kotlinx.serialization.SerialName("organization_id") val organizationId: String,
    @kotlinx.serialization.SerialName("product_types") val productTypes: Int,
    @kotlinx.serialization.SerialName("producer_accounts") val producerAccounts: Int,
    @kotlinx.serialization.SerialName("delivery_templates") val deliveryTemplates: Int,
    val members: Int,
    val contracts: Int,
    val organizations: Int,
    @kotlinx.serialization.SerialName("member_invitations") val memberInvitations: Int,
    @kotlinx.serialization.SerialName("skipped_invitations") val skippedInvitations: Int,
    @kotlinx.serialization.SerialName("member_join_requests") val memberJoinRequests: Int,
    @kotlinx.serialization.SerialName("basket_exchanges") val basketExchanges: Int,
)

sealed interface ImportOutcome {
    data class Success(
        val result: ImportResult,
    ) : ImportOutcome

    data object Forbidden : ImportOutcome

    data object NotFound : ImportOutcome

    data class Conflict(
        val reason: String,
    ) : ImportOutcome

    data class InvalidFormat(
        val reason: String,
    ) : ImportOutcome
}

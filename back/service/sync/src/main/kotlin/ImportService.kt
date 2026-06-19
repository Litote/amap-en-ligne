@file:OptIn(kotlin.time.ExperimentalTime::class)

package sync

import authentication.AuthenticatedInfo
import authentication.Role
import id.Id
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
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
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketExchange
import persistence.model.Contract
import persistence.model.DeliveryTemplate
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberJoinRequest
import persistence.model.Organization
import persistence.model.ProducerAccount
import persistence.model.ProductType
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours

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
    private val ownerSyncDAO: OwnerSyncDAO,
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
        val payloads = extractPayloads(export)

        // An email already owned by an instance OWNER cannot become a Member/invitation: OWNER role
        // is exclusive. Such members and their invitations are skipped (account + invitation) and the
        // collision is surfaced as a warning the UI can display, rather than silently corrupting the
        // owner-exclusivity invariant at activation time.
        val ownerEmails =
            ownerSyncDAO
                .listAll()
                .mapNotNull {
                    it.email
                        .trim()
                        .lowercase()
                        .takeIf(String::isNotBlank)
                }.toSet()
        val (ownerColludingMembers, importableMembers) =
            payloads.members.partition { it.email.collidesWith(ownerEmails) }
        val (ownerColludingInvitations, importableInvitations) =
            payloads.invitations.partition { it.email.collidesWith(ownerEmails) }
        val warnings = ownerCollisionWarnings(ownerColludingMembers.mapNotNull { it.email } + ownerColludingInvitations.map { it.email })

        importProducts(payloads.productTypes)
        importProducerAccounts(payloads.producerAccounts, sourceId, targetId, scopeKey)
        importTemplates(payloads.templates, targetId, scopeKey)
        importMembers(importableMembers, targetId, scopeKey)
        importContracts(payloads.contracts, targetId, scopeKey)
        importOrganization(payloads.organizations, targetOrganization, targetId, scopeKey)

        val invitationCounts =
            importInvitationsAndAutoGenerate(
                importableInvitations,
                importableMembers,
                targetId,
                scopeKey,
                targetOrganizationId,
            )

        importJoinRequests(payloads.joinRequests, targetId, scopeKey)
        importBasketExchanges(payloads.basketExchanges, targetId, scopeKey)

        return ImportOutcome.Success(
            ImportResult(
                organizationId = targetOrganizationId,
                productTypes = payloads.productTypes.size,
                producerAccounts = payloads.producerAccounts.size,
                deliveryTemplates = payloads.templates.size,
                members = importableMembers.size,
                contracts = payloads.contracts.size,
                organizations = payloads.organizations.size,
                memberInvitations = importableInvitations.size - invitationCounts.skipped,
                skippedInvitations = invitationCounts.skipped,
                generatedInvitations = invitationCounts.generated,
                memberJoinRequests = payloads.joinRequests.size,
                basketExchanges = payloads.basketExchanges.size,
                warnings = warnings,
            ),
        )
    }

    private fun String?.collidesWith(ownerEmails: Set<String>): Boolean = !isNullOrBlank() && trim().lowercase() in ownerEmails

    private fun ownerCollisionWarnings(emails: List<String>): List<String> =
        emails
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .distinctBy { it.lowercase() }
            .map { "Le membre « $it » n'a pas été importé : un compte propriétaire existe déjà avec cette adresse e-mail." }

    private data class ExtractedPayloads(
        val productTypes: List<ProductType>,
        val producerAccounts: List<ProducerAccount>,
        val templates: List<DeliveryTemplate>,
        val members: List<Member>,
        val contracts: List<Contract>,
        val organizations: List<Organization>,
        val invitations: List<MemberInvitation>,
        val joinRequests: List<MemberJoinRequest>,
        val basketExchanges: List<BasketExchange>,
    )

    private fun extractPayloads(export: OrganizationExport): ExtractedPayloads =
        ExtractedPayloads(
            productTypes =
                export.scopes.productTypes
                    .filterIsInstance<ProductTypePayload>()
                    .map { it.productType },
            producerAccounts =
                export.scopes.organization
                    .filterIsInstance<ProducerAccountPayload>()
                    .map { it.producerAccount },
            templates =
                export.scopes.organization
                    .filterIsInstance<DeliveryTemplatePayload>()
                    .map { it.deliveryTemplate },
            members =
                export.scopes.organization
                    .filterIsInstance<MemberPayload>()
                    .map { it.member },
            contracts =
                export.scopes.organization
                    .filterIsInstance<ContractPayload>()
                    .map { it.contract },
            organizations =
                export.scopes.organization
                    .filterIsInstance<OrganizationPayload>()
                    .map { it.organization },
            invitations =
                export.scopes.organization
                    .filterIsInstance<MemberInvitationPayload>()
                    .map { it.memberInvitation },
            joinRequests =
                export.scopes.organization
                    .filterIsInstance<MemberJoinRequestPayload>()
                    .map { it.memberJoinRequest },
            basketExchanges =
                export.scopes.organization
                    .filterIsInstance<BasketExchangePayload>()
                    .map { it.basketExchange },
        )

    private suspend fun importProducts(productTypes: List<ProductType>) {
        for (productType in productTypes) {
            val producerScopeKey = SyncScope.ProducerAccount(productType.producerAccountId.id).key
            productTypeDAO.put(
                productType,
                change(EntityType.ProductType, productType.productTypeId.id, producerScopeKey, ProductTypePayload(productType)),
            )
        }
    }

    private suspend fun importProducerAccounts(
        producerAccounts: List<ProducerAccount>,
        sourceId: Id<Organization>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (producerAccount in producerAccounts) {
            val rewritten = rewriteProducerAccount(producerAccount, sourceId, targetId)
            producerAccountSyncDAO.put(
                rewritten,
                targetId,
                listOf(change(EntityType.ProducerAccount, rewritten.producerAccountId.id, scopeKey, ProducerAccountPayload(rewritten))),
            )
        }
    }

    private suspend fun importTemplates(
        templates: List<DeliveryTemplate>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (template in templates) {
            val rewritten = template.copy(organizationId = targetId)
            deliveryTemplateSyncDAO.put(
                rewritten,
                change(EntityType.DeliveryTemplate, rewritten.deliveryTemplateId.id, scopeKey, DeliveryTemplatePayload(rewritten)),
            )
        }
    }

    private suspend fun importMembers(
        members: List<Member>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (member in members) {
            val rewritten = member.copy(organizationId = targetId)
            memberSyncDAO.put(
                rewritten,
                listOf(change(EntityType.Member, rewritten.memberId.id, scopeKey, MemberPayload(rewritten))),
            )
        }
    }

    private suspend fun importContracts(
        contracts: List<Contract>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (contract in contracts) {
            val rewritten = contract.copy(organizationId = targetId)
            contractSyncDAO.put(rewritten, change(EntityType.Contract, rewritten.contractId.id, scopeKey, ContractPayload(rewritten)))
        }
    }

    private suspend fun importOrganization(
        organizations: List<Organization>,
        targetOrganization: Organization,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (organization in organizations) {
            val rewritten = rewriteOrganization(organization, targetId)
            val merged =
                targetOrganization.copy(
                    name = rewritten.name,
                    contactEmail = rewritten.contactEmail,
                    timezone = rewritten.timezone,
                    defaultLanguage = rewritten.defaultLanguage,
                    deliveries = targetOrganization.deliveries + rewritten.deliveries,
                    producers = rewritten.producers,
                    products = rewritten.products,
                    defaultDeliveryTemplateId = rewritten.defaultDeliveryTemplateId,
                    notificationOverrides = rewritten.notificationOverrides,
                )
            organizationSyncDAO.put(
                merged,
                change(EntityType.Organization, merged.organizationId.id, scopeKey, OrganizationPayload(merged)),
            )
        }
    }

    private data class InvitationCounts(
        val skipped: Int,
        val generated: Int,
    )

    private suspend fun importInvitationsAndAutoGenerate(
        invitations: List<MemberInvitation>,
        members: List<Member>,
        targetId: Id<Organization>,
        scopeKey: String,
        targetOrganizationId: String,
    ): InvitationCounts {
        var skipped = 0
        for (invitation in invitations) {
            val rewritten = invitation.copy(organizationId = targetId)
            try {
                memberInvitationDAO.put(
                    rewritten,
                    change(EntityType.MemberInvitation, rewritten.invitationId, scopeKey, MemberInvitationPayload(rewritten)),
                )
            } catch (e: DuplicatePendingInvitationException) {
                skipped++
                logger.warn(e) { "skipping invitation for already-pending email during import into $targetOrganizationId" }
            }
        }

        val importedInvitationEmails = invitations.map { it.email.lowercase() }.toSet()
        val generatedEmailsSoFar = mutableSetOf<String>()
        val now = Clock.System.now()
        var generated = 0

        for (member in members) {
            val email = member.email
            if (email.isNullOrBlank()) continue
            val emailLower = email.lowercase()
            if (emailLower in importedInvitationEmails) continue
            if (!generatedEmailsSoFar.add(emailLower)) continue

            val invitation =
                MemberInvitation(
                    invitationId = generateId<MemberInvitation>().id,
                    organizationId = targetId,
                    email = email,
                    firstName = member.firstName ?: "",
                    lastName = member.lastName ?: "",
                    roles = member.roles,
                    status = MemberInvitationStatus.PENDING_ACTIVATION,
                    createdAt = now,
                    expiresAt = now + 168.hours,
                )
            try {
                memberInvitationDAO.put(
                    invitation,
                    change(EntityType.MemberInvitation, invitation.invitationId, scopeKey, MemberInvitationPayload(invitation)),
                )
                generated++
            } catch (e: DuplicatePendingInvitationException) {
                skipped++
                logger.warn(e) { "skipping auto-generated invitation for already-pending email during import into $targetOrganizationId" }
            }
        }

        return InvitationCounts(skipped, generated)
    }

    private suspend fun importJoinRequests(
        joinRequests: List<MemberJoinRequest>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (joinRequest in joinRequests) {
            val rewritten = joinRequest.copy(organizationId = targetId)
            memberJoinRequestSyncDAO.put(
                rewritten,
                change(EntityType.MemberJoinRequest, rewritten.requestId.id, scopeKey, MemberJoinRequestPayload(rewritten)),
            )
        }
    }

    private suspend fun importBasketExchanges(
        basketExchanges: List<BasketExchange>,
        targetId: Id<Organization>,
        scopeKey: String,
    ) {
        for (basketExchange in basketExchanges) {
            val rewritten = basketExchange.copy(organizationId = targetId)
            basketExchangeSyncDAO.put(
                rewritten,
                change(EntityType.BasketExchange, rewritten.basketExchangeId.id, scopeKey, BasketExchangePayload(rewritten)),
            )
        }
    }

    private suspend fun nonEmptyReason(
        targetId: Id<Organization>,
        targetOrganization: Organization,
        callerMemberId: String,
    ): String? =
        when {
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

@Serializable
data class ImportResult(
    @SerialName("organization_id") val organizationId: String,
    @SerialName("product_types") val productTypes: Int,
    @SerialName("producer_accounts") val producerAccounts: Int,
    @SerialName("delivery_templates") val deliveryTemplates: Int,
    val members: Int,
    val contracts: Int,
    val organizations: Int,
    @SerialName("member_invitations") val memberInvitations: Int,
    @SerialName("skipped_invitations") val skippedInvitations: Int,
    @SerialName("generated_invitations") val generatedInvitations: Int,
    @SerialName("member_join_requests") val memberJoinRequests: Int,
    @SerialName("basket_exchanges") val basketExchanges: Int,
    val warnings: List<String> = emptyList(),
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

@file:OptIn(ExperimentalTime::class)

package activation

import authentication.Role
import core.UserProvisioningPort
import core.memberInvitationChanges
import core.withMemberIdReplaced
import id.Id
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.BasketExchangePayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ContractPayload
import persistence.changes.Cursor
import persistence.changes.EntityPayload
import persistence.changes.MemberPayload
import persistence.changes.OrganizationPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.ProducerPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.ContractSyncDAO
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerInvitationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerSyncDAO
import persistence.dao.ServerDAO
import persistence.model.AccountStatus
import persistence.model.ActivateResponse
import persistence.model.ActivationKind
import persistence.model.EntityType
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.Owner
import persistence.model.OwnerInvitationStatus
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true)
class ActivationService(
    private val activationTokenDAO: ActivationTokenDAO,
    private val organizationRequestDAO: OrganizationRequestDAO,
    private val producerRequestDAO: ProducerRequestDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
    private val serverDAO: ServerDAO,
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val producerSyncDAO: ProducerSyncDAO,
    private val userProvisioningPort: UserProvisioningPort,
    private val memberInvitationDAO: MemberInvitationSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val ownerInvitationDAO: OwnerInvitationSyncDAO,
    private val ownerDAO: OwnerSyncDAO,
    private val contractSyncDAO: ContractSyncDAO,
    private val basketExchangeSyncDAO: BasketExchangeSyncDAO,
) {
    /**
     * Read-only preview of [token] for the activation screen: which account (email, kind,
     * organization/producer name) is about to be activated. Returns the same
     * NotFound/Expired/AlreadyActivated outcomes as [activate], without any side effect.
     */
    suspend fun describe(token: String): ActivationOutcome {
        val activationToken = activationTokenDAO.findByToken(token) ?: return ActivationOutcome.NotFound
        if (activationToken.expiresAt < Clock.System.now()) return ActivationOutcome.Expired
        if (activationToken.invalidatedAt != null) return ActivationOutcome.NotFound
        if (activationToken.activatedAt != null) return ActivationOutcome.AlreadyActivated

        val name: String? =
            when (activationToken.kind) {
                ActivationKind.ORGANIZATION_ADMIN -> {
                    val requestId = activationToken.requestId ?: return ActivationOutcome.NotFound
                    (organizationRequestDAO.findById(requestId) ?: return ActivationOutcome.NotFound).organizationName
                }

                ActivationKind.PRODUCER -> {
                    val requestId = activationToken.producerRequestId ?: return ActivationOutcome.NotFound
                    (producerRequestDAO.findById(requestId) ?: return ActivationOutcome.NotFound).producerName
                }

                ActivationKind.OWNER -> {
                    val invitationId = activationToken.ownerInvitationId ?: return ActivationOutcome.NotFound
                    val invitation = ownerInvitationDAO.findById(invitationId) ?: return ActivationOutcome.NotFound
                    if (invitation.status == OwnerInvitationStatus.CANCELLED) return ActivationOutcome.NotFound
                    if (invitation.status == OwnerInvitationStatus.ACTIVATED) return ActivationOutcome.AlreadyActivated
                    null
                }

                ActivationKind.MEMBER -> {
                    val invitationId = activationToken.memberInvitationId ?: return ActivationOutcome.NotFound
                    val invitation =
                        memberInvitationDAO.findById(invitationId.id) ?: return ActivationOutcome.NotFound
                    if (invitation.status == MemberInvitationStatus.CANCELLED) return ActivationOutcome.NotFound
                    if (invitation.status == MemberInvitationStatus.ACTIVATED) return ActivationOutcome.AlreadyActivated
                    (organizationSyncDAO.getById(invitation.organizationId) ?: return ActivationOutcome.NotFound).name
                }
            }
        return ActivationOutcome.Success(
            ActivateResponse(kind = activationToken.kind, organizationName = name, email = activationToken.adminEmail),
        )
    }

    suspend fun activate(
        token: String,
        password: String,
    ): ActivationOutcome {
        val activationToken = activationTokenDAO.findByToken(token) ?: return ActivationOutcome.NotFound
        val now = Clock.System.now()
        if (activationToken.expiresAt < now) return ActivationOutcome.Expired
        if (activationToken.invalidatedAt != null) return ActivationOutcome.NotFound
        if (activationToken.activatedAt != null) return ActivationOutcome.AlreadyActivated

        return when (activationToken.kind) {
            ActivationKind.ORGANIZATION_ADMIN -> {
                val requestId = activationToken.requestId ?: return ActivationOutcome.NotFound
                val organizationId = activationToken.organizationId ?: return ActivationOutcome.NotFound

                val request =
                    organizationRequestDAO.findById(requestId) ?: return ActivationOutcome.NotFound

                val organization = organizationSyncDAO.getById(organizationId)
                val serverId =
                    serverDAO
                        .list()
                        .singleOrNull()
                        ?.serverId
                        ?: error("ORGANIZATION_ADMIN activation requires exactly one configured server")

                val sub = userProvisioningPort.createAdminUser(activationToken.adminEmail, password)

                // memberId == sub: the auth subject is used directly as the member id.
                val member =
                    Member(
                        memberId = sub.toId(),
                        organizationId = organizationId,
                        roles = setOf(Role.ADMIN),
                        firstName = request.adminFirstName,
                        lastName = request.adminLastName,
                        email = activationToken.adminEmail,
                        accountStatus = MemberAccountStatus.ACTIVE,
                        registeredAt = now,
                        memberPreferences =
                            MemberPreferences(
                                deliveryRemindersEnabled = true,
                                volunteerAlertsEnabled = true,
                                lastUpdatedInstant = now,
                            ),
                        userPreferences =
                            UserPreferences(
                                emailNotificationsEnabled = true,
                                pushNotificationsEnabled = false,
                                lastUpdatedInstant = now,
                            ),
                        userSettings =
                            UserSettings(
                                language = organization?.defaultLanguage ?: request.defaultLanguage,
                                timezone = organization?.timezone ?: request.timezone,
                                serverId = serverId,
                                lastUpdatedInstant = now,
                            ),
                    )
                memberSyncDAO.put(member, buildMemberChanges(member))
                activationTokenDAO.markActivated(token, now)

                ActivationOutcome.Success(
                    ActivateResponse(
                        kind = ActivationKind.ORGANIZATION_ADMIN,
                        organizationName = request.organizationName,
                        email = activationToken.adminEmail,
                    ),
                )
            }

            ActivationKind.PRODUCER -> {
                val requestId = activationToken.producerRequestId ?: return ActivationOutcome.NotFound
                val producerAccountId = activationToken.producerAccountId ?: return ActivationOutcome.NotFound
                val request =
                    producerRequestDAO.findById(requestId) ?: return ActivationOutcome.NotFound
                val serverId =
                    serverDAO
                        .list()
                        .singleOrNull()
                        ?.serverId
                        ?: error("PRODUCER activation requires exactly one configured server")

                val sub =
                    userProvisioningPort.createProducerUser(
                        email = activationToken.adminEmail,
                        password = password,
                        firstName = request.adminFirstName,
                        lastName = request.adminLastName,
                    )

                // producerId == sub: the auth subject is used directly as the producer id.
                val producer =
                    Producer(
                        producerId = sub.toId(),
                        producerAccountId = producerAccountId,
                        role = ProducerRole.OWNER,
                        associationInstant = now,
                        status = ProducerStatus.ACTIVE,
                        producerPreferences =
                            ProducerPreferences(
                                productionAlertsEnabled = true,
                                lastUpdatedInstant = now,
                            ),
                        userPreferences =
                            UserPreferences(
                                emailNotificationsEnabled = true,
                                pushNotificationsEnabled = false,
                                lastUpdatedInstant = now,
                            ),
                        userSettings =
                            UserSettings(
                                language = "fr",
                                timezone = kotlinx.datetime.TimeZone.of("Europe/Paris"),
                                serverId = serverId,
                                lastUpdatedInstant = now,
                            ),
                    )
                producerSyncDAO.put(producer, listOf(buildProducerChange(producer)))
                clearProducerPendingActivation(producerAccountId, now)
                activationTokenDAO.markActivated(token, now)
                ActivationOutcome.Success(
                    ActivateResponse(
                        kind = ActivationKind.PRODUCER,
                        organizationName = request.producerName,
                        email = activationToken.adminEmail,
                    ),
                )
            }

            ActivationKind.OWNER -> {
                val invitationId = activationToken.ownerInvitationId ?: return ActivationOutcome.NotFound
                val invitation =
                    ownerInvitationDAO.findById(invitationId) ?: return ActivationOutcome.NotFound
                if (invitation.status == OwnerInvitationStatus.CANCELLED) return ActivationOutcome.NotFound
                if (invitation.status == OwnerInvitationStatus.ACTIVATED) return ActivationOutcome.AlreadyActivated

                val sub =
                    userProvisioningPort.createOwnerUser(
                        email = activationToken.adminEmail,
                        password = password,
                        firstName = invitation.firstName,
                        lastName = invitation.lastName,
                    )

                // ownerId == sub: the auth subject is used directly as the owner id.
                val ownerId = sub.toId<Owner>()
                val owner =
                    Owner(
                        ownerId = ownerId,
                        firstName = invitation.firstName,
                        lastName = invitation.lastName,
                        email = activationToken.adminEmail,
                        accountStatus = AccountStatus.ACTIVE,
                        registeredAt = now,
                        updatedAt = now,
                    )

                val change = buildOwnerChange(owner)
                ownerDAO.put(owner, change)

                val updatedInvitation =
                    invitation.copy(
                        status = OwnerInvitationStatus.ACTIVATED,
                        activatedAt = now,
                    )
                ownerInvitationDAO.put(updatedInvitation, buildOwnerInvitationChange(updatedInvitation))
                activationTokenDAO.markActivated(token, now)

                logger.info {
                    "Owner activated: ownerId=${ownerId.id} email=${activationToken.adminEmail}"
                }

                ActivationOutcome.Success(
                    ActivateResponse(
                        kind = ActivationKind.OWNER,
                        organizationName = null,
                        email = activationToken.adminEmail,
                    ),
                )
            }

            ActivationKind.MEMBER -> {
                val invitationId = activationToken.memberInvitationId ?: return ActivationOutcome.NotFound
                val invitation =
                    memberInvitationDAO.findById(invitationId.id) ?: return ActivationOutcome.NotFound
                if (invitation.status == MemberInvitationStatus.CANCELLED) return ActivationOutcome.NotFound
                if (invitation.status == MemberInvitationStatus.ACTIVATED) return ActivationOutcome.AlreadyActivated

                val organization =
                    organizationSyncDAO.getById(invitation.organizationId) ?: return ActivationOutcome.NotFound
                val serverId =
                    serverDAO
                        .list()
                        .singleOrNull()
                        ?.serverId
                        ?: error("member activation requires exactly one configured server")
                val sub =
                    userProvisioningPort.createMemberUser(
                        email = invitation.email,
                        password = password,
                        firstName = invitation.firstName,
                        lastName = invitation.lastName,
                        organizationId = invitation.organizationId.id,
                        roles = invitation.roles,
                    )
                // A member imported without auth account (same email, letter case ignored) is
                // re-keyed below instead of being duplicated: its subscriptions and history follow.
                val imported =
                    memberSyncDAO
                        .getByOrganizationId(invitation.organizationId)
                        .find { it.memberId.id != sub && it.email.equals(invitation.email, ignoreCase = true) }
                // memberId == sub: the auth subject is used directly as the member id.
                val member =
                    imported?.copy(
                        memberId = sub.toId(),
                        // The roles granted to the auth user, so the JWT and the row agree.
                        roles = invitation.roles,
                        firstName = imported.firstName ?: invitation.firstName,
                        lastName = imported.lastName ?: invitation.lastName,
                        email = invitation.email,
                        accountStatus = MemberAccountStatus.ACTIVE,
                        registeredAt = now,
                        userSettings = imported.userSettings.copy(serverId = serverId),
                    ) ?: Member(
                        memberId = sub.toId(),
                        organizationId = invitation.organizationId,
                        roles = invitation.roles,
                        firstName = invitation.firstName,
                        lastName = invitation.lastName,
                        email = invitation.email,
                        accountStatus = MemberAccountStatus.ACTIVE,
                        registeredAt = now,
                        memberPreferences =
                            MemberPreferences(
                                deliveryRemindersEnabled = true,
                                volunteerAlertsEnabled = true,
                                lastUpdatedInstant = now,
                            ),
                        userPreferences =
                            UserPreferences(
                                emailNotificationsEnabled = true,
                                pushNotificationsEnabled = false,
                                lastUpdatedInstant = now,
                            ),
                        userSettings =
                            UserSettings(
                                language = organization.defaultLanguage,
                                timezone = organization.timezone,
                                serverId = serverId,
                                lastUpdatedInstant = now,
                            ),
                    )
                memberSyncDAO.put(member, buildMemberChanges(member))
                if (imported != null) rekeyImportedMember(imported, member)

                val updatedInvitation =
                    invitation.copy(
                        status = MemberInvitationStatus.ACTIVATED,
                        activatedAt = now,
                    )
                memberInvitationDAO.put(updatedInvitation, memberInvitationChanges(updatedInvitation))
                activationTokenDAO.markActivated(token, now)

                ActivationOutcome.Success(
                    ActivateResponse(
                        kind = ActivationKind.MEMBER,
                        organizationName = organization.name,
                        email = activationToken.adminEmail,
                    ),
                )
            }
        }
    }

    /**
     * Clears [ProducerAccount.pendingActivation] once the producer owns an auth account, fanning
     * the update out on `instance-owner` and every linked organization scope so owners/admins
     * stop showing the producer as "invitation pending" without a full re-sync.
     */
    private suspend fun clearProducerPendingActivation(
        producerAccountId: Id<ProducerAccount>,
        now: Instant,
    ) {
        val producerAccount = producerAccountSyncDAO.findById(producerAccountId) ?: return
        if (!producerAccount.pendingActivation) return
        val activated = producerAccount.copy(pendingActivation = false, lastUpdatedInstant = now)
        val scopeKeys =
            producerAccount.organizations.map { SyncScope.Organization(it.organizationId.id).key }.distinct() +
                SyncScope.InstanceOwner.key
        val changes =
            scopeKeys.map { scopeKey ->
                Change(
                    cursor = Cursor.next(),
                    entityType = persistence.model.EntityType.ProducerAccount,
                    entityId = producerAccountId.id,
                    scopeKey = scopeKey,
                    op = ChangeOp.UPSERT,
                    payload = ProducerAccountPayload(activated),
                    producedAt = System.currentTimeMillis(),
                )
            }
        producerAccountSyncDAO.updatePendingActivation(producerAccountId, false, changes)
    }

    private fun buildProducerChange(producer: Producer): Change =
        Change(
            cursor = Cursor.next(),
            entityType = persistence.model.EntityType.Producer,
            entityId = producer.producerId.id,
            scopeKey = SyncScope.ProducerAccount(producer.producerAccountId.id).key,
            op = ChangeOp.UPSERT,
            payload = ProducerPayload(producer),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildOwnerChange(owner: Owner): Change =
        Change(
            cursor = Cursor.next(),
            entityType = persistence.model.EntityType.Owner,
            entityId = owner.ownerId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = persistence.changes.OwnerPayload(owner),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildOwnerInvitationChange(invitation: persistence.model.OwnerInvitation): Change =
        Change(
            cursor = Cursor.next(),
            entityType = persistence.model.EntityType.OwnerInvitation,
            entityId = invitation.invitationId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = persistence.changes.OwnerInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
        )

    /**
     * Moves every reference to the [imported] member onto [activated] (its new `memberId == sub`),
     * then removes the imported row. The new row is written first so the member is never missing.
     */
    private suspend fun rekeyImportedMember(
        imported: Member,
        activated: Member,
    ) {
        val organizationId = imported.organizationId
        val scopeKey = SyncScope.Organization(organizationId.id).key
        val from = imported.memberId
        val to = activated.memberId
        organizationSyncDAO.getById(organizationId)?.let { organization ->
            val rewritten = organization.withMemberIdReplaced(from, to)
            if (rewritten !== organization) {
                organizationSyncDAO.put(
                    rewritten,
                    upsertChange(EntityType.Organization, organizationId.id, scopeKey, OrganizationPayload(rewritten)),
                )
            }
        }
        contractSyncDAO.getByOrganizationId(organizationId).forEach { contract ->
            val rewritten = contract.withMemberIdReplaced(from, to)
            if (rewritten !== contract) {
                contractSyncDAO.put(
                    rewritten,
                    upsertChange(EntityType.Contract, rewritten.contractId.id, scopeKey, ContractPayload(rewritten)),
                )
            }
        }
        basketExchangeSyncDAO.getByOrganizationId(organizationId).forEach { exchange ->
            val rewritten = exchange.withMemberIdReplaced(from, to)
            if (rewritten !== exchange) {
                basketExchangeSyncDAO.put(
                    rewritten,
                    upsertChange(
                        EntityType.BasketExchange,
                        rewritten.basketExchangeId.id,
                        scopeKey,
                        BasketExchangePayload(rewritten),
                    ),
                )
            }
        }
        memberSyncDAO.delete(
            from,
            organizationId,
            listOf(scopeKey, SyncScope.InstanceOwner.key).map { key ->
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.Member,
                    entityId = from.id,
                    scopeKey = key,
                    op = ChangeOp.DELETE,
                    payload = null,
                    producedAt = System.currentTimeMillis(),
                )
            },
        )
    }

    private fun upsertChange(
        entityType: EntityType,
        entityId: String,
        scopeKey: String,
        payload: EntityPayload,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = entityType,
            entityId = entityId,
            scopeKey = scopeKey,
            op = ChangeOp.UPSERT,
            payload = payload,
            producedAt = System.currentTimeMillis(),
        )

    private fun buildMemberChanges(member: Member): List<Change> =
        listOf(
            Change(
                cursor = Cursor.next(),
                entityType = persistence.model.EntityType.Member,
                entityId = member.memberId.id,
                scopeKey = SyncScope.Organization(member.organizationId.id).key,
                op = ChangeOp.UPSERT,
                payload = MemberPayload(member),
                producedAt = System.currentTimeMillis(),
            ),
            Change(
                cursor = Cursor.next(),
                entityType = persistence.model.EntityType.Member,
                entityId = member.memberId.id,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.UPSERT,
                payload = MemberPayload(member),
                producedAt = System.currentTimeMillis(),
            ),
        )

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

sealed class ActivationOutcome {
    data class Success(
        val response: ActivateResponse,
    ) : ActivationOutcome()

    object NotFound : ActivationOutcome()

    object Expired : ActivationOutcome()

    object AlreadyActivated : ActivationOutcome()
}

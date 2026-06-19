@file:OptIn(ExperimentalTime::class)

package activation

import authentication.Role
import core.UserProvisioningPort
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberPayload
import persistence.changes.ProducerPayload
import persistence.changes.SyncScope
import persistence.dao.ActivationTokenDAO
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
import persistence.model.AccessibilityOptions
import persistence.model.AccountStatus
import persistence.model.ActivateResponse
import persistence.model.ActivationKind
import persistence.model.DeliveryReminders
import persistence.model.Member
import persistence.model.MemberAccountStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberPreferences
import persistence.model.MemberSettings
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
) {
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
                        activeStatus = true,
                        firstName = request.adminFirstName,
                        lastName = request.adminLastName,
                        email = activationToken.adminEmail,
                        accountStatus = MemberAccountStatus.ACTIVE,
                        memberSettings =
                            MemberSettings(
                                deliveryReminders = DeliveryReminders(daysBefore = 1, reminderTime = "08:00"),
                                accessibilityOptions = AccessibilityOptions(false, false, false),
                                lastUpdatedInstant = now,
                            ),
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
                // memberId == sub: the auth subject is used directly as the member id.
                val member =
                    Member(
                        memberId = sub.toId(),
                        organizationId = invitation.organizationId,
                        roles = invitation.roles,
                        activeStatus = true,
                        firstName = invitation.firstName,
                        lastName = invitation.lastName,
                        email = invitation.email,
                        accountStatus = MemberAccountStatus.ACTIVE,
                        memberSettings =
                            MemberSettings(
                                deliveryReminders = DeliveryReminders(daysBefore = 1, reminderTime = "08:00"),
                                accessibilityOptions = AccessibilityOptions(false, false, false),
                                lastUpdatedInstant = now,
                            ),
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

                val updatedInvitation =
                    invitation.copy(
                        status = MemberInvitationStatus.ACTIVATED,
                        activatedAt = now,
                    )
                memberInvitationDAO.put(updatedInvitation, buildMemberInvitationChange(updatedInvitation))
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

    private fun buildMemberInvitationChange(invitation: MemberInvitation): Change =
        Change(
            cursor = Cursor.next(),
            entityType = persistence.model.EntityType.MemberInvitation,
            entityId = invitation.invitationId,
            scopeKey = SyncScope.Organization(invitation.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = persistence.changes.MemberInvitationPayload(invitation),
            producedAt = System.currentTimeMillis(),
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

@file:OptIn(ExperimentalTime::class)

package onboarding

import authentication.Role
import email.MemberJoinRequestNotificationEmailPort
import email.OrganizationRequestNotificationEmailPort
import email.ProducerRequestNotificationEmailPort
import id.Id
import id.generateId
import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import notificationpublisher.NotificationPublisher
import notificationpublisher.resolveCopy
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.OrganizationRequestPayload
import persistence.changes.ProducerRequestPayload
import persistence.changes.SyncScope
import persistence.dao.MemberJoinRequestDAO
import persistence.dao.MemberJoinRequestSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationDAO
import persistence.dao.OrganizationRequestDAO
import persistence.dao.OrganizationRequestSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.dao.OwnerSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.dao.ProducerRequestDAO
import persistence.dao.ProducerRequestSyncDAO
import persistence.dao.ServerDAO
import persistence.model.AccountStatus
import persistence.model.CreateMemberJoinRequestBody
import persistence.model.CreateOrganizationRequestBody
import persistence.model.CreateProducerRequestBody
import persistence.model.EntityType
import persistence.model.MemberAccountStatus
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestCreated
import persistence.model.MemberJoinRequestStatus
import persistence.model.NotificationCategory
import persistence.model.NotificationChannel
import persistence.model.NotificationType
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestCreated
import persistence.model.OrganizationRequestStatus
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestCreated
import persistence.model.ProducerRequestStatus
import persistence.model.PublicOrganizationSummary
import persistence.model.Server
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@Single(createdAtStart = true)
class PublicService(
    private val organizationDAO: OrganizationDAO,
    private val serverDAO: ServerDAO,
    private val organizationRequestDAO: OrganizationRequestDAO,
    private val organizationRequestSyncDAO: OrganizationRequestSyncDAO,
    private val producerRequestDAO: ProducerRequestDAO,
    private val producerRequestSyncDAO: ProducerRequestSyncDAO,
    private val memberJoinRequestDAO: MemberJoinRequestDAO,
    private val memberJoinRequestSyncDAO: MemberJoinRequestSyncDAO,
    private val memberJoinRequestNotificationEmailPort: MemberJoinRequestNotificationEmailPort,
    private val organizationRequestNotificationEmailPort: OrganizationRequestNotificationEmailPort,
    private val producerRequestNotificationEmailPort: ProducerRequestNotificationEmailPort,
    private val notificationPublisher: NotificationPublisher,
    private val ownerDAO: OwnerSyncDAO,
    private val memberSyncDAO: MemberSyncDAO,
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
    private val organizationSyncDAO: OrganizationSyncDAO,
) {
    suspend fun listActiveOrganizations(): List<PublicOrganizationSummary> = organizationDAO.listActive()

    suspend fun listServers(): List<Server> = serverDAO.list()

    suspend fun createOrganizationRequest(body: CreateOrganizationRequestBody): CreateOrganizationOutcome {
        val orgNameConflict =
            organizationRequestDAO.existsByOrganizationName(
                body.organizationName,
                excludedStatuses = setOf(OrganizationRequestStatus.REJECTED),
            )
        if (orgNameConflict != null) return CreateOrganizationOutcome.Conflict("organization_name", orgNameConflict)

        val adminEmailConflict =
            organizationRequestDAO.existsByAdminEmail(
                body.adminEmail,
                excludedStatuses = setOf(OrganizationRequestStatus.REJECTED),
            )
        if (adminEmailConflict != null) return CreateOrganizationOutcome.Conflict("admin_email", adminEmailConflict)
        val request =
            OrganizationRequest(
                requestId = generateId(),
                organizationName = body.organizationName,
                organizationType = body.organizationType,
                timezone = body.timezone,
                defaultLanguage = body.defaultLanguage,
                adminFirstName = body.adminFirstName,
                adminLastName = body.adminLastName,
                adminEmail = body.adminEmail,
                status = OrganizationRequestStatus.PENDING_VALIDATION,
                submittedAt = Clock.System.now(),
                submitterComment = body.submitterComment,
            )
        organizationRequestSyncDAO.put(request, buildChange(request))
        try {
            organizationRequestNotificationEmailPort.notifyOwners(request)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to notify owners for organization request ${request.requestId.id}" }
        }
        try {
            notifyAllOwners(
                category = NotificationCategory.ORGANIZATION_REQUEST_SUBMITTED,
                title = "Nouvelle demande de création d'AMAP",
                body = "Une demande de création d'AMAP a été soumise pour « ${request.organizationName} ».",
                relatedEntityId = request.requestId.id,
            )
        } catch (e: Exception) {
            logger.warn(e) { "Failed to fan-out in-app notifications for organization request ${request.requestId.id}" }
        }
        return CreateOrganizationOutcome.Success(OrganizationRequestCreated(request.requestId, request.status))
    }

    suspend fun createProducerRequest(body: CreateProducerRequestBody): CreateProducerOutcome {
        val producerNameConflict =
            producerRequestDAO.existsByProducerName(
                body.producerName,
                excludedStatuses = setOf(ProducerRequestStatus.REJECTED),
            )
        if (producerNameConflict != null) return CreateProducerOutcome.Conflict("producer_name", producerNameConflict)

        val adminEmailConflict =
            producerRequestDAO.existsByAdminEmail(
                body.adminEmail,
                excludedStatuses = setOf(ProducerRequestStatus.REJECTED),
            )
        if (adminEmailConflict != null) return CreateProducerOutcome.Conflict("admin_email", adminEmailConflict)
        val request =
            ProducerRequest(
                requestId = generateId(),
                producerName = body.producerName,
                adminFirstName = body.adminFirstName,
                adminLastName = body.adminLastName,
                adminEmail = body.adminEmail,
                status = ProducerRequestStatus.PENDING_VALIDATION,
                submittedAt = Clock.System.now(),
                submitterComment = body.submitterComment,
            )
        producerRequestSyncDAO.put(request, buildChange(request))
        try {
            producerRequestNotificationEmailPort.notifyOwners(request)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to notify owners for producer request ${request.requestId.id}" }
        }
        try {
            notifyAllOwners(
                category = NotificationCategory.PRODUCER_REQUEST_SUBMITTED,
                title = "Nouvelle demande de compte producteur",
                body = "Une demande de compte producteur a été soumise pour « ${request.producerName} ».",
                relatedEntityId = request.requestId.id,
            )
        } catch (e: Exception) {
            logger.warn(e) { "Failed to fan-out in-app notifications for producer request ${request.requestId.id}" }
        }
        return CreateProducerOutcome.Success(ProducerRequestCreated(request.requestId, request.status))
    }

    suspend fun createMemberJoinRequest(body: CreateMemberJoinRequestBody): CreateMemberJoinOutcome {
        val organizationId = body.organizationId.toId<Organization>()
        if (memberSyncDAO.listAll().any {
                it.email.equals(
                    body.email,
                    ignoreCase = true,
                ) && it.accountStatus == MemberAccountStatus.ACTIVE
            }
        ) {
            return CreateMemberJoinOutcome.Conflict("email_member")
        }
        if (ownerDAO.existsByEmail(body.email)) {
            return CreateMemberJoinOutcome.Conflict("email_owner")
        }
        if (producerAccountSyncDAO.listAll().any { it.contactEmail?.equals(body.email, ignoreCase = true) == true && it.activeStatus }) {
            return CreateMemberJoinOutcome.Conflict("email_producer")
        }
        if (memberJoinRequestDAO.existsPendingByEmailAndOrganization(body.email, organizationId)) {
            return CreateMemberJoinOutcome.Conflict("email")
        }
        val request =
            MemberJoinRequest(
                requestId = generateId(),
                organizationId = organizationId,
                email = body.email,
                firstName = body.firstName,
                lastName = body.lastName,
                status = MemberJoinRequestStatus.PENDING,
                submittedAt = Clock.System.now(),
            )
        memberJoinRequestSyncDAO.put(request, buildChange(request))
        try {
            memberJoinRequestNotificationEmailPort.notifyAdmins(
                request,
                organizationSyncDAO.getById(request.organizationId)?.name,
            )
        } catch (e: Exception) {
            logger.warn(e) { "Failed to notify admins for member join request ${request.requestId.id}" }
        }
        try {
            notifyAdmins(
                organizationId = request.organizationId,
                category = NotificationCategory.MEMBER_JOIN_REQUEST_SUBMITTED,
                defaultTitle = "Nouvelle demande d'adhésion",
                defaultBody = "Une demande d'adhésion de ${request.firstName} ${request.lastName} est en attente.",
                relatedEntityId = request.requestId.id,
            )
        } catch (e: Exception) {
            logger.warn(e) { "Failed to fan-out in-app notifications for member join request ${request.requestId.id}" }
        }
        return CreateMemberJoinOutcome.Success(MemberJoinRequestCreated(request.requestId, request.status))
    }

    private suspend fun notifyAllOwners(
        category: NotificationCategory,
        title: String,
        body: String,
        relatedEntityId: String,
    ) {
        ownerDAO
            .listAll()
            .filter { it.accountStatus == AccountStatus.ACTIVE }
            .forEach { owner ->
                runCatching {
                    notificationPublisher.publish(
                        recipientScope = SyncScope.Owner(owner.ownerId.id).key,
                        type = NotificationType.INFO,
                        category = category,
                        title = title,
                        body = body,
                        relatedEntityId = relatedEntityId,
                        channels = if (owner.userPreferences.pushNotificationsEnabled) setOf(NotificationChannel.PUSH) else emptySet(),
                    )
                }.onFailure { logger.warn(it) { "Failed to notify owner ${owner.ownerId.id} — $category" } }
            }
    }

    private suspend fun notifyAdmins(
        organizationId: Id<Organization>,
        category: NotificationCategory,
        defaultTitle: String,
        defaultBody: String,
        relatedEntityId: String,
    ) {
        val overrides = organizationSyncDAO.getById(organizationId)?.notificationOverrides ?: emptyMap()
        val copy = overrides.resolveCopy(category, defaultTitle, defaultBody)
        memberSyncDAO
            .getByOrganizationId(organizationId)
            .filter { it.activeStatus && Role.ADMIN in it.roles }
            .forEach { admin ->
                // memberId == sub by convention
                val sub = admin.memberId.id
                runCatching {
                    notificationPublisher.publish(
                        recipientScope = SyncScope.Member(sub).key,
                        type = NotificationType.INFO,
                        category = category,
                        title = copy.title,
                        body = copy.body,
                        relatedEntityId = relatedEntityId,
                        channels = if (admin.userPreferences.pushNotificationsEnabled) setOf(NotificationChannel.PUSH) else emptySet(),
                    )
                }.onFailure { logger.warn(it) { "Failed to notify admin ${admin.memberId.id} — $category" } }
            }
    }

    private fun buildChange(request: MemberJoinRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.MemberJoinRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.Organization(request.organizationId.id).key,
            op = ChangeOp.UPSERT,
            payload = MemberJoinRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildChange(request: OrganizationRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.OrganizationRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = OrganizationRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildChange(request: ProducerRequest): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProducerRequest,
            entityId = request.requestId.id,
            scopeKey = SyncScope.InstanceOwner.key,
            op = ChangeOp.UPSERT,
            payload = ProducerRequestPayload(request),
            producedAt = System.currentTimeMillis(),
        )

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

sealed class CreateOrganizationOutcome {
    data class Success(
        val result: OrganizationRequestCreated,
    ) : CreateOrganizationOutcome()

    data class Conflict(
        val field: String,
        val existingStatus: OrganizationRequestStatus,
    ) : CreateOrganizationOutcome()
}

sealed class CreateMemberJoinOutcome {
    data class Success(
        val result: MemberJoinRequestCreated,
    ) : CreateMemberJoinOutcome()

    data class Conflict(
        val field: String,
    ) : CreateMemberJoinOutcome()
}

sealed class CreateProducerOutcome {
    data class Success(
        val result: ProducerRequestCreated,
    ) : CreateProducerOutcome()

    data class Conflict(
        val field: String,
        val existingStatus: ProducerRequestStatus,
    ) : CreateProducerOutcome()
}

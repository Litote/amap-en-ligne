@file:OptIn(ExperimentalTime::class)

package email

import authentication.Role
import id.toId
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.model.ActivityType
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberJoinRequest
import persistence.model.MemberJoinRequestStatus
import persistence.model.MemberRegistration
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OrganizationRequestStatus
import persistence.model.OrganizationType
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import persistence.model.ProducerRequest
import persistence.model.ProducerRequestStatus
import persistence.model.RegistrationStatus
import persistence.model.SlotKind
import persistence.model.SlotStatus
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class EmailTemplatesTest {
    private val expiresAt = Instant.fromEpochMilliseconds(1_700_000_000_000)
    private val createdAt = Instant.fromEpochMilliseconds(1_699_000_000_000)

    @Test
    fun `GIVEN organization activation WHEN rendered THEN subject names the org and body carries the link`() {
        val content =
            EmailTemplates.organizationActivation(
                request = organizationRequest(),
                activationUrl = "https://amap.example/activate?token=tok-1",
                expiresAt = expiresAt,
            )
        assertContains(content.subject, "AMAP des Collines")
        assertContains(content.body, "https://amap.example/activate?token=tok-1")
        assertContains(content.body, "Jean Dupont")
    }

    @Test
    fun `GIVEN expiry instant WHEN rendered THEN date is human-readable French with minute precision`() {
        // 1_700_000_000_000 ms = 2023-11-14T22:13:20Z = 2023-11-14T23h13 (Europe/Paris, CET = UTC+1)
        val content =
            EmailTemplates.organizationActivation(
                request = organizationRequest(),
                activationUrl = "https://amap.example/activate?token=tok-date",
                expiresAt = expiresAt,
            )
        assertContains(content.body, "14 novembre 2023 à 23h13")
    }

    @Test
    fun `GIVEN member invitation WHEN rendered THEN body carries the activation link`() {
        val content =
            EmailTemplates.memberInvitation(
                invitation = memberInvitation(),
                activationUrl = "https://amap.example/activate?token=tok-2",
                expiresAt = expiresAt,
            )
        assertContains(content.body, "https://amap.example/activate?token=tok-2")
        assertContains(content.body, "Marie Martin")
    }

    @Test
    fun `GIVEN an organization name WHEN amapEmailSubject THEN the subject is prefixed with the AMAP name`() {
        assertEquals("[Ma Super AMAP] Coucou", amapEmailSubject("Ma Super AMAP", "Coucou"))
    }

    @Test
    fun `GIVEN a null or blank organization name WHEN amapEmailSubject THEN the subject is unchanged`() {
        assertEquals("Coucou", amapEmailSubject(null, "Coucou"))
        assertEquals("Coucou", amapEmailSubject("   ", "Coucou"))
    }

    @Test
    fun `GIVEN instance-level templates WHEN rendered THEN subjects are left unprefixed for the gateway to brand`() {
        // Instance-level templates intentionally do NOT carry a [..] prefix: the deployment
        // gateway adds [AmapEnLigne] only when the subject is not already bracket-prefixed.
        assertFalse(EmailTemplates.ownerActivation(ownerInvitation(), "https://x", expiresAt).subject.startsWith("["))
        assertFalse(EmailTemplates.producerActivation(producerRequest(), "https://x", expiresAt).subject.startsWith("["))
    }

    @Test
    fun `GIVEN member invitation with an organization name WHEN rendered THEN the subject is prefixed`() {
        val content =
            EmailTemplates.memberInvitation(
                invitation = memberInvitation(),
                activationUrl = "https://amap.example/activate?token=tok-x",
                expiresAt = expiresAt,
                organizationName = "AMAP des Collines",
            )
        assertEquals("[AMAP des Collines] Invitation à rejoindre votre AMAP", content.subject)
    }

    @Test
    fun `GIVEN a custom subject and an organization name WHEN rendered THEN the prefix wraps the custom subject`() {
        val content =
            EmailTemplates.memberInvitation(
                invitation = memberInvitation().copy(customEmailSubject = "Connecte-toi"),
                activationUrl = "https://amap.example/activate?token=tok-y",
                expiresAt = expiresAt,
                organizationName = "AMAP des Collines",
            )
        assertEquals("[AMAP des Collines] Connecte-toi", content.subject)
    }

    @Test
    fun `GIVEN member invitation with custom subject and body WHEN rendered THEN custom copy is used but the activation link is kept`() {
        val content =
            EmailTemplates.memberInvitation(
                invitation =
                    memberInvitation().copy(
                        customEmailSubject = "Rejoins-nous !",
                        customEmailBody = "Salut, connecte-toi pour finaliser ton inscription.",
                    ),
                activationUrl = "https://amap.example/activate?token=tok-3",
                expiresAt = expiresAt,
            )
        assertEquals("Rejoins-nous !", content.subject)
        assertContains(content.body, "Salut, connecte-toi pour finaliser ton inscription.")
        // The default intro is replaced...
        assertTrue(!content.body.contains("Vous avez été invité(e) à rejoindre votre AMAP"))
        // ...but the activation link footer is always appended.
        assertContains(content.body, "https://amap.example/activate?token=tok-3")
    }

    @Test
    fun `GIVEN member invitation with blank custom fields WHEN rendered THEN falls back to default copy`() {
        val content =
            EmailTemplates.memberInvitation(
                invitation = memberInvitation().copy(customEmailSubject = "  ", customEmailBody = ""),
                activationUrl = "https://amap.example/activate?token=tok-4",
                expiresAt = expiresAt,
            )
        assertEquals("Invitation à rejoindre votre AMAP", content.subject)
        assertContains(content.body, "Vous avez été invité(e) à rejoindre votre AMAP")
    }

    @Test
    fun `GIVEN owner activation WHEN rendered THEN body carries the activation link`() {
        val content =
            EmailTemplates.ownerActivation(
                invitation = ownerInvitation(),
                activationUrl = "https://amap.example/activate?token=tok-3",
                expiresAt = expiresAt,
            )
        assertContains(content.body, "https://amap.example/activate?token=tok-3")
        assertContains(content.body, "Alice Bernard")
    }

    @Test
    fun `GIVEN producer activation WHEN rendered THEN body carries the activation link and producer name`() {
        val content =
            EmailTemplates.producerActivation(
                request = producerRequest(),
                activationUrl = "https://amap.example/activate?token=tok-4",
                expiresAt = expiresAt,
            )
        assertContains(content.body, "https://amap.example/activate?token=tok-4")
        assertContains(content.body, "Ferme des Lilas")
    }

    @Test
    fun `GIVEN a rejection with a comment WHEN rendered THEN the comment appears as a motif`() {
        val content = EmailTemplates.organizationRequestRejected(organizationRequest(), "Nom déjà utilisé")
        assertContains(content.body, "Motif : Nom déjà utilisé")
    }

    @Test
    fun `GIVEN a rejection without a comment WHEN rendered THEN no motif line is added`() {
        val content = EmailTemplates.organizationRequestRejected(organizationRequest(), null)
        assertFalse(content.body.contains("Motif :"))
    }

    @Test
    fun `GIVEN member join request rejection WHEN rendered THEN it addresses the requester`() {
        val content = EmailTemplates.memberJoinRequestRejected(memberJoinRequest())
        assertContains(content.body, "Paul Durand")
    }

    @Test
    fun `GIVEN account lifecycle events WHEN rendered THEN subjects describe the action`() {
        val target =
            AccountLifecycleTarget(
                sub = "sub-1",
                email = "user@example.org",
                firstName = "Léa",
                lastName = "Petit",
                role = AccountLifecycleRole.AMAP_MEMBER,
            )
        assertContains(EmailTemplates.accountSuspended(target).subject, "suspendu")
        assertContains(EmailTemplates.accountReactivated(target).subject, "réactivé")
        assertContains(EmailTemplates.accountDeleted(target).subject, "supprimé")
        assertContains(EmailTemplates.accountSuspended(target).body, "Léa Petit")
    }

    @Test
    fun `GIVEN basket exchange notifications WHEN rendered THEN they address the right recipient`() {
        val offerer = MemberSummary("m-1", "Sophie", "Roux", "sophie@example.org")
        val requester = MemberSummary("m-2", "Tom", "Klein", "tom@example.org")

        assertContains(EmailTemplates.basketExchangeRequestReceived(offerer, requester).body, "Sophie Roux")
        assertContains(EmailTemplates.basketExchangeRequestReceived(offerer, requester).body, "Tom Klein")
        assertContains(EmailTemplates.basketExchangeAccepted(requester).body, "Tom Klein")
        assertTrue(EmailTemplates.basketExchangeRejected(requester).subject.isNotBlank())
    }

    @Test
    fun `GIVEN a submitted join request WHEN rendered THEN admins see the requester identity`() {
        val content = EmailTemplates.memberJoinRequestSubmitted(memberJoinRequest())
        assertContains(content.body, "Paul Durand")
        assertContains(content.body, "paul@example.org")
    }

    @Test
    fun `GIVEN a submitted organization request WHEN rendered THEN owners see the org name and submitter`() {
        val content = EmailTemplates.organizationRequestSubmitted(organizationRequest())
        assertContains(content.subject, "organisation")
        assertContains(content.body, "AMAP des Collines")
        assertContains(content.body, "Jean Dupont")
        assertContains(content.body, "jean@example.org")
    }

    @Test
    fun `GIVEN a submitted producer request WHEN rendered THEN owners see the producer name and submitter`() {
        val content = EmailTemplates.producerRequestSubmitted(producerRequest())
        assertContains(content.subject, "producteur")
        assertContains(content.body, "Ferme des Lilas")
        assertContains(content.body, "Luc Moreau")
        assertContains(content.body, "luc@example.org")
    }

    @Test
    fun `GIVEN delivery with volunteers WHEN attendanceSheets rendered THEN names org and lists volunteers`() {
        val org = buildOrganization()
        val delivery = buildDeliveryWithVolunteer()
        val content = EmailTemplates.attendanceSheets(org, delivery)

        assertContains(content.subject, "AMAP des Collines")
        assertContains(content.body, "AMAP des Collines")
        assertContains(content.body, "Claire Brun")
        assertContains(content.body, "claire@example.org")
        assertContains(content.body, "Légumes bio")
    }

    @Test
    fun `GIVEN delivery with no volunteers WHEN attendanceSheets rendered THEN body says no volunteers`() {
        val delivery = buildDeliveryWithVolunteer().copy(contracts = emptyList())
        val content = EmailTemplates.attendanceSheets(buildOrganization(), delivery)
        assertContains(content.body, "Aucun bénévole inscrit")
    }

    @Test
    fun `GIVEN confirmed exchange on the delivery WHEN attendanceSheets rendered THEN it lists the basket pickup`() {
        val delivery = buildDeliveryWithVolunteer()
        // Confirmed exchange whose offered delivery is this delivery (dlv-1):
        // the offerer m-owner's basket is collected by the requester m-taker.
        val exchange =
            BasketExchange(
                basketExchangeId = "be-1".toId(),
                organizationId = "org-1".toId(),
                deliveryId = "dlv-1".toId(),
                contractId = "c-1".toId(),
                offeringMemberId = "m-owner".toId(),
                status = BasketExchangeStatus.ACCEPTED,
                createdAt = createdAt,
                acceptedRequestId = "r-1".toId(),
                requests =
                    listOf(
                        BasketExchangeRequest(
                            requestId = "r-1".toId(),
                            requesterMemberId = "m-taker".toId(),
                            createdAt = createdAt,
                            status = BasketExchangeRequestStatus.ACCEPTED,
                            proposedDeliveryId = "dlv-2".toId(),
                        ),
                    ),
            )

        val content =
            EmailTemplates.attendanceSheets(
                buildOrganization(),
                delivery,
                basketExchanges = listOf(exchange),
            )

        assertContains(content.body, "ÉCHANGES DE PANIERS")
        assertContains(content.body, "à remettre à")
        assertContains(content.body, "m-owner")
        assertContains(content.body, "m-taker")
    }

    @Test
    fun `GIVEN owners broadcast WHEN rendered THEN it carries event and actor but no impacted identity`() {
        val content =
            EmailTemplates.ownersLifecycleBroadcast(
                event = OwnersBroadcastEvent.ACCOUNT_DELETED,
                actorOwnerEmail = "owner@example.org",
                impactedRole = AccountLifecycleRole.PRODUCER,
            )
        assertContains(content.body, "supprimé")
        assertContains(content.body, "producteur")
        assertContains(content.body, "owner@example.org")
    }

    private fun organizationRequest() =
        OrganizationRequest(
            requestId = "req-1".toId(),
            organizationName = "AMAP des Collines",
            organizationType = OrganizationType.AMAP,
            timezone = TimeZone.UTC,
            defaultLanguage = "fr",
            adminFirstName = "Jean",
            adminLastName = "Dupont",
            adminEmail = "jean@example.org",
            status = OrganizationRequestStatus.APPROVED,
            submittedAt = createdAt,
        )

    private fun memberInvitation() =
        MemberInvitation(
            invitationId = "inv-1",
            organizationId = "org-1".toId(),
            email = "marie@example.org",
            firstName = "Marie",
            lastName = "Martin",
            roles = setOf(Role.VOLUNTEER),
            status = MemberInvitationStatus.PENDING_ACTIVATION,
            createdAt = createdAt,
            expiresAt = expiresAt,
        )

    private fun ownerInvitation() =
        OwnerInvitation(
            invitationId = "oinv-1".toId(),
            firstName = "Alice",
            lastName = "Bernard",
            email = "alice@example.org",
            status = OwnerInvitationStatus.PENDING_ACTIVATION,
            submittedAt = createdAt,
        )

    private fun producerRequest() =
        ProducerRequest(
            requestId = "preq-1".toId(),
            producerName = "Ferme des Lilas",
            adminFirstName = "Luc",
            adminLastName = "Moreau",
            adminEmail = "luc@example.org",
            status = ProducerRequestStatus.APPROVED,
            submittedAt = createdAt,
        )

    private fun memberJoinRequest() =
        MemberJoinRequest(
            requestId = "mjr-1".toId(),
            organizationId = "org-1".toId(),
            email = "paul@example.org",
            firstName = "Paul",
            lastName = "Durand",
            status = MemberJoinRequestStatus.REJECTED,
            submittedAt = createdAt,
            reviewComment = "Liste d'attente complète",
        )

    private fun buildOrganization() =
        Organization(
            organizationId = "org-1".toId(),
            name = "AMAP des Collines",
            contactEmail = "amap@example.org",
            activeStatus = true,
            timezone = TimeZone.UTC,
            defaultLanguage = "fr",
            createdInstant = createdAt,
            lastUpdatedInstant = createdAt,
        )

    private fun buildDeliveryWithVolunteer() =
        Delivery(
            deliveryId = "dlv-1".toId(),
            organizationId = "org-1".toId(),
            scheduledDate = LocalDateTime(2025, 1, 17, 18, 0),
            status = DeliveryStatus.CONFIRMED,
            minVolunteersRequired = 2,
            contracts =
                listOf(
                    DeliveryContract(
                        contractId = "c-1".toId(),
                        basketQuantity = 25,
                        deliveryDescription = "Légumes bio",
                        status = DeliveryContractStatus.PENDING,
                        slots =
                            listOf(
                                MemberSlot(
                                    startTime = LocalDateTime(2025, 1, 17, 18, 0),
                                    endTime = LocalDateTime(2025, 1, 17, 20, 0),
                                    activityType = ActivityType.DISTRIBUTION,
                                    requiredVolunteers = 2,
                                    currentRegistrations = 1,
                                    status = SlotStatus.OPEN,
                                    slotKind = SlotKind.STANDARD,
                                    registrations =
                                        listOf(
                                            MemberRegistration(
                                                memberId = "m-1".toId(),
                                                displayName = "Claire Brun",
                                                memberEmail = "claire@example.org",
                                                registrationInstant = createdAt,
                                                status = RegistrationStatus.CONFIRMED,
                                            ),
                                        ),
                                ),
                            ),
                    ),
                ),
        )
}

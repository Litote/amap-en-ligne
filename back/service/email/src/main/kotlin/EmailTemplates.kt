@file:OptIn(ExperimentalTime::class)

package email

import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.format.MonthNames
import kotlinx.datetime.format.char
import kotlinx.datetime.toLocalDateTime
import persistence.model.BasketExchange
import persistence.model.BasketExchangeStatus
import persistence.model.Delivery
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberJoinRequest
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OwnerInvitation
import persistence.model.ProducerRequest
import persistence.model.RegistrationStatus
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/** Subject + plain-text body of a transactional email, before a recipient is attached. */
data class EmailContent(
    val subject: String,
    val body: String,
)

/**
 * Prefixes an AMAP-scoped email subject with the organization name, e.g.
 * `[Ma Super AMAP] Invitation à rejoindre votre AMAP`. A null/blank name leaves
 * the subject unchanged (used for instance-level emails with no owning AMAP).
 */
fun amapEmailSubject(
    organizationName: String?,
    subject: String,
): String = organizationName?.takeIf { it.isNotBlank() }?.let { "[$it] $subject" } ?: subject

/**
 * Pure French templates for the transactional emails. Kept free of any
 * AWS/SMTP/IO dependency so they can be unit-tested directly (see
 * `EmailTemplatesTest`) and **shared by both deployments**: `deploy:lambda`
 * publishes the rendered content onto SNS (→ SES), `deploy:jvm` hands it to the
 * SMTP `EmailSender.sendNotificationEmail`. Recipient is attached by each
 * adapter.
 */
object EmailTemplates {
    private const val SIGNATURE = "\n\nCordialement,\nL'équipe AMAP en ligne"
    private const val GREETING = "Bonjour,\n\n"
    private const val ADMIN_REVIEW_PROMPT = "Connectez-vous à l'espace d'administration pour l'examiner."

    private val FRENCH_DATE_TIME_FORMAT =
        LocalDateTime.Format {
            day()
            char(' ')
            monthName(
                MonthNames(
                    listOf(
                        "janvier",
                        "février",
                        "mars",
                        "avril",
                        "mai",
                        "juin",
                        "juillet",
                        "août",
                        "septembre",
                        "octobre",
                        "novembre",
                        "décembre",
                    ),
                ),
            )
            char(' ')
            year()
            chars(" à ")
            hour()
            char('h')
            minute()
        }

    private fun Instant.toFrenchDateTime(): String = FRENCH_DATE_TIME_FORMAT.format(toLocalDateTime(TimeZone.of("Europe/Paris")))

    private fun activationFooter(
        activationUrl: String,
        expiresAt: Instant,
    ): String =
        "Pour activer votre compte, cliquez sur le lien ci-dessous :\n" +
            "$activationUrl\n\n" +
            "Ce lien est valable jusqu'au ${expiresAt.toFrenchDateTime()}.\n\n" +
            "Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail."

    fun organizationActivation(
        request: OrganizationRequest,
        activationUrl: String,
        expiresAt: Instant,
    ): EmailContent =
        EmailContent(
            subject = "Activez votre compte ${request.organizationName}",
            body =
                "Bonjour ${request.adminFirstName} ${request.adminLastName},\n\n" +
                    "Votre demande de création de l'organisation « ${request.organizationName} » a été approuvée.\n\n" +
                    activationFooter(activationUrl, expiresAt) +
                    SIGNATURE,
        )

    /**
     * Variant used by [ActivationEmailCronJob] which fetches only the primitive fields
     * from the DB (not a full [OrganizationRequest] object).
     */
    fun organizationActivationForCronJob(
        adminFirstName: String,
        adminLastName: String,
        organizationName: String,
        activationUrl: String,
        expiresAt: Instant,
    ): EmailContent =
        EmailContent(
            subject = "Activez votre compte $organizationName",
            body =
                "Bonjour $adminFirstName $adminLastName,\n\n" +
                    "Votre demande de création de l'organisation « $organizationName » a été approuvée.\n\n" +
                    activationFooter(activationUrl, expiresAt) +
                    SIGNATURE,
        )

    fun memberInvitation(
        invitation: MemberInvitation,
        activationUrl: String,
        expiresAt: Instant,
        organizationName: String? = null,
    ): EmailContent {
        val baseSubject = invitation.customEmailSubject?.takeIf { it.isNotBlank() } ?: "Invitation à rejoindre votre AMAP"
        val subject = amapEmailSubject(organizationName, baseSubject)
        val intro =
            invitation.customEmailBody?.takeIf { it.isNotBlank() }
                ?: (
                    "Bonjour ${invitation.firstName} ${invitation.lastName},\n\n" +
                        "Vous avez été invité(e) à rejoindre votre AMAP sur l'application AmapEnLigne."
                )
        // The activation link footer + signature are always appended so the link is never droppable.
        return EmailContent(
            subject = subject,
            body = intro + "\n\n" + activationFooter(activationUrl, expiresAt) + SIGNATURE,
        )
    }

    fun ownerActivation(
        invitation: OwnerInvitation,
        activationUrl: String,
        expiresAt: Instant,
    ): EmailContent =
        EmailContent(
            subject = "Activez votre compte administrateur d'instance",
            body =
                "Bonjour ${invitation.firstName} ${invitation.lastName},\n\n" +
                    "Vous avez été invité(e) à devenir administrateur de l'instance AmapEnLigne.\n\n" +
                    activationFooter(activationUrl, expiresAt) +
                    SIGNATURE,
        )

    fun producerActivation(
        request: ProducerRequest,
        activationUrl: String,
        expiresAt: Instant,
    ): EmailContent =
        EmailContent(
            subject = "Activez votre compte producteur",
            body =
                "Bonjour ${request.adminFirstName} ${request.adminLastName},\n\n" +
                    "Votre demande de compte producteur « ${request.producerName} » a été approuvée.\n\n" +
                    activationFooter(activationUrl, expiresAt) +
                    SIGNATURE,
        )

    fun organizationRequestRejected(
        request: OrganizationRequest,
        reviewComment: String?,
    ): EmailContent =
        EmailContent(
            subject = "Votre demande de création d'organisation",
            body =
                "Bonjour ${request.adminFirstName} ${request.adminLastName},\n\n" +
                    "Votre demande de création de l'organisation « ${request.organizationName} » n'a pas pu être acceptée.\n" +
                    rejectionReason(reviewComment) +
                    SIGNATURE,
        )

    fun producerRequestRejected(
        request: ProducerRequest,
        reviewComment: String?,
    ): EmailContent =
        EmailContent(
            subject = "Votre demande de compte producteur",
            body =
                "Bonjour ${request.adminFirstName} ${request.adminLastName},\n\n" +
                    "Votre demande de compte producteur « ${request.producerName} » n'a pas pu être acceptée.\n" +
                    rejectionReason(reviewComment) +
                    SIGNATURE,
        )

    fun memberJoinRequestRejected(
        request: MemberJoinRequest,
        organizationName: String? = null,
    ): EmailContent =
        EmailContent(
            subject = amapEmailSubject(organizationName, "Votre demande d'adhésion"),
            body =
                "Bonjour ${request.firstName} ${request.lastName},\n\n" +
                    "Votre demande d'adhésion à l'AMAP n'a pas pu être acceptée.\n" +
                    rejectionReason(request.reviewComment) +
                    SIGNATURE,
        )

    /** Sent to the instance owners when a new organization creation request is submitted. */
    fun organizationRequestSubmitted(request: OrganizationRequest): EmailContent =
        EmailContent(
            subject = "Nouvelle demande de création d'organisation",
            body =
                GREETING +
                    "Une nouvelle demande de création d'organisation a été reçue :\n" +
                    "« ${request.organizationName} » soumise par " +
                    "${request.adminFirstName} ${request.adminLastName} (${request.adminEmail}).\n\n" +
                    ADMIN_REVIEW_PROMPT +
                    SIGNATURE,
        )

    /** Sent to the instance owners when a new producer account request is submitted. */
    fun producerRequestSubmitted(request: ProducerRequest): EmailContent =
        EmailContent(
            subject = "Nouvelle demande de compte producteur",
            body =
                GREETING +
                    "Une nouvelle demande de compte producteur a été reçue :\n" +
                    "« ${request.producerName} » soumise par " +
                    "${request.adminFirstName} ${request.adminLastName} (${request.adminEmail}).\n\n" +
                    ADMIN_REVIEW_PROMPT +
                    SIGNATURE,
        )

    /** Sent to the AMAP administrators when a new join request is submitted. */
    fun memberJoinRequestSubmitted(
        request: MemberJoinRequest,
        organizationName: String? = null,
    ): EmailContent =
        EmailContent(
            subject = amapEmailSubject(organizationName, "Nouvelle demande d'adhésion"),
            body =
                GREETING +
                    "Une nouvelle demande d'adhésion à votre AMAP a été reçue :\n" +
                    "${request.firstName} ${request.lastName} (${request.email}).\n\n" +
                    ADMIN_REVIEW_PROMPT +
                    SIGNATURE,
        )

    /**
     * PII-free audit notification sent to the *other* active instance owners when
     * an account lifecycle action occurs. Carries only the event, the impacted
     * role and the acting owner — never the impacted user's identity (RGPD).
     */
    fun ownersLifecycleBroadcast(
        event: OwnersBroadcastEvent,
        actorOwnerEmail: String,
        impactedRole: AccountLifecycleRole,
    ): EmailContent {
        val action =
            when (event) {
                OwnersBroadcastEvent.ACCOUNT_SUSPENDED -> "Un compte a été suspendu"
                OwnersBroadcastEvent.ACCOUNT_REACTIVATED -> "Un compte a été réactivé"
                OwnersBroadcastEvent.ACCOUNT_DELETED -> "Un compte a été supprimé"
            }
        val roleLabel =
            when (impactedRole) {
                AccountLifecycleRole.OWNER -> "administrateur d'instance"
                AccountLifecycleRole.PRODUCER -> "producteur"
                AccountLifecycleRole.AMAP_MEMBER -> "membre d'AMAP"
            }
        return EmailContent(
            subject = "Notification d'administration d'instance",
            body =
                GREETING +
                    "$action (rôle concerné : $roleLabel).\n" +
                    "Action effectuée par : $actorOwnerEmail.\n\n" +
                    "Cette notification est conservée à des fins d'audit." +
                    SIGNATURE,
        )
    }

    fun accountSuspended(target: AccountLifecycleTarget): EmailContent =
        EmailContent(
            subject = "Votre compte AMAP en ligne a été suspendu",
            body =
                "Bonjour ${target.firstName} ${target.lastName},\n\n" +
                    "Votre compte a été suspendu. Vous ne pouvez temporairement plus vous connecter.\n" +
                    "Si vous pensez qu'il s'agit d'une erreur, contactez votre administrateur." +
                    SIGNATURE,
        )

    fun accountReactivated(target: AccountLifecycleTarget): EmailContent =
        EmailContent(
            subject = "Votre compte AMAP en ligne a été réactivé",
            body =
                "Bonjour ${target.firstName} ${target.lastName},\n\n" +
                    "Votre compte a été réactivé. Vous pouvez de nouveau vous connecter." +
                    SIGNATURE,
        )

    fun accountDeleted(target: AccountLifecycleTarget): EmailContent =
        EmailContent(
            subject = "Votre compte AMAP en ligne a été supprimé",
            body =
                "Bonjour ${target.firstName} ${target.lastName},\n\n" +
                    "Votre compte a été supprimé conformément à votre demande ou à une décision d'administration.\n" +
                    "Vos données personnelles ont été anonymisées." +
                    SIGNATURE,
        )

    fun basketExchangeRequestReceived(
        offerer: MemberSummary,
        requester: MemberSummary,
        organizationName: String? = null,
    ): EmailContent =
        EmailContent(
            subject = amapEmailSubject(organizationName, "Nouvelle demande pour votre panier"),
            body =
                "Bonjour ${offerer.firstName} ${offerer.lastName},\n\n" +
                    "${requester.firstName} ${requester.lastName} souhaite récupérer le panier que vous proposez à l'échange.\n" +
                    "Connectez-vous à l'application pour accepter ou refuser cette demande." +
                    SIGNATURE,
        )

    fun basketExchangeAccepted(
        requester: MemberSummary,
        organizationName: String? = null,
    ): EmailContent =
        EmailContent(
            subject = amapEmailSubject(organizationName, "Votre demande d'échange a été acceptée"),
            body =
                "Bonjour ${requester.firstName} ${requester.lastName},\n\n" +
                    "Votre demande de récupération de panier a été acceptée. Vous pourrez le récupérer le jour de la livraison." +
                    SIGNATURE,
        )

    fun basketExchangeRejected(
        requester: MemberSummary,
        organizationName: String? = null,
    ): EmailContent =
        EmailContent(
            subject = amapEmailSubject(organizationName, "Votre demande d'échange n'a pas été retenue"),
            body =
                "Bonjour ${requester.firstName} ${requester.lastName},\n\n" +
                    "Votre demande de récupération de panier n'a pas été retenue cette fois-ci." +
                    SIGNATURE,
        )

    fun attendanceSheets(
        organization: Organization,
        delivery: Delivery,
        basketExchanges: List<BasketExchange> = emptyList(),
        members: List<Member> = emptyList(),
    ): EmailContent {
        val dateLabel = formatDeliveryDate(delivery.scheduledDate)
        val memberNames = members.associate { it.memberId.id to it.displayName() }
        val pickups = basketPickupsForDelivery(basketExchanges, delivery.deliveryId.id)
        val body =
            buildString {
                appendLine("Feuilles d'émargement — ${organization.name}")
                appendLine("Livraison : $dateLabel")
                appendLine()
                appendVolunteerSignOffSection(delivery)
                appendLine()
                appendBasketDistributionSection(delivery)
                appendBasketExchangeSection(pickups, memberNames)
                append(SIGNATURE)
            }
        return EmailContent(
            subject = "Feuilles d'émargement — ${organization.name} — $dateLabel",
            body = body,
        )
    }

    private fun StringBuilder.appendVolunteerSignOffSection(delivery: Delivery) {
        appendLine("=== ÉMARGEMENT BÉNÉVOLES ===")
        val volunteers =
            delivery.contracts
                .flatMap { dc ->
                    dc.slots.flatMap { slot ->
                        slot.registrations
                            .filter { it.status == RegistrationStatus.REGISTERED || it.status == RegistrationStatus.CONFIRMED }
                            .map { reg -> Pair(slot.startTime, reg) }
                    }
                }
        if (volunteers.isEmpty()) {
            appendLine("Aucun bénévole inscrit.")
            return
        }
        for ((startTime, reg) in volunteers) {
            val arrival = "${startTime.hour}h${startTime.minute.toString().padStart(2, '0')}"
            appendLine(
                "${reg.displayName} <${reg.memberEmail}>  Arrivée : $arrival  □ Présent  □ Absent  Signature : ___________",
            )
        }
    }

    private fun StringBuilder.appendBasketDistributionSection(delivery: Delivery) {
        appendLine("=== DISTRIBUTION PANIERS ===")
        if (delivery.contracts.isEmpty()) {
            appendLine("Aucun contrat.")
            return
        }
        for (dc in delivery.contracts) {
            appendLine("${dc.deliveryDescription} — ${dc.basketQuantity} panier(s)")
        }
    }

    private fun StringBuilder.appendBasketExchangeSection(
        pickups: Map<String, String>,
        memberNames: Map<String, String>,
    ) {
        if (pickups.isEmpty()) return
        appendLine()
        appendLine("=== ÉCHANGES DE PANIERS ===")
        for ((ownerId, collectorId) in pickups) {
            val owner = memberNames[ownerId] ?: ownerId
            val collector = memberNames[collectorId] ?: collectorId
            appendLine("Panier de $owner → à remettre à $collector")
        }
    }

    /** Member display name ("Prénom Nom"), falling back to the member id. */
    private fun Member.displayName(): String {
        val name = listOfNotNull(firstName, lastName).filter { it.isNotBlank() }.joinToString(" ")
        return name.ifBlank { memberId.id }
    }

    /**
     * For [deliveryId], maps each member whose basket is collected by another member
     * (confirmed exchange) to the collector. Mirrors the front
     * `basketPickupsForDelivery` selector.
     */
    private fun basketPickupsForDelivery(
        exchanges: List<BasketExchange>,
        deliveryId: String,
    ): Map<String, String> {
        val pickups = LinkedHashMap<String, String>()
        for (e in exchanges) {
            if (e.status != BasketExchangeStatus.ACCEPTED) continue
            val acceptedId = e.acceptedRequestId ?: continue
            val accepted = e.requests.firstOrNull { it.requestId == acceptedId } ?: continue
            when (deliveryId) {
                e.deliveryId.id -> {
                    pickups[e.offeringMemberId.id] = accepted.requesterMemberId.id
                }

                accepted.proposedDeliveryId?.id -> {
                    pickups[accepted.requesterMemberId.id] = e.offeringMemberId.id
                }
            }
        }
        return pickups
    }

    private fun formatDeliveryDate(dt: LocalDateTime): String {
        val months =
            listOf(
                "janvier",
                "février",
                "mars",
                "avril",
                "mai",
                "juin",
                "juillet",
                "août",
                "septembre",
                "octobre",
                "novembre",
                "décembre",
            )
        val month = months[dt.month.ordinal]
        val hour = "${dt.hour}h${dt.minute.toString().padStart(2, '0')}"
        return "${dt.day} $month ${dt.year} à $hour"
    }

    private fun rejectionReason(reviewComment: String?): String =
        if (reviewComment.isNullOrBlank()) {
            ""
        } else {
            "\nMotif : $reviewComment\n"
        }
}

package exchange

import email.MemberSummary
import id.Id
import persistence.model.Delivery
import persistence.model.Member
import persistence.model.Organization

private val FRENCH_MONTHS =
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

internal fun Member.toSummary(): MemberSummary =
    MemberSummary(
        memberId = memberId.id,
        firstName = firstName ?: "",
        lastName = lastName ?: "",
        email = email ?: "",
    )

/** Human-readable name for notification copy ("Prénom Nom", falling back to "Un membre"). */
internal fun Member.displayName(): String {
    val name = listOfNotNull(firstName, lastName).filter { it.isNotBlank() }.joinToString(" ")
    return name.ifBlank { "Un membre" }
}

/** French date label of [deliveryId] within this organization, or "?" if unknown. */
internal fun Organization.deliveryDateLabel(deliveryId: Id<Delivery>?): String {
    val delivery = deliveryId?.let { id -> deliveries.find { it.deliveryId == id } } ?: return "?"
    val dt = delivery.scheduledDate
    val month = FRENCH_MONTHS.getOrElse(dt.month.ordinal) { "" }
    return "${dt.day} $month ${dt.year}".trim()
}

internal fun requestsDeepLink(basketExchangeId: String): String = "/basket-exchange/$basketExchangeId/requests"

internal fun exchangeDeepLink(): String = "/basket-exchange"

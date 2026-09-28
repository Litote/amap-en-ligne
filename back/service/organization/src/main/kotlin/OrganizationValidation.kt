package organization

import core.BasketComposition
import core.InputRules
import persistence.model.Delivery
import persistence.model.NotificationCategory
import persistence.model.Organization

/**
 * Mirrors the admin identity form (`organization_config_screen.dart`) and the coordinator
 * delivery form (`time_slot_form_screen.dart`, slot-time overrides + minimum volunteers)
 * and basket-composition editor (component name / weight).
 *
 * Only fields that differ from [persisted] are checked: the `Organization` aggregate is
 * re-upserted for many unrelated reasons (registrations, basket composition…), and a
 * legacy value must not block those edits.
 */
internal fun organizationFormError(
    persisted: Organization?,
    incoming: Organization,
): String? {
    if (incoming.name != persisted?.name) InputRules.requireName("name", incoming.name)?.let { return it }
    if (incoming.contactEmail != persisted?.contactEmail) {
        InputRules.requireEmail("contact_email", incoming.contactEmail)?.let { return it }
    }
    if (incoming.website != persisted?.website) InputRules.optionalHttpUrl("website", incoming.website)?.let { return it }
    // Mirrors `requiredLanguageCode` in the front identity form.
    if (incoming.defaultLanguage != persisted?.defaultLanguage && !LANGUAGE_CODE.matches(incoming.defaultLanguage)) {
        return "default_language must be a two-letter code (e.g. fr)"
    }
    notificationOverridesError(persisted, incoming)?.let { return it }
    itemTypesError(persisted, incoming)?.let { return it }
    val persistedDeliveries = persisted?.deliveries.orEmpty().associateBy { it.deliveryId }
    incoming.deliveries.forEach { delivery ->
        deliveryFormError(persistedDeliveries[delivery.deliveryId], delivery)?.let { return it }
    }
    return null
}

private val LANGUAGE_CODE = Regex("[a-z]{2}")

// Custom alert copy is sent verbatim (NotificationCopy.resolveCopy): a `{…}` placeholder
// would reach members as is. Mirrors `alertOverrideError` in `alert_templates_bloc.dart`.
private val ALERT_PLACEHOLDER = Regex("\\{[^{}]*}")

// Org alerts actually published with `resolveCopy` — mirrors `kCustomisableAlertCategories` in
// `alert_templates_bloc.dart`. DELIVERY_REMINDER is never sent; owner categories have no org.
private val CUSTOMISABLE_ALERT_CATEGORIES =
    setOf(
        NotificationCategory.SLOT_CANCELLED,
        NotificationCategory.SLOT_RESCHEDULED,
        NotificationCategory.VOLUNTEER_SHORTAGE,
        NotificationCategory.VOLUNTEER_URGENT_NEED,
        NotificationCategory.BASKET_EXCHANGE_REQUEST_RECEIVED,
        NotificationCategory.BASKET_EXCHANGE_ACCEPTED,
        NotificationCategory.BASKET_EXCHANGE_REJECTED,
        NotificationCategory.MEMBER_JOIN_REQUEST_SUBMITTED,
    )

/**
 * Rejects changed admin alert overrides of a category that is never sent with the org copy,
 * or containing a `{…}` placeholder.
 */
private fun notificationOverridesError(
    persisted: Organization?,
    incoming: Organization,
): String? {
    val previous = persisted?.notificationOverrides.orEmpty()
    incoming.notificationOverrides.forEach { (category, override) ->
        if (override == previous[category]) return@forEach
        if (category !in CUSTOMISABLE_ALERT_CATEGORIES) {
            return "notification_overrides.$category cannot be customised"
        }
        listOfNotNull(override.title, override.body).forEach { text ->
            if (ALERT_PLACEHOLDER.containsMatchIn(text)) {
                return "notification_overrides.$category must not contain {…} placeholders (sent verbatim)"
            }
        }
    }
    return null
}

/**
 * Changed entries of the organization component catalog follow the producer catalog rules
 * (`ProductTypeValidation`): a name and a small SVG-only icon. An oversized icon would push
 * the whole organization item over the DynamoDB 400 KB limit.
 */
private fun itemTypesError(
    persisted: Organization?,
    incoming: Organization,
): String? {
    val previous = persisted?.itemTypes.orEmpty().associateBy { it.id }
    incoming.itemTypes.forEach { itemType ->
        if (itemType == previous[itemType.id]) return@forEach
        InputRules.requireName("item_types.name", itemType.name)?.let { return it }
        InputRules.optionalSvg("item_types.image_svg", itemType.imageSvg)?.let { return it }
    }
    return null
}

private fun deliveryFormError(
    persisted: Delivery?,
    incoming: Delivery,
): String? {
    val start = incoming.scheduledDate.hour * 60 + incoming.scheduledDate.minute
    val label = "delivery ${incoming.scheduledDate.date}"
    if (incoming.minVolunteersRequired != persisted?.minVolunteersRequired) {
        InputRules.requireAtLeast("$label min_volunteers_required", incoming.minVolunteersRequired, 1)?.let { return it }
    }
    val endTime = incoming.standardEndTime
    if (endTime != null && endTime != persisted?.standardEndTime) {
        val end = InputRules.minutesOf(endTime) ?: return "$label standard_end_time must be HH:MM"
        if (end <= start) return "$label standard_end_time must be after the delivery start time"
    }
    val arrivalTime = incoming.volunteerArrivalTime
    if (arrivalTime != null && arrivalTime != persisted?.volunteerArrivalTime) {
        val arrival = InputRules.minutesOf(arrivalTime) ?: return "$label volunteer_arrival_time must be HH:MM"
        if (arrival > start) return "$label volunteer_arrival_time must not be after the delivery start time"
    }
    val earlySlot = incoming.earlySlot
    if (earlySlot != null && earlySlot != persisted?.earlySlot) {
        val early = InputRules.minutesOf(earlySlot.arrivalTime) ?: return "$label early_slot.arrival_time must be HH:MM"
        if (early >= start) return "$label early_slot.arrival_time must be before the delivery start time"
        InputRules.requireAtLeast("$label early_slot.max_volunteers", earlySlot.maxVolunteers, 1)?.let { return it }
    }
    basketItemsError(persisted, incoming, label)?.let { return it }
    return null
}

/** Composition rules shared with the producer path — see [BasketComposition.itemsError]. */
private fun basketItemsError(
    persisted: Delivery?,
    incoming: Delivery,
    label: String,
): String? = BasketComposition.itemsError(persisted?.basketDescriptions.orEmpty(), incoming.basketDescriptions, label)

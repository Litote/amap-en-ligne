package deliverytemplate

import core.InputRules
import persistence.model.DeliveryTemplate

/**
 * Mirrors the admin template form (`delivery_template_form_screen.dart` +
 * `delivery_template_time_utils.dart`): required name, strict `HH:MM` times,
 * end after start, volunteer arrival at or before start, early arrival strictly
 * before start, and positive volunteer counts. Returns the first violation.
 */
internal fun DeliveryTemplate.validationError(): String? {
    InputRules.requireName("name", name)?.let { return it }
    val start = InputRules.minutesOf(standardStartTime) ?: return "standard_start_time must be HH:MM"
    val end = InputRules.minutesOf(standardEndTime) ?: return "standard_end_time must be HH:MM"
    if (end <= start) return "standard_end_time must be after standard_start_time"
    volunteerArrivalTime?.let { arrival ->
        val arrivalMinutes = InputRules.minutesOf(arrival) ?: return "volunteer_arrival_time must be HH:MM"
        if (arrivalMinutes > start) return "volunteer_arrival_time must not be after standard_start_time"
    }
    InputRules.requireAtLeast("desired_volunteer_count", desiredVolunteerCount, 1)?.let { return it }
    earlySlot?.let { slot ->
        val early = InputRules.minutesOf(slot.arrivalTime) ?: return "early_slot.arrival_time must be HH:MM"
        if (early >= start) return "early_slot.arrival_time must be before standard_start_time"
        InputRules.requireAtLeast("early_slot.max_volunteers", slot.maxVolunteers, 1)?.let { return it }
    }
    return null
}

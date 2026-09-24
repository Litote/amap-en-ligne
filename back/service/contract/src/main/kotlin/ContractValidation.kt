package contract

import core.InputRules
import persistence.model.Contract

/** Season years accepted by the contract form (`coordinator_contracts_screen.dart`). */
internal val SEASON_YEAR_RANGE = 2000..2100

/**
 * Mirrors the coordinator contract form: required name and producer, first delivery
 * date not after the last one, at least one delivery, plausible season year.
 * Returns the first violation, or `null`.
 */
internal fun Contract.fieldValidationError(): String? {
    InputRules.requireName("name", name)?.let { return it }
    if (producerAccountId.id.isBlank()) return "producer_account_id must not be blank"
    if (minDeliveryDate > maxDeliveryDate) return "min_delivery_date must not be after max_delivery_date"
    InputRules.requireAtLeast("delivery_count", deliveryCount, 1)?.let { return it }
    if (seasonYear !in SEASON_YEAR_RANGE) return "season_year must be between ${SEASON_YEAR_RANGE.first} and ${SEASON_YEAR_RANGE.last}"
    return null
}

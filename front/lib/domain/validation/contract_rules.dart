/// Contract form rules, mirroring the back `ContractValidation.kt`
/// (`SEASON_YEAR_RANGE`, `min_delivery_date <= max_delivery_date`).
library;

const int kMinSeasonYear = 2000;
const int kMaxSeasonYear = 2100;

/// Season year: an integer between [kMinSeasonYear] and [kMaxSeasonYear].
String? seasonYearError(String? value) {
  final year = int.tryParse(value?.trim() ?? '');
  if (year == null) return 'Année invalide';
  if (year < kMinSeasonYear || year > kMaxSeasonYear) {
    return 'Année invalide (entre $kMinSeasonYear et $kMaxSeasonYear)';
  }
  return null;
}

/// First delivery date (ISO `YYYY-MM-DD`) must not be after the last one.
/// Returns `null` when either date is missing/unparsable (handled elsewhere).
String? contractDateRangeError(String minDate, String maxDate) {
  final min = DateTime.tryParse(minDate.trim());
  final max = DateTime.tryParse(maxDate.trim());
  if (min == null || max == null || !min.isAfter(max)) return null;
  return 'La date de première livraison doit précéder la date de dernière '
      'livraison.';
}

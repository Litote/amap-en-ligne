/// Delivery form rules, mirroring the back `OrganizationValidation.kt`
/// (per-delivery slot-time overrides and minimum volunteers).
///
/// Callers pass only the values the user changed (null otherwise), exactly
/// like the back, which only checks fields that differ from the stored
/// delivery so legacy data stays editable.
library;

int? _minutesOf(String hhmm) {
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(hhmm);
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

/// Returns the first French error message, or `null` when coherent.
String? deliverySlotTimesError({
  required int startMinutes,
  String? standardEndTime,
  String? volunteerArrivalTime,
  String? earlyArrivalTime,
  int? earlyMaxVolunteers,
  int? minVolunteers,
}) {
  if (minVolunteers != null && minVolunteers < 1) {
    return 'Le nombre minimum de bénévoles doit être au moins 1.';
  }
  return _timeError(
        standardEndTime,
        (end) => end <= startMinutes,
        "L'heure de fin doit être après l'heure de début de la livraison.",
      ) ??
      _timeError(
        volunteerArrivalTime,
        (arrival) => arrival > startMinutes,
        "L'arrivée des bénévoles doit être avant ou à l'heure de début "
        'de livraison.',
      ) ??
      _timeError(
        earlyArrivalTime,
        (early) => early >= startMinutes,
        "L'arrivée anticipée doit être avant l'heure de début de "
        'livraison.',
      ) ??
      _earlyMaxVolunteersError(earlyMaxVolunteers);
}

/// Returns [message] when [hhmm] is set and either malformed or rejected by
/// [isInvalid] (which receives the time in minutes since midnight).
String? _timeError(
  String? hhmm,
  bool Function(int minutes) isInvalid,
  String message,
) {
  if (hhmm == null) return null;
  final minutes = _minutesOf(hhmm);
  return minutes == null || isInvalid(minutes) ? message : null;
}

String? _earlyMaxVolunteersError(int? earlyMaxVolunteers) {
  if (earlyMaxVolunteers != null && earlyMaxVolunteers < 1) {
    return 'Le nombre de bénévoles du créneau anticipé doit être au moins 1.';
  }
  return null;
}

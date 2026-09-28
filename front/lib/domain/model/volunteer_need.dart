/// How pressing a delivery's volunteer need is, as shown to members.
enum VolunteerNeedLevel {
  /// No badge: no need, or at least 80 % of the places are taken.
  none,

  /// Between 50 % and 80 % of the places are taken.
  limited,

  /// Less than 50 % taken, the delivery is more than [kUrgentNeedWindow] away.
  wanted,

  /// Less than 50 % taken, the delivery is within [kUrgentNeedWindow].
  urgent,
}

/// A short-staffed delivery becomes "urgent" this close to its start — the
/// lead of the first volunteer shortage alert (back `SHORTAGE_LEAD`), so the
/// planning never cries "urgent" weeks before any alert is sent.
const Duration kUrgentNeedWindow = Duration(days: 3);

/// Level of the volunteer need of a delivery starting at [start], with
/// [current] of the [required] volunteers registered.
VolunteerNeedLevel volunteerNeedLevel({
  required int current,
  required int required,
  required DateTime start,
  required DateTime now,
}) {
  if (required <= 0) return VolunteerNeedLevel.none;
  final rate = current / required;
  if (rate >= 0.8) return VolunteerNeedLevel.none;
  if (rate >= 0.5) return VolunteerNeedLevel.limited;
  return start.difference(now) <= kUrgentNeedWindow
      ? VolunteerNeedLevel.urgent
      : VolunteerNeedLevel.wanted;
}

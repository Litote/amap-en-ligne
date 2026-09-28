import 'package:intl/intl.dart';

/// Formats an ISO-8601 instant (e.g. `2026-09-26T06:27:42.216Z`) as a French
/// local date and time: "26 sept. 2026 à 08h27".
///
/// Returns [iso] unchanged when it cannot be parsed, so a malformed value is
/// still visible rather than hidden.
String formatInstantFr(String iso) {
  final instant = DateTime.tryParse(iso);
  if (instant == null) return iso;
  return DateFormat("d MMM yyyy 'à' HH'h'mm", 'fr').format(instant.toLocal());
}

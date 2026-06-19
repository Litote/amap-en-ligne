import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:intl/intl.dart';

/// Shared date/time formatting for delivery display widgets.
///
/// Centralises the formatters that were previously duplicated across the member
/// planning screen, the volunteer dashboard and the coordinator screens.

/// Formats a delivery's scheduled date as a one-line time range label.
///
/// - [longMonth] true → planning style: "Mercredi 17 Janvier • 18h00-20h00"
///   (full month name, padded minutes).
/// - [longMonth] false → dashboard style: "Mercredi 31 Jan • 18h-20h"
///   (abbreviated month, trimmed minutes).
///
/// When [slotEndTime] (an ISO-8601 datetime from [MemberSlot.endTime]) is
/// provided it sets the end of the range; otherwise the end defaults to
/// start + 2h.
String formatDeliveryDateLine(
  String scheduledDate, {
  String? slotEndTime,
  bool longMonth = false,
}) {
  final date = DateTime.parse(scheduledDate);
  final pattern = longMonth ? 'EEEE d MMMM' : 'EEEE d MMM';
  final dayPart = DateFormat(pattern, 'fr').format(date);
  final capitalised = _capitalise(dayPart);

  final start = _formatTime(date.hour, date.minute, padMinutes: longMonth);

  final String end;
  final parsedEnd = _tryParseIso(slotEndTime);
  if (parsedEnd != null) {
    end = _formatTime(parsedEnd.hour, parsedEnd.minute, padMinutes: false);
  } else {
    end = _formatTime(date.hour + 2, date.minute, padMinutes: longMonth);
  }

  return '$capitalised • $start-$end';
}

/// Formats a delivery's scheduled date as a single start time, coordinator
/// style: "Mercredi 17 Janvier • 18h00".
String formatDeliveryDateTime(String scheduledDate) {
  final date = DateTime.parse(scheduledDate);
  final raw = DateFormat("EEEE d MMMM • HH'h'mm", 'fr').format(date);
  return _capitalise(raw);
}

/// Formats an ISO-8601 datetime to a trimmed time label: "18h" or "18h30".
///
/// Returns the input unchanged when it cannot be parsed.
String formatSlotTime(String iso) {
  final dt = _tryParseIso(iso);
  if (dt == null) return iso;
  return _formatTime(dt.hour, dt.minute, padMinutes: false);
}

/// Formats a "HH:MM" template time string (e.g. "18:30") to "18h30" / "18h".
String formatTemplateTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return hhmm;
  return _formatTime(hour, minute, padMinutes: false);
}

/// French label for a slot [ActivityType].
String activityLabel(ActivityType activityType) => switch (activityType) {
  ActivityType.preparation => 'Préparation paniers',
  ActivityType.reception => 'Réception',
  ActivityType.distribution => 'Distribution',
};

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Formats an (hour, minute) pair. When [padMinutes] is false the minutes are
/// dropped for whole hours ("18h"); otherwise they are always shown ("18h00").
String _formatTime(int hour, int minute, {required bool padMinutes}) {
  final h = hour.toString().padLeft(2, '0');
  if (!padMinutes && minute == 0) return '${h}h';
  final m = minute.toString().padLeft(2, '0');
  return '${h}h$m';
}

DateTime? _tryParseIso(String? iso) {
  if (iso == null) return null;
  return DateTime.tryParse(iso);
}

import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Builds the default volunteer slots for a delivery scheduled at [scheduled].
///
/// Volunteers can only register on existing [MemberSlot]s (the back forbids
/// slot creation to VOLUNTEER-only callers), so privileged delivery writes
/// must materialise them:
/// - one OPEN STANDARD slot from [scheduled] to the template's standard end
///   time (two hours after [scheduled] without template), sized by
///   [requiredVolunteers];
/// - one OPEN EARLY slot from the template's early-arrival time to the same
///   end, sized by [EarlySlot.maxVolunteers], when the template defines one.
///
/// Per-delivery overrides ([standardEndTimeOverride], [volunteerArrivalTimeOverride],
/// [earlySlotOverride]) win over the [template]; the template is the fallback, then the
/// hard-coded defaults. An early slot can thus be materialised from a delivery override
/// even when no template is selected.
///
/// Slot ids stay null — the back allocates them on first write.
List<MemberSlot> defaultVolunteerSlots({
  required DateTime scheduled,
  required int requiredVolunteers,
  DeliveryTemplate? template,
  String? standardEndTimeOverride,
  String? volunteerArrivalTimeOverride,
  EarlySlot? earlySlotOverride,
}) {
  final end =
      _timeOnDay(
        scheduled,
        standardEndTimeOverride ?? template?.standardEndTime,
      ) ??
      scheduled.add(const Duration(hours: 2));
  final standardStart =
      _timeOnDay(
        scheduled,
        volunteerArrivalTimeOverride ?? template?.volunteerArrivalTime,
      ) ??
      scheduled;
  final slots = [
    MemberSlot(
      startTime: _iso(standardStart),
      endTime: _iso(end),
      activityType: ActivityType.reception,
      requiredVolunteers: requiredVolunteers,
      currentRegistrations: 0,
      status: SlotStatus.open,
      slotKind: SlotKind.standard,
    ),
  ];
  final earlySlot = earlySlotOverride ?? template?.earlySlot;
  final earlyStart = earlySlot == null
      ? null
      : _timeOnDay(scheduled, earlySlot.arrivalTime);
  if (earlySlot != null && earlyStart != null) {
    slots.add(
      MemberSlot(
        startTime: _iso(earlyStart),
        endTime: _iso(end),
        activityType: ActivityType.reception,
        requiredVolunteers: earlySlot.maxVolunteers,
        currentRegistrations: 0,
        status: SlotStatus.open,
        slotKind: SlotKind.early,
      ),
    );
  }
  return slots;
}

DateTime? _timeOnDay(DateTime day, String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

String _iso(DateTime dt) => dt.toIso8601String().split('.').first;

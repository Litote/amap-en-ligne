import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';

/// Coordinator-facing "N/M bénévoles" summary.
///
/// Delegates to the canonical [deliveryVolunteerStaffing] selector (sum over all
/// non-cancelled STANDARD + EARLY slots) and falls back to the delivery's
/// configured [Delivery.minVolunteersRequired] when no slot defines a need yet.
({int current, int required}) deliveryVolunteerSummary(Delivery delivery) {
  final staffing = deliveryVolunteerStaffing(delivery);
  final required = staffing.required == 0
      ? delivery.minVolunteersRequired
      : staffing.required;
  return (current: staffing.current, required: required);
}

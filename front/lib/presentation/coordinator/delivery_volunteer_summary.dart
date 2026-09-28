import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';

/// Coordinator-facing "N/M bénévoles" summary.
///
/// Delegates to the canonical [deliveryVolunteerStaffing] selector (sum over all
/// non-cancelled STANDARD + EARLY slots) and falls back to the delivery's
/// configured [Delivery.minVolunteersRequired] when no slot defines a need yet —
/// unless the delivery carries no main contract while the organization has
/// some: only main contracts mobilise volunteers, so such a delivery needs none
/// (`required == 0`, cf. [kNoVolunteerNeededLabel]).
({int current, int required}) deliveryVolunteerSummary(
  Delivery delivery, {
  Set<String> mainContractIds = const {},
}) {
  final staffing = deliveryVolunteerStaffing(
    delivery,
    mainContractIds: mainContractIds,
  );
  final needsVolunteers =
      mainContractIds.isEmpty ||
      delivery.contracts.any((c) => mainContractIds.contains(c.contractId));
  final required = staffing.required == 0 && needsVolunteers
      ? delivery.minVolunteersRequired
      : staffing.required;
  return (current: staffing.current, required: required);
}

/// Shown instead of the "N/M bénévoles" counter when a delivery needs no
/// volunteer (see [deliveryVolunteerSummary]).
const kNoVolunteerNeededLabel = 'Aucun bénévole requis';

/// The counter line for [summary]: "N/M bénévoles", or
/// [kNoVolunteerNeededLabel] when nothing is required.
String volunteerSummaryLabel(({int current, int required}) summary) =>
    summary.required == 0
    ? kNoVolunteerNeededLabel
    : '${summary.current}/${summary.required} bénévoles';

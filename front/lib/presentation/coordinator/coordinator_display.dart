import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Display helpers for coordinator names — shared between dashboard sections
/// and the planning screen.

// V1: no per-contract emoji yet; spec uses 🥕/🍞 as illustrations.

/// Returns an abbreviated name for [member]: "J. Morel".
///
/// Falls back to [member.memberId] when both [firstName] and [lastName] are
/// null or empty.
String abbreviateMemberName(Member member) {
  final first = member.firstName?.trim() ?? '';
  final last = member.lastName?.trim() ?? '';
  if (first.isEmpty && last.isEmpty) return member.memberId;
  if (first.isEmpty) return last;
  return '${first[0]}. $last';
}

/// Returns the full display name for [member]: "Jean Morel".
///
/// Falls back to [member.memberId] when both fields are null/empty.
String displayMemberName(Member member) {
  final first = member.firstName?.trim() ?? '';
  final last = member.lastName?.trim() ?? '';
  if (first.isEmpty && last.isEmpty) return member.memberId;
  if (first.isEmpty) return last;
  if (last.isEmpty) return first;
  return '$first $last';
}

/// Returns a compact coordinator summary for [contract], e.g.:
///   - "J. Morel" when one coordinator is resolved.
///   - "J. Morel, M. Olivier" when multiple.
///   - "—" when [contract.coordinators] is empty or none are found in [membersById].
String formatCoordinatorsCompact(
  DeliveryContract contract,
  Map<String, Member> membersById,
) {
  if (contract.coordinators.isEmpty) return '—';
  final names = contract.coordinators
      .map((id) => membersById[id])
      .whereType<Member>()
      .map(abbreviateMemberName)
      .toList();
  if (names.isEmpty) return '—';
  return names.join(', ');
}

/// Placeholder shown for [contract] when none of its coordinators can be named:
///   - "Coordinateur à confirmer" when nobody coordinates it yet.
///   - "Coordinateur inscrit" when someone does but their [Member] is not in the
///     local cache (e.g. right after login, before the members are synced).
String unnamedCoordinatorLabel(DeliveryContract contract) =>
    contract.coordinators.isEmpty
    ? 'Coordinateur à confirmer'
    : 'Coordinateur inscrit';

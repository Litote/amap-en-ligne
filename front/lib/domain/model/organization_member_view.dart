import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Pure domain selectors for the volunteer member dashboard view.
///
/// No Flutter dependencies — all functions are testable in plain Dart.

// ---------------------------------------------------------------------------
// Season selectors
// ---------------------------------------------------------------------------

/// Returns the current season year: the highest [Contract.seasonYear] among
/// contracts whose [Contract.status] is [ContractStatus.active].
///
/// Falls back to [now.year] when no contract has status ACTIVE.
int currentSeasonYear(List<Contract> contracts, DateTime now) {
  int? best;
  for (final c in contracts) {
    if (c.status == ContractStatus.active) {
      if (best == null || c.seasonYear > best) {
        best = c.seasonYear;
      }
    }
  }
  return best ?? now.year;
}

/// Returns the set of [Contract.contractId] values for contracts whose
/// [Contract.seasonYear] matches [seasonYear].
Set<String> seasonContractIds(List<Contract> contracts, int seasonYear) {
  final result = <String>{};
  for (final c in contracts) {
    if (c.seasonYear == seasonYear) {
      result.add(c.contractId);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Delivery selectors
// ---------------------------------------------------------------------------

/// Returns the next [Delivery] (chronologically) where [memberId] has an
/// active (non-CANCELLED) registration, or null if no such delivery exists.
///
/// "Next" means [Delivery.scheduledDate] is after [now] and the delivery is
/// active (not COMPLETED / CANCELLED).
Delivery? nextRegistrationFor(
  Organization org,
  String memberId, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final registered =
      org.deliveries.where((d) {
        if (!d.status.isActive) return false;
        final date = DateTime.parse(d.scheduledDate);
        if (!date.isAfter(reference)) return false;
        return isRegisteredOn(d, memberId);
      }).toList()..sort(
        (a, b) => DateTime.parse(
          a.scheduledDate,
        ).compareTo(DateTime.parse(b.scheduledDate)),
      );
  return registered.firstOrNull;
}

/// Returns up to [limit] upcoming active deliveries with volunteer slots,
/// sorted chronologically.
///
/// "Upcoming" means [Delivery.scheduledDate] is after [now] and the delivery
/// is active (not COMPLETED / CANCELLED). Only deliveries with at least one
/// volunteer slot are returned (deliveries without contracts/slots are excluded).
List<Delivery> upcomingActiveDeliveries(
  Organization org,
  DateTime now, {
  int limit = 5,
}) {
  final result =
      org.deliveries.where((d) {
        if (!d.status.isActive) return false;
        if (!DateTime.parse(d.scheduledDate).isAfter(now)) return false;
        return _deliveryHasVolunteerSlots(d);
      }).toList()..sort(
        (a, b) => DateTime.parse(
          a.scheduledDate,
        ).compareTo(DateTime.parse(b.scheduledDate)),
      );
  return result.take(limit).toList();
}

bool _deliveryHasVolunteerSlots(Delivery delivery) {
  for (final contract in delivery.contracts) {
    if (contract.slots.isNotEmpty) return true;
  }
  return false;
}

/// True when [delivery] is only linked to contracts that are not yet active
/// (status IN_PREPARATION): such a delivery is hidden from plain members and
/// flagged "Contrat inactif" (registration disabled) for coordinators/admins.
///
/// Links whose contract is not in [contractsById] are ignored — an unknown
/// contract cannot vouch either way. A delivery without any resolvable link
/// (no contracts, or only unknown ones) is considered active.
bool isDeliveryPendingContractActivation(
  Delivery delivery,
  Map<String, Contract> contractsById,
) {
  var sawKnownContract = false;
  for (final link in delivery.contracts) {
    final contract = contractsById[link.contractId];
    if (contract == null) continue;
    sawKnownContract = true;
    if (contract.status != ContractStatus.inPreparation) return false;
  }
  return sawKnownContract;
}

/// Returns true when [memberId] has at least one active (non-CANCELLED)
/// registration on any slot of [delivery].
bool isRegisteredOn(Delivery delivery, String memberId) {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      for (final reg in slot.registrations) {
        if (reg.memberId == memberId &&
            reg.status != RegistrationStatus.cancelled) {
          return true;
        }
      }
    }
  }
  return false;
}

/// Canonical volunteer-staffing total for [delivery]: the sum of
/// ([MemberSlot.currentRegistrations], [MemberSlot.requiredVolunteers]) over all
/// **non-cancelled** slots of every contract, counting STANDARD and EARLY slots
/// alike.
///
/// This is the single source of truth for the "N/M bénévoles" counter shown
/// across the member planning, the dashboards and the coordinator screens
/// (cf. UI specs `screen-member-01/02`, `screen-coordinator-01/02`, which sum
/// `requiredVolunteers` over every slot). CANCELLED slots accept no registration
/// and never count toward capacity.
({int current, int required}) deliveryVolunteerStaffing(Delivery delivery) {
  var current = 0;
  var required = 0;
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      if (slot.status == SlotStatus.cancelled) continue;
      required += slot.requiredVolunteers;
      current += slot.currentRegistrations;
    }
  }
  return (current: current, required: required);
}

/// Derives a single [SlotStatus] summarising the volunteer staffing of
/// [delivery], used by the coordinator list chips.
///
/// - Inactive delivery (COMPLETED / CANCELLED) → [SlotStatus.closed].
/// - No required volunteers → [SlotStatus.open].
/// - Fully staffed (ratio ≥ 1) → [SlotStatus.full].
/// - Half staffed or more (ratio ≥ 0.5) → [SlotStatus.open].
/// - Otherwise → [SlotStatus.critical].
SlotStatus deliverySlotStatus(Delivery delivery) {
  if (!delivery.status.isActive) return SlotStatus.closed;
  var total = 0;
  var filled = 0;
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      total += slot.requiredVolunteers;
      filled += slot.currentRegistrations;
    }
  }
  if (total == 0) return SlotStatus.open;
  final ratio = filled / total;
  if (ratio >= 1.0) return SlotStatus.full;
  if (ratio >= 0.5) return SlotStatus.open;
  return SlotStatus.critical;
}

// ---------------------------------------------------------------------------
// Slot selectors
// ---------------------------------------------------------------------------

/// Returns the STANDARD and EARLY [MemberSlot]s from a [DeliveryContract], or
/// null when no such slot exists.
///
/// When the contract has multiple slots of the same kind, the first one is
/// returned.
({MemberSlot? standard, MemberSlot? early}) slotsByKind(
  DeliveryContract contract,
) {
  MemberSlot? standard;
  MemberSlot? early;
  for (final slot in contract.slots) {
    if (slot.slotKind == SlotKind.standard && standard == null) {
      standard = slot;
    } else if (slot.slotKind == SlotKind.early && early == null) {
      early = slot;
    }
  }
  return (standard: standard, early: early);
}

/// Returns the volunteer capacity for [slot] — its [MemberSlot.requiredVolunteers]
/// for both STANDARD and EARLY slots.
///
/// EARLY slots are materialised with `requiredVolunteers` set to the resolved
/// early capacity (delivery override, then template `earlySlot.maxVolunteers`),
/// so the slot row is the single override-aware source — no [DeliveryTemplate]
/// lookup is needed at read time. See [deliveryVolunteerStaffing].
int slotCapacity(MemberSlot slot) => slot.requiredVolunteers;

/// Counts the active (non-CANCELLED) registrations on [slot].
int activeRegistrationsCount(MemberSlot slot) => slot.registrations
    .where((r) => r.status != RegistrationStatus.cancelled)
    .length;

/// Returns true when [slot] has remaining capacity for a new registration.
///
/// Capacity is resolved via [slotCapacity] — returns false when capacity is 0
/// (a slot sized for no volunteers). A [SlotStatus.cancelled] slot never accepts
/// registrations.
bool slotHasCapacity(MemberSlot slot) {
  if (slot.status == SlotStatus.cancelled) return false;
  final capacity = slotCapacity(slot);
  if (capacity == 0) return false;
  return activeRegistrationsCount(slot) < capacity;
}

// ---------------------------------------------------------------------------
// History selectors
// ---------------------------------------------------------------------------

/// Counts [MemberRegistration]s with [RegistrationStatus.completed] for
/// [memberId] across all deliveries that are linked to at least one contract
/// whose id is in [seasonContractIds].
///
/// A delivery qualifies if any of its [Delivery.contracts] has a contractId
/// present in [seasonContractIds]. Only slots on those qualifying contracts
/// are inspected.
int completedRegistrationsInSeason(
  Organization org,
  String memberId,
  Set<String> seasonContractIds,
) {
  if (seasonContractIds.isEmpty) return 0;
  var count = 0;
  for (final delivery in org.deliveries) {
    for (final contract in delivery.contracts) {
      if (!seasonContractIds.contains(contract.contractId)) continue;
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status == RegistrationStatus.completed) {
            count++;
          }
        }
      }
    }
  }
  return count;
}

/// Returns the [Delivery] of the most recent [RegistrationStatus.completed]
/// registration for [memberId] restricted to the given [seasonContractIds],
/// or null if none exists.
Delivery? lastCompletedDeliveryInSeason(
  Organization org,
  String memberId,
  Set<String> seasonContractIds,
) {
  if (seasonContractIds.isEmpty) return null;
  Delivery? latest;
  DateTime? latestDate;
  for (final delivery in org.deliveries) {
    for (final contract in delivery.contracts) {
      if (!seasonContractIds.contains(contract.contractId)) continue;
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status == RegistrationStatus.completed) {
            final date = DateTime.parse(delivery.scheduledDate);
            if (latestDate == null || date.isAfter(latestDate)) {
              latestDate = date;
              latest = delivery;
            }
          }
        }
      }
    }
  }
  return latest;
}

/// Returns the [Delivery] of the most recent [RegistrationStatus.completed]
/// registration for [memberId], or null if none exists.
///
/// Searches across all deliveries regardless of season.
Delivery? lastCompletedDelivery(Organization org, String memberId) {
  Delivery? latest;
  DateTime? latestDate;
  for (final delivery in org.deliveries) {
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status == RegistrationStatus.completed) {
            final date = DateTime.parse(delivery.scheduledDate);
            if (latestDate == null || date.isAfter(latestDate)) {
              latestDate = date;
              latest = delivery;
            }
          }
        }
      }
    }
  }
  return latest;
}

// ---------------------------------------------------------------------------
// Registration lookup per delivery
// ---------------------------------------------------------------------------

/// Returns the slot kind of the first active registration for [memberId] on
/// [delivery], or null when no active registration exists.
SlotKind? registeredSlotKindOn(Delivery delivery, String memberId) {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      for (final reg in slot.registrations) {
        if (reg.memberId == memberId &&
            reg.status != RegistrationStatus.cancelled) {
          return slot.slotKind;
        }
      }
    }
  }
  return null;
}

/// Returns the contract id and slot kind of the first slot with available
/// capacity of [kind] within [delivery], or null when no such slot exists.
///
/// Used by the register action to locate the target slot without requiring
/// the user to choose a contract.
({String contractId, SlotKind slotKind})? findAvailableSlot(
  Delivery delivery,
  SlotKind kind,
) {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      if (slot.slotKind == kind && slotHasCapacity(slot)) {
        return (contractId: contract.contractId, slotKind: kind);
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// History screen selectors (PR 5)
// ---------------------------------------------------------------------------

/// All registrations (across all deliveries) for [memberId] in [org].
///
/// Returns pairs of delivery + the first registration found on that delivery
/// that belongs to [memberId] (any status). One entry per delivery that has
/// at least one registration for [memberId].
List<({Delivery delivery, MemberRegistration registration})>
personalRegistrations(Organization org, String memberId) {
  final result = <({Delivery delivery, MemberRegistration registration})>[];
  for (final delivery in org.deliveries) {
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId) {
            result.add((delivery: delivery, registration: reg));
          }
        }
      }
    }
  }
  return result;
}

/// Registrations whose status is [RegistrationStatus.completed].
///
/// Sorted descending by [Delivery.scheduledDate] (most recent first).
List<({Delivery delivery, MemberRegistration registration})>
personalCompletedRegistrations(Organization org, String memberId) {
  final all = personalRegistrations(org, memberId)
      .where((e) => e.registration.status == RegistrationStatus.completed)
      .toList();
  all.sort(
    (a, b) => DateTime.parse(
      b.delivery.scheduledDate,
    ).compareTo(DateTime.parse(a.delivery.scheduledDate)),
  );
  return all;
}

/// Registrations on active future deliveries (delivery is active and its
/// scheduled date is strictly after [now]).
///
/// Sorted ascending by [Delivery.scheduledDate].
List<({Delivery delivery, MemberRegistration registration})>
personalUpcomingRegistrations(Organization org, String memberId, DateTime now) {
  final result = <({Delivery delivery, MemberRegistration registration})>[];
  for (final delivery in org.deliveries) {
    if (!delivery.status.isActive) continue;
    if (!DateTime.parse(delivery.scheduledDate).isAfter(now)) continue;
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status != RegistrationStatus.cancelled) {
            result.add((delivery: delivery, registration: reg));
          }
        }
      }
    }
  }
  result.sort(
    (a, b) => DateTime.parse(
      a.delivery.scheduledDate,
    ).compareTo(DateTime.parse(b.delivery.scheduledDate)),
  );
  return result;
}

/// Other registered members on [delivery], excluding [selfMemberId].
///
/// Returns the first non-cancelled, non-self registration per member (deduped
/// by memberId across all slots/contracts of the delivery).
List<MemberRegistration> teammatesOn(Delivery delivery, String selfMemberId) {
  final seen = <String>{};
  final result = <MemberRegistration>[];
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      for (final reg in slot.registrations) {
        if (reg.memberId == selfMemberId) continue;
        if (reg.status == RegistrationStatus.cancelled) continue;
        if (seen.contains(reg.memberId)) continue;
        seen.add(reg.memberId);
        result.add(reg);
      }
    }
  }
  return result;
}

/// Counts total non-cancelled registrations for [memberId] on deliveries linked
/// to at least one contract in [seasonContractIds].
///
/// Includes all statuses except [RegistrationStatus.cancelled] — covers both
/// upcoming (registered/confirmed) and completed participations.
int seasonRegistrationsCount(
  Organization org,
  String memberId,
  Set<String> seasonContractIds,
) {
  if (seasonContractIds.isEmpty) return 0;
  var count = 0;
  for (final delivery in org.deliveries) {
    for (final contract in delivery.contracts) {
      if (!seasonContractIds.contains(contract.contractId)) continue;
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status != RegistrationStatus.cancelled) {
            count++;
          }
        }
      }
    }
  }
  return count;
}

/// Builds the display label for the season banner from the date range of the
/// contracts belonging to [seasonYear].
///
/// Algorithm:
/// 1. Filter [contracts] to those whose [Contract.seasonYear] == [seasonYear].
/// 2. Compute [startYear] = civil year of the earliest [Contract.minDeliveryDate].
/// 3. Compute [endYear]   = civil year of the latest  [Contract.maxDeliveryDate].
/// 4. If no matching contracts → fallback to [now.year].
/// 5. If startYear == endYear → "Saison {startYear}".
/// 6. Otherwise              → "Saison {startYear}-{endYear}".
String seasonLabel(List<Contract> contracts, int seasonYear, DateTime now) {
  final seasonContracts = contracts
      .where((c) => c.seasonYear == seasonYear)
      .toList();

  if (seasonContracts.isEmpty) {
    return 'Saison ${now.year}';
  }

  int? startYear;
  int? endYear;

  for (final c in seasonContracts) {
    try {
      final minYear = DateTime.parse(c.minDeliveryDate).year;
      if (startYear == null || minYear < startYear) startYear = minYear;
    } catch (_) {}
    try {
      final maxYear = DateTime.parse(c.maxDeliveryDate).year;
      if (endYear == null || maxYear > endYear) endYear = maxYear;
    } catch (_) {}
  }

  if (startYear == null || endYear == null) {
    return 'Saison ${now.year}';
  }

  if (startYear == endYear) {
    return 'Saison $startYear';
  }
  return 'Saison $startYear-$endYear';
}

/// Builds the full chronological list of (year, month, count) records covering
/// every month in the season range, from the month of the earliest
/// [Contract.minDeliveryDate] to the month of the latest
/// [Contract.maxDeliveryDate] among [contracts] whose [Contract.seasonYear]
/// equals [seasonContractIds] membership.
///
/// Months with zero completed participations are included (count = 0).
/// The list is ordered chronologically (ascending).
/// Returns an empty list when no season contracts exist.
///
/// Only registrations with [RegistrationStatus.completed] are counted, and
/// only for deliveries linked to a contract whose id is in [seasonContractIds].
List<({int year, int month, int count})> seasonMonthlyParticipationCounts(
  Organization org,
  String memberId,
  List<Contract> contracts,
  Set<String> seasonContractIds,
) {
  if (seasonContractIds.isEmpty) return const [];

  // Filter contracts to the ones belonging to the season.
  final seasonContracts = contracts
      .where((c) => seasonContractIds.contains(c.contractId))
      .toList();

  if (seasonContracts.isEmpty) return const [];

  // Determine range bounds.
  int? startYear;
  int? startMonth;
  int? endYear;
  int? endMonth;

  for (final c in seasonContracts) {
    try {
      final minDate = DateTime.parse(c.minDeliveryDate);
      if (startYear == null ||
          minDate.year < startYear ||
          (minDate.year == startYear && minDate.month < startMonth!)) {
        startYear = minDate.year;
        startMonth = minDate.month;
      }
    } catch (_) {}
    try {
      final maxDate = DateTime.parse(c.maxDeliveryDate);
      if (endYear == null ||
          maxDate.year > endYear ||
          (maxDate.year == endYear && maxDate.month > endMonth!)) {
        endYear = maxDate.year;
        endMonth = maxDate.month;
      }
    } catch (_) {}
  }

  if (startYear == null || endYear == null) return const [];

  // Enumerate every month in the [startYear/startMonth .. endYear/endMonth] range.
  final months = <({int year, int month})>[];
  var y = startYear;
  var m = startMonth!;
  while (y < endYear || (y == endYear && m <= endMonth!)) {
    months.add((year: y, month: m));
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }

  // Build a (year, month) → count map from completed registrations.
  final counts = <(int, int), int>{};
  for (final delivery in org.deliveries) {
    final date = DateTime.parse(delivery.scheduledDate);
    for (final contract in delivery.contracts) {
      if (!seasonContractIds.contains(contract.contractId)) continue;
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status == RegistrationStatus.completed) {
            final key = (date.year, date.month);
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
      }
    }
  }

  return months.map((ym) {
    final count = counts[(ym.year, ym.month)] ?? 0;
    return (year: ym.year, month: ym.month, count: count);
  }).toList();
}

/// Activity status thresholds.
///
/// Based on completed participations for the current AMAP season:
///   - ≥ 5 → active
///   - 1–4 → occasional
///   - 0   → inactive
enum MemberActivityStatus {
  /// ≥ 5 completed participations in the season.
  active,

  /// 1–4 completed participations in the season.
  occasional,

  /// 0 completed participations in the season.
  inactive,
}

/// Returns the [MemberActivityStatus] for [memberId] in [org] for the given
/// [seasonContractIds].
MemberActivityStatus memberActivityStatus(
  Organization org,
  String memberId,
  Set<String> seasonContractIds,
) {
  final count = completedRegistrationsInSeason(
    org,
    memberId,
    seasonContractIds,
  );
  if (count >= 5) return MemberActivityStatus.active;
  if (count >= 1) return MemberActivityStatus.occasional;
  return MemberActivityStatus.inactive;
}

/// Result of [memberRankIn]: standard ranking with ex-aequo detection.
///
/// [rank] is the 1-based standard rank (number of members strictly above + 1).
/// [total] is the total count of active members considered.
/// [tied] is true when at least one other active member shares the same count.
typedef MemberRankResult = ({int rank, int total, bool tied});

/// 1-based standard rank of [memberId] among [activeMembers] by completed
/// participations in [seasonContractIds].
///
/// Standard ranking: rank = 1 + (number of members with a strictly higher
/// count). Members with the same count share the same rank (ex-aequo).
/// [tied] is true when at least one other member shares exactly the same count.
///
/// Only members present in [activeMembers] are included in the denominator.
/// Returns null when [memberId] is not found in [activeMembers].
MemberRankResult? memberRankIn(
  Organization org,
  Iterable<Member> activeMembers,
  String memberId,
  Set<String> seasonContractIds,
) {
  final activeMemberList = activeMembers.toList();
  final isMemberActive = activeMemberList.any((m) => m.memberId == memberId);
  if (!isMemberActive) return null;

  // Build (memberId, count) pairs for all active members.
  final scores = activeMemberList.map((m) {
    final count = completedRegistrationsInSeason(
      org,
      m.memberId,
      seasonContractIds,
    );
    return (memberId: m.memberId, count: count);
  }).toList();

  final myScore = scores.firstWhere((s) => s.memberId == memberId);
  final myCount = myScore.count;

  // Standard rank: 1 + number of members with strictly higher count.
  final rank = 1 + scores.where((s) => s.count > myCount).length;

  // tied: at least one OTHER member has the same count.
  final tied = scores.any((s) => s.memberId != memberId && s.count == myCount);

  return (rank: rank, total: scores.length, tied: tied);
}

/// Distribution of active members across activity tiers for the given season.
///
/// Returns the count of active members in each [MemberActivityStatus] bucket:
///   - [MemberActivityStatus.active]     : ≥ 5 participations
///   - [MemberActivityStatus.occasional] : 1–4 participations
///   - [MemberActivityStatus.inactive]   : 0 participations
///
/// Only members in [activeMembers] are counted. [seasonContractIds] scopes
/// participation counting to the current season.
({int active, int occasional, int inactive}) participationDistribution(
  Organization org,
  Iterable<Member> activeMembers,
  Set<String> seasonContractIds,
) {
  var active = 0;
  var occasional = 0;
  var inactive = 0;
  for (final m in activeMembers) {
    final status = memberActivityStatus(org, m.memberId, seasonContractIds);
    switch (status) {
      case MemberActivityStatus.active:
        active++;
      case MemberActivityStatus.occasional:
        occasional++;
      case MemberActivityStatus.inactive:
        inactive++;
    }
  }
  return (active: active, occasional: occasional, inactive: inactive);
}

// ---------------------------------------------------------------------------
// Coordinator selectors
// ---------------------------------------------------------------------------

/// Returns the [Member]s whose [Member.memberId] appears in
/// [contract.coordinators], preserving the order of [contract.coordinators].
///
/// Member ids that are not found in [members] are silently skipped.
List<Member> coordinatorsForContract(
  DeliveryContract contract,
  List<Member> members,
) {
  final memberById = {for (final m in members) m.memberId: m};
  return contract.coordinators
      .map((id) => memberById[id])
      .whereType<Member>()
      .toList();
}

/// Returns the deduplicated union of coordinators across all [delivery.contracts].
///
/// Order is stable: first appearance wins when a member id is present in
/// multiple contracts.
List<Member> coordinatorsFor(Delivery delivery, List<Member> members) {
  final seen = <String>{};
  final result = <Member>[];
  for (final contract in delivery.contracts) {
    for (final coordinator in coordinatorsForContract(contract, members)) {
      if (seen.add(coordinator.memberId)) {
        result.add(coordinator);
      }
    }
  }
  return result;
}

/// Returns true when [memberId] is listed in [contract.coordinators].
bool isCoordinatorOf(DeliveryContract contract, String memberId) =>
    contract.coordinators.contains(memberId);

/// Returns every ([Delivery], [DeliveryContract]) pair in [org] where the
/// delivery is [DeliveryStatus.confirmed] and the contract has no coordinator.
///
/// Deliveries with other statuses (PLANNED, IN_PROGRESS, COMPLETED, CANCELLED)
/// are never included. The order of deliveries and contracts within each
/// delivery is preserved.
List<({Delivery delivery, DeliveryContract contract})>
deliveriesMissingCoordinator(Organization org) {
  final result = <({Delivery delivery, DeliveryContract contract})>[];
  for (final delivery in org.deliveries) {
    if (delivery.status != DeliveryStatus.confirmed) continue;
    for (final contract in delivery.contracts) {
      if (contract.coordinators.isEmpty) {
        result.add((delivery: delivery, contract: contract));
      }
    }
  }
  return result;
}

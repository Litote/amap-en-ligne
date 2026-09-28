import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart'
    show DeliveryTemplate;
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/volunteer_need.dart';

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
/// [include], when given, filters the candidates before the [limit] applies.
List<Delivery> upcomingActiveDeliveries(
  Organization org,
  DateTime now, {
  int limit = 5,
  bool Function(Delivery)? include,
}) {
  final result =
      org.deliveries.where((d) {
        if (!d.status.isActive) return false;
        if (include != null && !include(d)) return false;
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

/// Whether a member holding [roles] may see contracts still IN_PREPARATION:
/// only coordinators and admins do, plain members never see them.
bool canSeeContractsInPreparation(Iterable<Role> roles) =>
    roles.contains(Role.coordinator) || roles.contains(Role.admin);

/// Display-only view of [delivery] for a viewer who may not see IN_PREPARATION
/// contracts (see [canSeeContractsInPreparation]): drops the links to such
/// contracts and the basket descriptions of the products only they bring.
///
/// A contract's products are the product types of its prices, or every
/// product of its producer in [org] for a legacy price-less contract. Links
/// whose contract is unknown in [contracts] are kept.
///
/// Rendering only — never enqueue the result: it would delete the hidden
/// links server-side.
Delivery deliveryWithoutInPreparationContracts(
  Delivery delivery,
  Organization org,
  List<Contract> contracts,
) {
  final contractsById = {for (final c in contracts) c.contractId: c};
  bool isHidden(DeliveryContract link) =>
      contractsById[link.contractId]?.status == ContractStatus.inPreparation;
  if (!delivery.contracts.any(isHidden)) return delivery;

  final visibleLinks = delivery.contracts.where((l) => !isHidden(l)).toList();
  final hiddenProducts = _productsOfLinks(
    delivery.contracts.where(isHidden),
    contractsById,
    org,
  );
  final visibleProducts = _productsOfLinks(visibleLinks, contractsById, org);
  return delivery.copyWith(
    contracts: visibleLinks,
    basketDescriptions: delivery.basketDescriptions
        .where(
          (d) =>
              !hiddenProducts.contains(d.productTypeId) ||
              visibleProducts.contains(d.productTypeId),
        )
        .toList(),
  );
}

/// Product types brought by the contracts of [links] (unknown contracts
/// bring none).
Set<String> _productsOfLinks(
  Iterable<DeliveryContract> links,
  Map<String, Contract> contractsById,
  Organization org,
) => {
  for (final link in links)
    if (contractsById[link.contractId] case final contract?)
      ..._contractProducts(contract, org),
};

/// The product types of [contract]'s prices, or every product of its
/// producer in [org] for a legacy price-less contract.
Set<String> _contractProducts(Contract contract, Organization org) =>
    contract.productPrices.isNotEmpty
    ? {for (final price in contract.productPrices) price.productTypeId}
    : {
        for (final product in org.products)
          if (product.producerAccountId == contract.producerAccountId)
            product.productTypeId,
      };

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
/// non-coordinator active registrations and [MemberSlot.requiredVolunteers]
/// over all **non-cancelled** slots of every contract, counting STANDARD and
/// EARLY slots alike.
///
/// Coordinators listed in [DeliveryContract.coordinators] are excluded from
/// [current] so their presence on a slot does not inflate the volunteer count.
///
/// This is the single source of truth for the "N/M bénévoles" counter shown
/// across the member planning, the dashboards and the coordinator screens
/// (cf. UI specs `screen-member-01/02`, `screen-coordinator-01/02`, which sum
/// `requiredVolunteers` over every slot). CANCELLED slots accept no registration
/// and never count toward capacity.
/// Returns the ids of the contracts flagged as "main" ([Contract.isMainContract])
/// among [contracts].
///
/// Only main contracts (e.g. the vegetable contract) require volunteers; the
/// secondary contracts of a delivery (eggs, fruit…) mobilise only the
/// coordinator. Pass the result to [deliveryVolunteerStaffing] /
/// [deliverySlotStatus] so the counter ignores the secondary contracts.
Set<String> mainContractIdsOf(List<Contract> contracts) => {
  for (final c in contracts)
    if (c.isMainContract) c.contractId,
};

/// Returns the [DeliveryContract]s of [delivery] that drive the volunteer need.
///
/// When [mainContractIds] flags at least one of the delivery's contracts as
/// main, only those are kept; otherwise every contract is kept (legacy
/// fallback, so deliveries with no main contract behave as before).
List<DeliveryContract> _volunteerCountingContracts(
  Delivery delivery,
  Set<String> mainContractIds,
) {
  final mains = delivery.contracts
      .where((c) => mainContractIds.contains(c.contractId))
      .toList();
  return mains.isEmpty ? delivery.contracts : mains;
}

/// Returns the deduplicated ids of every coordinator across all of [delivery]'s
/// contracts — these never count toward the volunteer total even when they
/// register on a slot owned by another contract.
Set<String> deliveryCoordinatorIds(Delivery delivery) => {
  for (final contract in delivery.contracts) ...contract.coordinators,
};

({int current, int required}) deliveryVolunteerStaffing(
  Delivery delivery, {
  Set<String> mainContractIds = const {},
}) {
  final coordinatorIds = deliveryCoordinatorIds(delivery);
  var current = 0;
  var required = 0;
  for (final contract in _volunteerCountingContracts(
    delivery,
    mainContractIds,
  )) {
    for (final slot in contract.slots) {
      if (slot.status == SlotStatus.cancelled) continue;
      required += slot.requiredVolunteers;
      current += activeRegistrationsExcluding(slot, coordinatorIds);
    }
  }
  return (current: current, required: required);
}

/// The contract links of [delivery] with baskets to collect: a link without
/// any basket (e.g. a contract still in preparation) has nothing to pick up
/// and must not hold back the collection progress.
List<DeliveryContract> deliveryContractsToCollect(Delivery delivery) => [
  for (final contract in delivery.contracts)
    if (contract.basketQuantity > 0) contract,
];

/// Derives a single [SlotStatus] summarising the volunteer staffing of
/// [delivery], used by the coordinator list chips.
///
/// - Inactive delivery (COMPLETED / CANCELLED) → [SlotStatus.closed].
/// - No required volunteers → [SlotStatus.open].
/// - Fully staffed (ratio ≥ 1) → [SlotStatus.full].
/// - Half staffed or more (ratio ≥ 0.5) → [SlotStatus.open].
/// - Otherwise → [SlotStatus.critical], except when [now] is given and the
///   delivery starts more than [kUrgentNeedWindow] later → [SlotStatus.open]
///   (same urgency rule as the member badge, `volunteerNeedLevel`).
SlotStatus deliverySlotStatus(
  Delivery delivery, {
  Set<String> mainContractIds = const {},
  DateTime? now,
}) {
  if (!delivery.status.isActive) return SlotStatus.closed;
  final coordinatorIds = deliveryCoordinatorIds(delivery);
  var total = 0;
  var filled = 0;
  for (final contract in _volunteerCountingContracts(
    delivery,
    mainContractIds,
  )) {
    for (final slot in contract.slots) {
      total += slot.requiredVolunteers;
      filled += activeRegistrationsExcluding(slot, coordinatorIds);
    }
  }
  if (total == 0) return SlotStatus.open;
  final ratio = filled / total;
  if (ratio >= 1.0) return SlotStatus.full;
  if (ratio >= 0.5) return SlotStatus.open;
  if (now != null &&
      DateTime.parse(delivery.scheduledDate).difference(now) >
          kUrgentNeedWindow) {
    return SlotStatus.open;
  }
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

/// Counts active (non-CANCELLED) registrations on [slot] that do not belong to
/// any of [contract]'s coordinators.
///
/// Prefer [activeRegistrationsExcluding] with the delivery-wide coordinator set
/// ([deliveryCoordinatorIds]) for the volunteer counter, so a coordinator of
/// another linked contract registered on this slot is also excluded.
int nonCoordinatorActiveRegistrations(
  MemberSlot slot,
  DeliveryContract contract,
) => activeRegistrationsExcluding(slot, contract.coordinators.toSet());

/// Counts active (non-CANCELLED) registrations on [slot] whose member id is not
/// in [coordinatorIds].
///
/// Used as the single source for the "N/M bénévoles" volunteer counter so that
/// coordinators present on a slot are not counted toward volunteer capacity.
int activeRegistrationsExcluding(MemberSlot slot, Set<String> coordinatorIds) =>
    slot.registrations
        .where(
          (r) =>
              r.status != RegistrationStatus.cancelled &&
              !coordinatorIds.contains(r.memberId),
        )
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

/// Whether a registration with [status] records the volunteer as present.
///
/// The delivery-tracking screen marks presence as [RegistrationStatus.confirmed]
/// and imported or legacy data may carry [RegistrationStatus.completed]: both
/// are a participation for history, ranking and statistics.
bool isPresentRegistrationStatus(RegistrationStatus status) =>
    status == RegistrationStatus.confirmed ||
    status == RegistrationStatus.completed;

/// Whether [contract] has any completed registration for [memberId].
bool _hasCompletedRegistration(DeliveryContract contract, String memberId) {
  for (final slot in contract.slots) {
    for (final reg in slot.registrations) {
      if (reg.memberId == memberId && isPresentRegistrationStatus(reg.status)) {
        return true;
      }
    }
  }
  return false;
}

/// Counts completed registrations for [memberId] across [contract]'s slots.
int _completedRegistrationCount(DeliveryContract contract, String memberId) {
  var count = 0;
  for (final slot in contract.slots) {
    for (final reg in slot.registrations) {
      if (reg.memberId == memberId && isPresentRegistrationStatus(reg.status)) {
        count++;
      }
    }
  }
  return count;
}

/// Counts present [MemberRegistration]s ([isPresentRegistrationStatus]) for
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
      if (seasonContractIds.contains(contract.contractId)) {
        count += _completedRegistrationCount(contract, memberId);
      }
    }
  }
  return count;
}

/// Returns the [Delivery] of the most recent present ([isPresentRegistrationStatus])
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
    final hasCompleted = delivery.contracts.any(
      (contract) =>
          seasonContractIds.contains(contract.contractId) &&
          _hasCompletedRegistration(contract, memberId),
    );
    if (!hasCompleted) continue;
    final date = DateTime.parse(delivery.scheduledDate);
    if (latestDate == null || date.isAfter(latestDate)) {
      latestDate = date;
      latest = delivery;
    }
  }
  return latest;
}

/// Returns the [Delivery] of the most recent present ([isPresentRegistrationStatus])
/// registration for [memberId], or null if none exists.
///
/// Searches across all deliveries regardless of season.
Delivery? lastCompletedDelivery(Organization org, String memberId) {
  Delivery? latest;
  DateTime? latestDate;
  for (final delivery in org.deliveries) {
    final hasCompleted = delivery.contracts.any(
      (contract) => _hasCompletedRegistration(contract, memberId),
    );
    if (!hasCompleted) continue;
    final date = DateTime.parse(delivery.scheduledDate);
    if (latestDate == null || date.isAfter(latestDate)) {
      latestDate = date;
      latest = delivery;
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

/// Registrations recording the member as present ([isPresentRegistrationStatus]).
///
/// Sorted descending by [Delivery.scheduledDate] (most recent first).
List<({Delivery delivery, MemberRegistration registration})>
personalCompletedRegistrations(Organization org, String memberId) {
  final all =
      personalRegistrations(org, memberId)
          .where((e) => isPresentRegistrationStatus(e.registration.status))
          .toList()
        ..sort(
          (a, b) => DateTime.parse(
            b.delivery.scheduledDate,
          ).compareTo(DateTime.parse(a.delivery.scheduledDate)),
        );
  return all;
}

/// All registrations across every slot/contract of [delivery], flattened.
Iterable<MemberRegistration> _allRegistrations(Delivery delivery) sync* {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      yield* slot.registrations;
    }
  }
}

/// Counts non-cancelled registrations for [memberId] across [contract]'s slots.
int _activeRegistrationCount(DeliveryContract contract, String memberId) {
  var count = 0;
  for (final slot in contract.slots) {
    for (final reg in slot.registrations) {
      if (reg.memberId == memberId &&
          reg.status != RegistrationStatus.cancelled) {
        count++;
      }
    }
  }
  return count;
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
    for (final reg in _allRegistrations(delivery)) {
      if (reg.memberId == memberId &&
          reg.status != RegistrationStatus.cancelled) {
        result.add((delivery: delivery, registration: reg));
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

/// Activity of the slot [selfMemberId] holds an active (non-cancelled)
/// registration on for [delivery], or `null` when they hold none.
ActivityType? selfActivityOn(Delivery delivery, String selfMemberId) {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      final registered = slot.registrations.any(
        (reg) =>
            reg.memberId == selfMemberId &&
            reg.status != RegistrationStatus.cancelled,
      );
      if (registered) return slot.activityType;
    }
  }
  return null;
}

/// Other registered members on [delivery], excluding [selfMemberId].
///
/// Returns the first non-cancelled, non-self registration per member (deduped
/// by memberId across all slots/contracts of the delivery).
List<MemberRegistration> teammatesOn(Delivery delivery, String selfMemberId) {
  final seen = <String>{};
  final result = <MemberRegistration>[];
  for (final reg in _allRegistrations(delivery)) {
    if (reg.memberId == selfMemberId) continue;
    if (reg.status == RegistrationStatus.cancelled) continue;
    if (seen.add(reg.memberId)) result.add(reg);
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
      if (seasonContractIds.contains(contract.contractId)) {
        count += _activeRegistrationCount(contract, memberId);
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
    final minYear = DateTime.tryParse(c.minDeliveryDate)?.year;
    if (minYear != null && (startYear == null || minYear < startYear)) {
      startYear = minYear;
    }
    final maxYear = DateTime.tryParse(c.maxDeliveryDate)?.year;
    if (maxYear != null && (endYear == null || maxYear > endYear)) {
      endYear = maxYear;
    }
  }

  if (startYear == null || endYear == null) {
    return 'Saison ${now.year}';
  }

  if (startYear == endYear) {
    return 'Saison $startYear';
  }
  return 'Saison $startYear-$endYear';
}

/// Earliest (year, month) among [contracts] by [Contract.minDeliveryDate],
/// or null when none has a parseable date.
({int year, int month})? _earliestMonth(List<Contract> contracts) {
  ({int year, int month})? earliest;
  for (final c in contracts) {
    final date = DateTime.tryParse(c.minDeliveryDate);
    if (date == null) continue;
    if (earliest == null ||
        date.year < earliest.year ||
        (date.year == earliest.year && date.month < earliest.month)) {
      earliest = (year: date.year, month: date.month);
    }
  }
  return earliest;
}

/// Latest (year, month) among [contracts] by [Contract.maxDeliveryDate],
/// or null when none has a parseable date.
({int year, int month})? _latestMonth(List<Contract> contracts) {
  ({int year, int month})? latest;
  for (final c in contracts) {
    final date = DateTime.tryParse(c.maxDeliveryDate);
    if (date == null) continue;
    if (latest == null ||
        date.year > latest.year ||
        (date.year == latest.year && date.month > latest.month)) {
      latest = (year: date.year, month: date.month);
    }
  }
  return latest;
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
/// Only present registrations ([isPresentRegistrationStatus]) are counted, and
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
  final start = _earliestMonth(seasonContracts);
  final end = _latestMonth(seasonContracts);
  if (start == null || end == null) return const [];

  final months = _enumerateMonths(start, end);
  final counts = _monthlyCompletedCounts(org, memberId, seasonContractIds);

  return months.map((ym) {
    final count = counts[(ym.year, ym.month)] ?? 0;
    return (year: ym.year, month: ym.month, count: count);
  }).toList();
}

/// Every `(year, month)` in the inclusive `[start .. end]` range, ascending.
List<({int year, int month})> _enumerateMonths(
  ({int year, int month}) start,
  ({int year, int month}) end,
) {
  final months = <({int year, int month})>[];
  var y = start.year;
  var m = start.month;
  while (y < end.year || (y == end.year && m <= end.month)) {
    months.add((year: y, month: m));
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }
  return months;
}

/// `(year, month) → completed-registration count` for [memberId] across the
/// deliveries linked to a contract in [seasonContractIds].
Map<(int, int), int> _monthlyCompletedCounts(
  Organization org,
  String memberId,
  Set<String> seasonContractIds,
) {
  final counts = <(int, int), int>{};
  for (final delivery in org.deliveries) {
    final date = DateTime.parse(delivery.scheduledDate);
    final key = (date.year, date.month);
    for (final contract in delivery.contracts) {
      if (seasonContractIds.contains(contract.contractId)) {
        final completed = _completedRegistrationCount(contract, memberId);
        if (completed > 0) counts[key] = (counts[key] ?? 0) + completed;
      }
    }
  }
  return counts;
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

// ---------------------------------------------------------------------------
// Planning selectors
// ---------------------------------------------------------------------------

/// Returns the month to display by default on the planning screen.
///
/// The month of the next delivery at or after [now] — the current month while
/// one remains in it, else a later month instead of an empty one. Without any
/// upcoming delivery: the next month when the current month's deliveries have
/// all passed, else the current month.
DateTime defaultPlanningMonth(Organization org, DateTime now) {
  final currentMonth = DateTime(now.year, now.month);
  final dates = org.deliveries.map((d) => DateTime.parse(d.scheduledDate));
  final upcoming = dates.where((date) => !date.isBefore(now)).toList();
  if (upcoming.isNotEmpty) {
    final next = upcoming.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(next.year, next.month);
  }
  final pastThisMonth = dates.any(
    (date) => date.year == now.year && date.month == now.month,
  );
  return pastThisMonth ? DateTime(now.year, now.month + 1) : currentMonth;
}

import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_slots.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Result of [planWeeklyDeliveries]: the updated deliveries list for the
/// organization, together with counters describing what changed.
class WeeklyDeliveryPlan {
  const WeeklyDeliveryPlan({
    required this.deliveries,
    required this.newCount,
    required this.linkedCount,
  });

  /// The full deliveries list for the organization (existing + new/linked).
  final List<Delivery> deliveries;

  /// Number of new [Delivery] objects that will be created (tmp_* ids).
  final int newCount;

  /// Number of existing deliveries that will be linked to the contract.
  final int linkedCount;

  /// Total number of deliveries affected (created or linked).
  int get totalAffected => newCount + linkedCount;
}

/// Builds a [WeeklyDeliveryPlan] for [contract] over its full date range.
///
/// For each Monday-to-Sunday week from [Contract.minDeliveryDate] to
/// [Contract.maxDeliveryDate] (step = 7 days), the algorithm:
/// - If a non-cancelled delivery already exists on that exact date:
///   links [contract] to it (unless already linked).
/// - Otherwise creates a new [Delivery] with a `tmp_*` id.
///
/// The [template] parameter must be pre-resolved by the caller (null if none
/// is available). When [template] is provided, its [DeliveryTemplate.standardStartTime]
/// (format `HH:MM`) sets the time component of new deliveries; otherwise
/// defaults to 18:00.
///
/// [nextTmpId] is called once per new delivery and must return a unique
/// integer used to build the `tmp_delivery_<n>` id.
///
/// Returns the original [org.deliveries] list when [Contract.minDeliveryDate]
/// or [Contract.maxDeliveryDate] cannot be parsed.
WeeklyDeliveryPlan planWeeklyDeliveries({
  required Contract contract,
  required Organization org,
  DeliveryTemplate? template,
  required int Function() nextTmpId,
}) {
  final min = DateTime.tryParse(contract.minDeliveryDate);
  final max = DateTime.tryParse(contract.maxDeliveryDate);
  if (min == null || max == null) {
    return WeeklyDeliveryPlan(
      deliveries: org.deliveries,
      newCount: 0,
      linkedCount: 0,
    );
  }

  // Index existing non-cancelled deliveries by date-only key 'YYYY-MM-DD'.
  final existingByDate = _indexByDate(org.deliveries);

  final deliveryContract = DeliveryContract(
    contractId: contract.contractId,
    basketQuantity: _contractBasketQuantity(contract),
    deliveryDescription: contract.name,
    status: DeliveryContractStatus.pending,
    coordinators: const [],
  );
  final basketDescriptions = _contractBasketDescriptions(contract, org);

  // Work on a mutable map: date-key → updated delivery.
  final updatedByDate = <String, Delivery>{...existingByDate};
  int newCount = 0;
  int linkedCount = 0;

  var current = min;
  while (!current.isAfter(max)) {
    final key = _dateKey(current);
    final existing = existingByDate[key];

    if (existing != null) {
      final linked = _linkContractToDelivery(
        existing,
        deliveryContract,
        contract.contractId,
        isMainContract: contract.isMainContract,
        template: template,
      );
      if (linked != null) {
        updatedByDate[key] = linked;
        linkedCount++;
      }
    } else {
      updatedByDate[key] = _buildWeeklyDelivery(
        date: current,
        org: org,
        deliveryContract: deliveryContract,
        basketDescriptions: basketDescriptions,
        template: template,
        isMainContract: contract.isMainContract,
        nextTmpId: nextTmpId,
      );
      newCount++;
    }

    current = current.add(const Duration(days: 7));
  }

  // Rebuild the full deliveries list preserving original order, then
  // appending newly created deliveries sorted by date.
  final result = _rebuildDeliveries(org.deliveries, updatedByDate);

  return WeeklyDeliveryPlan(
    deliveries: result,
    newCount: newCount,
    linkedCount: linkedCount,
  );
}

/// Indexes non-cancelled [deliveries] by date-only key 'YYYY-MM-DD'.
Map<String, Delivery> _indexByDate(List<Delivery> deliveries) {
  final byDate = <String, Delivery>{};
  for (final d in deliveries) {
    if (d.status == DeliveryStatus.cancelled) continue;
    final dt = DateTime.tryParse(d.scheduledDate);
    if (dt == null) continue;
    byDate[_dateKey(dt)] = d;
  }
  return byDate;
}

/// Links [deliveryContract] to [existing], or returns null when the delivery is
/// already linked to [contractId].
///
/// Volunteer slots live only on the main contract: when [isMainContract] is true
/// and the existing delivery carries no slot yet (e.g. it was created by a
/// secondary contract first), the default volunteer slots are attached to this
/// main link so the volunteer need is materialised exactly once.
Delivery? _linkContractToDelivery(
  Delivery existing,
  DeliveryContract deliveryContract,
  String contractId, {
  required bool isMainContract,
  required DeliveryTemplate? template,
}) {
  final alreadyLinked = existing.contracts.any(
    (dc) => dc.contractId == contractId,
  );
  if (alreadyLinked) return null;
  final deliveryHasSlots = existing.contracts.any((c) => c.slots.isNotEmpty);
  final scheduled = DateTime.tryParse(existing.scheduledDate);
  final link = isMainContract && !deliveryHasSlots && scheduled != null
      ? deliveryContract.copyWith(
          slots: defaultVolunteerSlots(
            scheduled: scheduled,
            requiredVolunteers:
                template?.desiredVolunteerCount ??
                existing.minVolunteersRequired,
            template: template,
          ),
        )
      : deliveryContract;
  return existing.copyWith(contracts: [...existing.contracts, link]);
}

/// Builds a brand-new weekly [Delivery] on [date] for [deliveryContract].
Delivery _buildWeeklyDelivery({
  required DateTime date,
  required Organization org,
  required DeliveryContract deliveryContract,
  required List<BasketDeliveryDescription> basketDescriptions,
  required DeliveryTemplate? template,
  required bool isMainContract,
  required int Function() nextTmpId,
}) {
  final hour = _resolveStartHour(template);
  final minute = _resolveStartMinute(template);
  final scheduledDate = DateTime(date.year, date.month, date.day, hour, minute);
  final requiredVolunteers = template?.desiredVolunteerCount ?? 1;
  // Volunteer slots are materialised only on the main contract — secondary
  // contracts (eggs, fruit…) mobilise only the coordinator, no volunteer.
  final link = isMainContract
      ? deliveryContract.copyWith(
          slots: defaultVolunteerSlots(
            scheduled: scheduledDate,
            requiredVolunteers: requiredVolunteers,
            template: template,
          ),
        )
      : deliveryContract;
  return Delivery(
    deliveryId: 'tmp_delivery_${nextTmpId()}',
    organizationId: org.organizationId,
    scheduledDate: scheduledDate.toIso8601String().split('.').first,
    status: DeliveryStatus.planned,
    minVolunteersRequired: requiredVolunteers,
    deliveryTemplateId: template?.deliveryTemplateId,
    basketDescriptions: basketDescriptions,
    contracts: [link],
  );
}

/// Rebuilds the deliveries list: [original] order preserved (each replaced by
/// its updated version when present), then new entries appended ordered by date.
List<Delivery> _rebuildDeliveries(
  List<Delivery> original,
  Map<String, Delivery> updatedByDate,
) {
  final result = <Delivery>[];
  final seen = <String>{};
  for (final d in original) {
    final dt = DateTime.tryParse(d.scheduledDate);
    final key = dt != null ? _dateKey(dt) : null;
    if (key != null && updatedByDate.containsKey(key)) {
      result.add(updatedByDate[key]!);
      seen.add(key);
    } else {
      result.add(d);
    }
  }
  final newEntries =
      updatedByDate.entries.where((e) => !seen.contains(e.key)).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in newEntries) {
    result.add(entry.value);
  }
  return result;
}

/// The product-type ids allowed for [contract]: those referenced by its product
/// prices, or every product of its producer for a legacy price-less contract.
Set<String> _allowedProductTypeIds(Contract contract, Organization org) {
  if (contract.productPrices.isNotEmpty) {
    return {for (final price in contract.productPrices) price.productTypeId};
  }
  return {
    for (final product in org.products)
      if (product.producerAccountId == contract.producerAccountId)
        product.productTypeId,
  };
}

/// Default basket descriptions for a delivery generated from [contract]: the
/// products referenced by the contract's product prices (or every product of
/// the contract's producer for a legacy contract without any price entry),
/// one entry per supported basket size — mirroring what the delivery form
/// saves when those products are selected.
List<BasketDeliveryDescription> _contractBasketDescriptions(
  Contract contract,
  Organization org,
) {
  final allowed = _allowedProductTypeIds(contract, org);
  final descriptions = <BasketDeliveryDescription>[];
  final seenKeys = <String>{};
  for (final product in org.products) {
    if (!allowed.contains(product.productTypeId)) continue;
    for (final basketSize in product.supportedBasketSizes) {
      final key = '${product.productTypeId}::${basketSize.name}';
      if (!seenKeys.add(key)) continue;
      descriptions.add(
        BasketDeliveryDescription(
          productTypeId: product.productTypeId,
          basketSizeName: basketSize.name,
        ),
      );
    }
  }
  return descriptions;
}

/// Resolves the contract to plan deliveries against, given a freshly read
/// [contracts] list and the [saved] contract returned by the creation call.
///
/// A sync may complete between the optimistic creation and the moment the
/// plan is applied, remapping the contract's `tmp_*` id to its server id (the
/// tmp row disappears from the cache). Resolution order: exact id match, then
/// natural key (organization, producer, name, season, date range), then
/// [saved] itself when the cache has no candidate yet.
Contract resolveSavedContract(List<Contract> contracts, Contract saved) {
  for (final contract in contracts) {
    if (contract.contractId == saved.contractId) return contract;
  }
  for (final contract in contracts) {
    if (contract.organizationId == saved.organizationId &&
        contract.producerAccountId == saved.producerAccountId &&
        contract.name == saved.name &&
        contract.seasonYear == saved.seasonYear &&
        contract.minDeliveryDate == saved.minDeliveryDate &&
        contract.maxDeliveryDate == saved.maxDeliveryDate) {
      return contract;
    }
  }
  return saved;
}

/// Calculates the basket quantity for a contract: number of subscriptions
/// across all active members.
int _contractBasketQuantity(Contract contract) {
  var quantity = 0;
  for (final member in contract.members) {
    if (member.status != ContractMemberStatus.active) continue;
    quantity += member.subscriptions.length;
  }
  return quantity;
}

String _dateKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

int _resolveStartHour(DeliveryTemplate? template) {
  if (template == null) return 18;
  final parts = template.standardStartTime.split(':');
  if (parts.isEmpty) return 18;
  return int.tryParse(parts[0]) ?? 18;
}

int _resolveStartMinute(DeliveryTemplate? template) {
  if (template == null) return 0;
  final parts = template.standardStartTime.split(':');
  if (parts.length < 2) return 0;
  return int.tryParse(parts[1]) ?? 0;
}

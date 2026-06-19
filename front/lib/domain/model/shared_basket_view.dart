import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Pure selectors for shared baskets (groups of members alternating on a single physical basket).
///
/// The alternation formula is mirrored verbatim from the back (`SharedBasketAlternation.kt`) and
/// pinned by the shared acceptance scenario:
///  - order the contract's deliveries by `(scheduledDate, deliveryId)`,
///  - `a` = index of the basket's `anchorDeliveryId` (0 if null/unknown),
///  - `p` = index of the target delivery,
///  - picker = `memberIds[((p - a) % n + n) % n]`.

/// Returns the deliveries linked to [contractId], ordered by `(scheduledDate, deliveryId)`.
List<Delivery> contractDeliveriesOrdered(Organization org, String contractId) {
  final linked = org.deliveries
      .where((d) => d.contracts.any((c) => c.contractId == contractId))
      .toList();
  linked.sort((a, b) {
    final byDate = a.scheduledDate.compareTo(b.scheduledDate);
    return byDate != 0 ? byDate : a.deliveryId.compareTo(b.deliveryId);
  });
  return linked;
}

/// The member id that picks up [basket] at [deliveryId], or null when the basket has no members
/// or [deliveryId] is not one of the contract's [orderedDeliveries].
String? sharedBasketPickerFor(
  SharedBasket basket,
  List<Delivery> orderedDeliveries,
  String deliveryId,
) {
  final n = basket.memberIds.length;
  if (n == 0) return null;
  final p = orderedDeliveries.indexWhere((d) => d.deliveryId == deliveryId);
  if (p < 0) return null;
  var a = 0;
  final anchor = basket.anchorDeliveryId;
  if (anchor != null) {
    final anchorIndex = orderedDeliveries.indexWhere(
      (d) => d.deliveryId == anchor,
    );
    if (anchorIndex >= 0) a = anchorIndex;
  }
  final index = ((p - a) % n + n) % n;
  return basket.memberIds[index];
}

/// For a given delivery, the picker member id per shared basket of [contract].
/// Keyed by `sharedBasketId`.
Map<String, String> sharedBasketPickupsForDelivery(
  Contract contract,
  List<Delivery> orderedDeliveries,
  String deliveryId,
) {
  final result = <String, String>{};
  for (final basket in contract.sharedBaskets) {
    final picker = sharedBasketPickerFor(basket, orderedDeliveries, deliveryId);
    if (picker != null) result[basket.sharedBasketId] = picker;
  }
  return result;
}

/// The shared basket of [contract] that [memberId] belongs to, or null.
SharedBasket? sharedBasketForMember(Contract contract, String memberId) {
  for (final basket in contract.sharedBaskets) {
    if (basket.memberIds.contains(memberId)) return basket;
  }
  return null;
}

/// Whether [memberId] is the one picking up the basket at [deliveryId] (only meaningful when the
/// member belongs to a shared basket of [contract]).
bool memberPicksUpOn(
  Contract contract,
  List<Delivery> orderedDeliveries,
  String deliveryId,
  String memberId,
) {
  final basket = sharedBasketForMember(contract, memberId);
  if (basket == null) return false;
  return sharedBasketPickerFor(basket, orderedDeliveries, deliveryId) ==
      memberId;
}

/// The deliveries (ordered) at which [memberId] picks up the shared basket on [contract].
List<Delivery> pickupDeliveriesFor(
  Contract contract,
  List<Delivery> orderedDeliveries,
  String memberId,
) {
  final basket = sharedBasketForMember(contract, memberId);
  if (basket == null) return const [];
  return orderedDeliveries
      .where(
        (d) =>
            sharedBasketPickerFor(basket, orderedDeliveries, d.deliveryId) ==
            memberId,
      )
      .toList();
}

/// Whether [memberId] effectively holds [contract]'s basket on [deliveryId].
///
/// A member who is not part of any shared basket always holds their own basket; a member who
/// shares a basket holds it only on the deliveries where the alternation designates them as the
/// picker. Mirrors the back `Contract.holdsBasketOn`. [orderedDeliveries] = [contractDeliveriesOrdered].
bool memberHoldsBasketOn(
  Contract contract,
  List<Delivery> orderedDeliveries,
  String deliveryId,
  String memberId,
) {
  final basket = sharedBasketForMember(contract, memberId);
  if (basket == null) return true;
  return sharedBasketPickerFor(basket, orderedDeliveries, deliveryId) ==
      memberId;
}

/// The co-sharers of [memberId] inside their shared basket on [contract] (excludes [memberId]).
List<String> coSharersFor(Contract contract, String memberId) {
  final basket = sharedBasketForMember(contract, memberId);
  if (basket == null) return const [];
  return basket.memberIds.where((id) => id != memberId).toList();
}

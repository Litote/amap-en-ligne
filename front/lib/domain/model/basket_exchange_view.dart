import 'package:amap_en_ligne/domain/model/basket_exchange.dart';

/// Pure selectors over a member's basket exchanges, shared by the dashboard
/// card, the screen sections and the global overview. Zero Flutter / IO deps.

/// Compact, actionable summary of a member's ongoing basket exchanges.
class BasketExchangeSummary {
  const BasketExchangeSummary({
    required this.requestsToValidate,
    required this.proposalsAwaitingValidation,
    required this.confirmedExchanges,
  });

  /// Pending requests across my OPEN offers — I (the offerer) must validate or refuse.
  final int requestsToValidate;

  /// My own pending requests on others' OPEN offers — awaiting their validation.
  final int proposalsAwaitingValidation;

  /// Confirmed (ACCEPTED) exchanges I am involved in (offerer or accepted requester).
  final int confirmedExchanges;

  /// Whether there is anything worth surfacing on the home dashboard.
  bool get hasActivity =>
      requestsToValidate > 0 ||
      proposalsAwaitingValidation > 0 ||
      confirmedExchanges > 0;
}

/// Derives a [BasketExchangeSummary] for [memberId] from [all] exchanges.
BasketExchangeSummary basketExchangeSummaryFor(
  List<BasketExchange> all,
  String memberId,
) {
  var toValidate = 0;
  var awaiting = 0;
  var confirmed = 0;
  for (final e in all) {
    if (e.status == BasketExchangeStatus.open) {
      if (e.offeringMemberId == memberId) {
        toValidate += e.requests
            .where((r) => r.status == BasketExchangeRequestStatus.pending)
            .length;
      } else {
        final mine = e.requests.any(
          (r) =>
              r.requesterMemberId == memberId &&
              r.status == BasketExchangeRequestStatus.pending,
        );
        if (mine) awaiting++;
      }
    } else if (e.status == BasketExchangeStatus.accepted &&
        _isConfirmedFor(e, memberId)) {
      confirmed++;
    }
  }
  return BasketExchangeSummary(
    requestsToValidate: toValidate,
    proposalsAwaitingValidation: awaiting,
    confirmedExchanges: confirmed,
  );
}

/// Number of PENDING requests on an OPEN offer (offerer's "à valider" badge).
int pendingRequestCount(BasketExchange offer) => offer.requests
    .where((r) => r.status == BasketExchangeRequestStatus.pending)
    .length;

/// The delivery ids that [e] commits for [memberId] (see [committedDeliveryIdsFor]).
Iterable<String> _committedByExchange(BasketExchange e, String memberId) sync* {
  if (e.offeringMemberId == memberId &&
      (e.status == BasketExchangeStatus.open ||
          e.status == BasketExchangeStatus.accepted)) {
    yield e.deliveryId;
  }
  if (e.status != BasketExchangeStatus.accepted) return;
  final acceptedId = e.acceptedRequestId;
  if (acceptedId == null) return;
  final accepted = e.requests
      .where((r) => r.requestId == acceptedId)
      .firstOrNull;
  if (accepted == null) return;
  final involvesMember =
      e.offeringMemberId == memberId || accepted.requesterMemberId == memberId;
  if (!involvesMember) return;
  yield e.deliveryId;
  final counter = accepted.proposedDeliveryId;
  if (counter != null) yield counter;
}

/// Delivery ids whose basket [memberId] has already committed in another exchange
/// — so it cannot be re-offered or re-proposed. A basket is committed when it is
/// currently offered (OPEN/ACCEPTED) or has been given away **or received** through
/// a settled (ACCEPTED) exchange. In an accepted exchange both deliveries change
/// hands (the offerer gives D1 and receives D2, the requester gives D2 and receives
/// D1), so both are committed for both parties. Mirrors the back's
/// `isBasketCommitted` guard so the UI hides ineligible deliveries.
Set<String> committedDeliveryIdsFor(List<BasketExchange> all, String memberId) {
  final committed = <String>{};
  for (final e in all) {
    committed.addAll(_committedByExchange(e, memberId));
  }
  return committed;
}

/// For a given delivery, maps each member whose basket is collected by **someone
/// else** (because of a confirmed exchange) to that collector's member id.
///
/// Confirmed (ACCEPTED) exchange on delivery D:
/// - if D is the offered delivery (D1): the offerer's basket is collected by the
///   accepted requester (`offerer → requester`);
/// - if D is the accepted counter-delivery (D2): the requester's basket is
///   collected by the offerer (`requester → offerer`).
Map<String, String> basketPickupsForDelivery(
  List<BasketExchange> all,
  String deliveryId,
) {
  final pickups = <String, String>{};
  for (final e in all) {
    if (e.status != BasketExchangeStatus.accepted) continue;
    final acceptedId = e.acceptedRequestId;
    if (acceptedId == null) continue;
    final accepted = e.requests
        .where((r) => r.requestId == acceptedId)
        .firstOrNull;
    if (accepted == null) continue;
    if (e.deliveryId == deliveryId) {
      // D1 — offerer absent, requester collects.
      pickups[e.offeringMemberId] = accepted.requesterMemberId;
    } else if (accepted.proposedDeliveryId == deliveryId) {
      // D2 — requester absent, offerer collects.
      pickups[accepted.requesterMemberId] = e.offeringMemberId;
    }
  }
  return pickups;
}

bool _isConfirmedFor(BasketExchange e, String memberId) {
  if (e.offeringMemberId == memberId) return true;
  final acceptedId = e.acceptedRequestId;
  if (acceptedId == null) return false;
  return e.requests.any(
    (r) => r.requestId == acceptedId && r.requesterMemberId == memberId,
  );
}

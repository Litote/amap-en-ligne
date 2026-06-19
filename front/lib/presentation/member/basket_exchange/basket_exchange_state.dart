import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_exchange_state.freezed.dart';

/// UI status for async save/cancel operations.
enum BasketExchangeSaveStatus { idle, saving, success, failure }

/// Sub-state of the dialog currently open in the screen.
@freezed
sealed class BasketExchangeDialogState with _$BasketExchangeDialogState {
  /// No dialog open.
  const factory BasketExchangeDialogState.none() = _None;

  /// "Proposer un échange" dialog.
  const factory BasketExchangeDialogState.propose() = _Propose;

  /// "Envoyer une demande" dialog for a given offer.
  const factory BasketExchangeDialogState.submitRequest({
    required BasketExchange offer,
  }) = _SubmitRequest;
}

/// Sealed state union for [BasketExchangeBloc].
@freezed
sealed class BasketExchangeState with _$BasketExchangeState {
  /// Initial loading — waiting for streams to emit.
  const factory BasketExchangeState.loading() = BasketExchangeLoading;

  /// Member row not yet synced — show "Synchronisation en cours…".
  const factory BasketExchangeState.unauthorized() = BasketExchangeUnauthorized;

  /// Fully resolved state — all data available.
  const factory BasketExchangeState.ready({
    required Member me,
    required Organization org,
    required List<BasketExchange> allExchanges,
    @Default(<Member>[]) List<Member> members,
    @Default(<Contract>[]) List<Contract> contracts,
    @Default(BasketExchangeDialogState.none())
    BasketExchangeDialogState dialogState,
    @Default(BasketExchangeSaveStatus.idle) BasketExchangeSaveStatus saveStatus,
    String? errorMessage,
  }) = BasketExchangeReady;
}

/// Extension helpers to derive filtered sub-lists from [BasketExchangeReady].
extension BasketExchangeReadyX on BasketExchangeReady {
  /// Members indexed by id, for resolving display names.
  Map<String, Member> get membersById => {
    for (final m in members) m.memberId: m,
  };

  /// Offers where *I* am the offerer.
  List<BasketExchange> get myOffers =>
      allExchanges.where((e) => e.offeringMemberId == me.memberId).toList();

  /// Open offers from *other* members that I can request.
  List<BasketExchange> get availableOffers => allExchanges
      .where(
        (e) =>
            e.status == BasketExchangeStatus.open &&
            e.offeringMemberId != me.memberId,
      )
      .toList();

  /// Non-open exchanges where I am involved (offerer or requester).
  List<BasketExchange> get historyItems => allExchanges
      .where(
        (e) =>
            e.status != BasketExchangeStatus.open &&
            _involvedIn(e, me.memberId),
      )
      .toList();

  /// Count of successfully completed exchanges this calendar year.
  int get successfulExchangesThisYear {
    final year = DateTime.now().year;
    return historyItems.where((e) {
      if (e.status != BasketExchangeStatus.accepted) return false;
      final decidedAt = e.decidedAt;
      if (decidedAt == null) return false;
      return DateTime.tryParse(decidedAt)?.year == year;
    }).length;
  }

  bool _involvedIn(BasketExchange exchange, String memberId) {
    if (exchange.offeringMemberId == memberId) return true;
    return exchange.requests.any((r) => r.requesterMemberId == memberId);
  }

  /// Returns my pending request on a given offer, or null if none.
  BasketExchangeRequest? myPendingRequestOn(BasketExchange offer) {
    return offer.requests
        .where(
          (r) =>
              r.requesterMemberId == me.memberId &&
              r.status == BasketExchangeRequestStatus.pending,
        )
        .firstOrNull;
  }
}

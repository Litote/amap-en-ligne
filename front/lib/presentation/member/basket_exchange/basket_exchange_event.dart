import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_exchange_event.freezed.dart';

@freezed
sealed class BasketExchangeEvent with _$BasketExchangeEvent {
  /// Internal — emitted when org/member/exchange streams emit new values.
  const factory BasketExchangeEvent.loadedFromStreams({
    required Organization org,
    required Member? me,
    required List<BasketExchange> exchanges,
  }) = BasketExchangeLoadedFromStreams;

  /// User tapped [➕ PROPOSER UN ÉCHANGE].
  const factory BasketExchangeEvent.proposeRequested() =
      BasketExchangeProposeRequested;

  /// User confirmed the proposal in the dialog.
  const factory BasketExchangeEvent.proposeSubmitted({
    required String deliveryId,
    required String contractId,
    String? motive,
  }) = BasketExchangeProposeSubmitted;

  /// User cancelled the propose dialog.
  const factory BasketExchangeEvent.proposeCancelled() =
      BasketExchangeProposeCancelled;

  /// User tapped [DEMANDER ÉCHANGE] on a specific offer.
  const factory BasketExchangeEvent.requestRequested({
    required BasketExchange offer,
  }) = BasketExchangeRequestRequested;

  /// User confirmed sending a request in the dialog, proposing one of their own
  /// deliveries ([proposedDeliveryId] / optional [proposedContractId]) in return.
  const factory BasketExchangeEvent.requestSubmitted({
    required BasketExchange offer,
    required String proposedDeliveryId,
    String? proposedContractId,
  }) = BasketExchangeRequestSubmitted;

  /// User tapped [RETIRER MA DEMANDE].
  const factory BasketExchangeEvent.requestWithdrawn({
    required BasketExchange offer,
    required String requestId,
  }) = BasketExchangeRequestWithdrawn;

  /// Offerer accepted a received request.
  const factory BasketExchangeEvent.requestAccepted({
    required BasketExchange offer,
    required String requestId,
  }) = BasketExchangeRequestAccepted;

  /// Offerer refused a received request.
  const factory BasketExchangeEvent.requestRefused({
    required BasketExchange offer,
    required String requestId,
  }) = BasketExchangeRequestRefused;

  /// Offerer cancelled their own offer.
  const factory BasketExchangeEvent.offerCancelled({
    required BasketExchange offer,
  }) = BasketExchangeOfferCancelled;

  /// User dismissed the current dialog.
  const factory BasketExchangeEvent.dialogDismissed() =
      BasketExchangeDialogDismissed;

  /// User tapped [🔄 ACTUALISER].
  const factory BasketExchangeEvent.refreshRequested() =
      BasketExchangeRefreshRequested;
}

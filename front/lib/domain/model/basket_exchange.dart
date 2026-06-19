import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_exchange.freezed.dart';
part 'basket_exchange.g.dart';

/// Wire status for a [BasketExchange] offer.
///
/// Mirrors `BasketExchangeStatus` on the back. Uppercase wire values.
enum BasketExchangeStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('CANCELLED')
  cancelled,
}

/// Wire status for a [BasketExchangeRequest] embedded in a [BasketExchange].
///
/// Mirrors `BasketExchangeRequestStatus` on the back. Uppercase wire values.
enum BasketExchangeRequestStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('WITHDRAWN')
  withdrawn,
}

/// A request from one member to take over another member's basket slot.
///
/// Embedded inside [BasketExchange.requests]. The back allocates real request
/// ids server-side: when the client submits a `tmp_*` [requestId] inside
/// `BasketExchange.requests[]`, the [MutationOutcome.serverEntityId] carries
/// the outer [BasketExchange.basketExchangeId] (not the request id). The front
/// recovers the allocated request id by re-reading the response [BasketExchange]
/// after sync — the `tmp_*` request entry is replaced with the real one.
@freezed
abstract class BasketExchangeRequest with _$BasketExchangeRequest {
  const factory BasketExchangeRequest({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'requester_member_id') required String requesterMemberId,
    // ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
    @JsonKey(name: 'created_at') required String createdAt,
    required BasketExchangeRequestStatus status,
    // ISO-8601 instant string; null/absent when not yet decided.
    @JsonKey(name: 'decided_at') String? decidedAt,
    // Reciprocal swap: the delivery (and optional contract) the requester offers
    // in return. The offerer receives this basket when validating the request.
    // Required at submission time (enforced by the back); nullable on the wire for
    // robustness / legacy rows.
    @JsonKey(name: 'proposed_delivery_id') String? proposedDeliveryId,
    @JsonKey(name: 'proposed_contract_id') String? proposedContractId,
  }) = _BasketExchangeRequest;

  factory BasketExchangeRequest.fromJson(Map<String, Object?> json) =>
      _$BasketExchangeRequestFromJson(json);
}

/// A basket-exchange offer published by a member on one of their upcoming
/// delivery slots.
///
/// Synced on the `organization:{id}` scope. The back never allows
/// [applyDelete] — tombstones are [FORBIDDEN].
///
/// `tmp_*` ids: when the client creates a new offer, it assigns a `tmp_*`
/// [basketExchangeId]. After sync the handler reads [MutationOutcome.serverEntityId]
/// to remap the local row to the real id. For embedded [requests], see
/// [BasketExchangeRequest] doc comment for the id-recovery convention.
@freezed
abstract class BasketExchange with _$BasketExchange {
  const factory BasketExchange({
    @JsonKey(name: 'basket_exchange_id') required String basketExchangeId,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'delivery_id') required String deliveryId,
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'offering_member_id') required String offeringMemberId,
    String? motive,
    required BasketExchangeStatus status,
    // ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
    @JsonKey(name: 'created_at') required String createdAt,
    // ISO-8601 instant string; null/absent until the exchange is decided.
    @JsonKey(name: 'decided_at') String? decidedAt,
    // Null/absent while no request has been accepted yet.
    @JsonKey(name: 'accepted_request_id') String? acceptedRequestId,
    @Default([]) List<BasketExchangeRequest> requests,
  }) = _BasketExchange;

  factory BasketExchange.fromJson(Map<String, Object?> json) =>
      _$BasketExchangeFromJson(json);
}

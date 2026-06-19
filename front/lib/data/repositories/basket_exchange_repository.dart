import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write API for [BasketExchange] entities on the `organization:{id}` scope.
///
/// All writes apply optimistically to the local drift cache and enqueue a
/// [ClientMutation] in the pending queue. The actual flush to the server happens
/// on the next `SyncRepository.sync()` call.
///
/// ### Nested request id convention
///
/// When a member submits a request ([submitRequest]), the client assigns a
/// `tmp_*` [BasketExchangeRequest.requestId] inside [BasketExchange.requests].
/// The back allocates the real request id server-side but returns
/// [MutationOutcome.serverEntityId] = [BasketExchange.basketExchangeId] (the
/// outer aggregate id, not the inner request id). After the next sync the
/// [BasketExchangeSyncHandler.applyPayload] rewrites `requests_json` from the
/// authoritative server payload, so the `tmp_*` request id is replaced
/// transparently without a dedicated remap step.
///
/// ### Reciprocal swap
///
/// A request carries a counter-delivery ([BasketExchangeRequest.proposedDeliveryId]
/// / [proposedContractId]) — the basket the requester offers in return. The offerer
/// validates one request ([acceptRequest], the exchange is confirmed) or refuses it
/// individually ([refuseRequest], the offer stays OPEN for other requesters). Both
/// transitions are supported by the back's [BasketExchangeService].
class BasketExchangeRepository {
  BasketExchangeRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  // ---------------------------------------------------------------------------
  // Read API
  // ---------------------------------------------------------------------------

  /// All basket-exchange offers for the given organization.
  Stream<List<BasketExchange>> watch(String orgId) =>
      _db.watchBasketExchangesByOrg(orgId);

  /// Offers where [offeringMemberId] is the current member.
  Stream<List<BasketExchange>> watchMyOffers(String orgId, String memberId) =>
      _db
          .watchBasketExchangesByOrg(orgId)
          .map(
            (list) =>
                list.where((e) => e.offeringMemberId == memberId).toList(),
          );

  /// Open offers from other members — available to request.
  Stream<List<BasketExchange>> watchAvailableOffers(
    String orgId,
    String memberId,
  ) => _db
      .watchBasketExchangesByOrg(orgId)
      .map(
        (list) => list
            .where(
              (e) =>
                  e.status == BasketExchangeStatus.open &&
                  e.offeringMemberId != memberId,
            )
            .toList(),
      );

  /// Non-open exchanges where the member is involved (as offerer or requester).
  ///
  /// Includes ACCEPTED and CANCELLED exchanges where:
  /// - [offeringMemberId] == [memberId], or
  /// - the member appears in [requests] as the accepted requester, or
  /// - the member appears in [requests] with any other terminal status.
  Stream<List<BasketExchange>> watchHistory(String orgId, String memberId) =>
      _db
          .watchBasketExchangesByOrg(orgId)
          .map(
            (list) => list
                .where(
                  (e) =>
                      e.status != BasketExchangeStatus.open &&
                      _memberIsInvolved(e, memberId),
                )
                .toList(),
          );

  bool _memberIsInvolved(BasketExchange exchange, String memberId) {
    if (exchange.offeringMemberId == memberId) return true;
    return exchange.requests.any((r) => r.requesterMemberId == memberId);
  }

  // ---------------------------------------------------------------------------
  // Write API
  // ---------------------------------------------------------------------------

  /// Creates a new basket-exchange offer optimistically and enqueues an Upsert.
  Future<void> createOffer({
    required String orgId,
    required String deliveryId,
    required String contractId,
    required String offeringMemberId,
    String? motive,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final exchange = BasketExchange(
      basketExchangeId: _idGen.nextTmpId(),
      organizationId: orgId,
      deliveryId: deliveryId,
      contractId: contractId,
      offeringMemberId: offeringMemberId,
      motive: motive,
      status: BasketExchangeStatus.open,
      createdAt: now,
    );
    await _submitMutation(exchange, orgId);
  }

  /// Adds a request from [requesterMemberId] to an existing offer.
  ///
  /// Clones the aggregate locally with the new request (status PENDING, `tmp_*`
  /// requestId) and enqueues an Upsert. After sync, the server-allocated request
  /// id replaces the `tmp_*` entry — see class doc for the id-recovery convention.
  Future<void> submitRequest({
    required BasketExchange basketExchange,
    required String requesterMemberId,
    required String proposedDeliveryId,
    String? proposedContractId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final newRequest = BasketExchangeRequest(
      requestId: _idGen.nextTmpId(),
      requesterMemberId: requesterMemberId,
      createdAt: now,
      status: BasketExchangeRequestStatus.pending,
      proposedDeliveryId: proposedDeliveryId,
      proposedContractId: proposedContractId,
    );
    final updated = basketExchange.copyWith(
      requests: [...basketExchange.requests, newRequest],
    );
    await _submitMutation(updated, basketExchange.organizationId);
  }

  /// Withdraws the request identified by [requestId] from the offer.
  ///
  /// Transitions the matching request to [BasketExchangeRequestStatus.withdrawn].
  Future<void> withdrawRequest({
    required BasketExchange basketExchange,
    required String requestId,
  }) async {
    final updatedRequests = basketExchange.requests.map((r) {
      if (r.requestId != requestId) return r;
      return r.copyWith(status: BasketExchangeRequestStatus.withdrawn);
    }).toList();
    final updated = basketExchange.copyWith(requests: updatedRequests);
    await _submitMutation(updated, basketExchange.organizationId);
  }

  /// Accepts the request identified by [requestId].
  ///
  /// Atomically:
  /// - Transitions the offer to [BasketExchangeStatus.accepted].
  /// - Sets [BasketExchange.acceptedRequestId] to [requestId].
  /// - Sets [BasketExchange.decidedAt] to [decidedAt].
  /// - Transitions the accepted request to [BasketExchangeRequestStatus.accepted].
  /// - Transitions all other PENDING requests to [BasketExchangeRequestStatus.rejected].
  Future<void> acceptRequest({
    required BasketExchange basketExchange,
    required String requestId,
    required String decidedAt,
  }) async {
    final updatedRequests = basketExchange.requests.map((r) {
      if (r.requestId == requestId) {
        return r.copyWith(
          status: BasketExchangeRequestStatus.accepted,
          decidedAt: decidedAt,
        );
      }
      if (r.status == BasketExchangeRequestStatus.pending) {
        return r.copyWith(
          status: BasketExchangeRequestStatus.rejected,
          decidedAt: decidedAt,
        );
      }
      return r;
    }).toList();
    final updated = basketExchange.copyWith(
      status: BasketExchangeStatus.accepted,
      acceptedRequestId: requestId,
      decidedAt: decidedAt,
      requests: updatedRequests,
    );
    await _submitMutation(updated, basketExchange.organizationId);
  }

  /// Refuses the request identified by [requestId].
  ///
  /// Transitions only the target request to [BasketExchangeRequestStatus.rejected].
  /// The offer remains [BasketExchangeStatus.open] so other requesters can still
  /// be accepted. Supported by the back (offerer-only).
  Future<void> refuseRequest({
    required BasketExchange basketExchange,
    required String requestId,
    required String decidedAt,
  }) async {
    final updatedRequests = basketExchange.requests.map((r) {
      if (r.requestId != requestId) return r;
      return r.copyWith(
        status: BasketExchangeRequestStatus.rejected,
        decidedAt: decidedAt,
      );
    }).toList();
    final updated = basketExchange.copyWith(requests: updatedRequests);
    await _submitMutation(updated, basketExchange.organizationId);
  }

  /// Cancels the offer.
  ///
  /// Transitions the offer to [BasketExchangeStatus.cancelled], sets
  /// [BasketExchange.decidedAt], and transitions all PENDING requests to
  /// [BasketExchangeRequestStatus.rejected].
  Future<void> cancelOffer({
    required BasketExchange basketExchange,
    required String decidedAt,
  }) async {
    final updatedRequests = basketExchange.requests.map((r) {
      if (r.status == BasketExchangeRequestStatus.pending) {
        return r.copyWith(
          status: BasketExchangeRequestStatus.rejected,
          decidedAt: decidedAt,
        );
      }
      return r;
    }).toList();
    final updated = basketExchange.copyWith(
      status: BasketExchangeStatus.cancelled,
      decidedAt: decidedAt,
      requests: updatedRequests,
    );
    await _submitMutation(updated, basketExchange.organizationId);
  }

  Future<void> _submitMutation(BasketExchange exchange, String orgId) async {
    await _db.upsertBasketExchange(exchange);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(payload: BasketExchangePayload(basketExchange: exchange)),
      ),
      scopeKey: organizationScopeKey(orgId),
    );
  }
}

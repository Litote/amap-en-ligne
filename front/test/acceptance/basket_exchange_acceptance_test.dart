@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Client side of `basket-exchange-reciprocal-swap`, seen from each device:
/// the requester answers the offer with a counter-delivery (nested `tmp_`
/// request id recovered from the authoritative aggregate), then the offerer
/// validates one request, which rejects the other pending one.
void main() {
  const orgId = 'org-1';
  const orgScope = 'organization:org-1';
  const offerId = 'be-1';

  final story = _loadStory('basket-exchange-reciprocal-swap');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  const openOffer = BasketExchange(
    basketExchangeId: offerId,
    organizationId: orgId,
    deliveryId: 'delivery-d1',
    contractId: 'contract-c1',
    offeringMemberId: 'offerer-1',
    status: BasketExchangeStatus.open,
    createdAt: '2026-01-01T00:00:00Z',
  );

  BasketExchangeRequest request({
    required String requestId,
    required String requester,
    required String proposedDeliveryId,
    required String proposedContractId,
    BasketExchangeRequestStatus status = BasketExchangeRequestStatus.pending,
    String? decidedAt,
  }) => BasketExchangeRequest(
    requestId: requestId,
    requesterMemberId: requester,
    createdAt: '2026-01-02T00:00:00Z',
    status: status,
    decidedAt: decidedAt,
    proposedDeliveryId: proposedDeliveryId,
    proposedContractId: proposedContractId,
  );

  SyncResponse appliedWith(String clientOpId, BasketExchange serverState) =>
      SyncResponse(
        authorizedScopes: const [orgScope],
        results: {
          orgScope: IncrementalScopeSyncResult(
            changes: [
              Change(
                entityType: EntityType.basketExchange,
                entityId: offerId,
                op: ChangeOp.upsert,
                payload: BasketExchangePayload(basketExchange: serverState),
                producedAt: 1,
              ),
            ],
            nextCursor: 'c1',
          ),
        },
        mutations: [
          MutationOutcome(
            clientOpId: clientOpId,
            status: MutationStatus.applied,
            // Root id: the nested request id is never echoed here.
            serverEntityId: offerId,
          ),
        ],
      );

  Future<BasketExchange> localOffer() async =>
      (await db.watchBasketExchangesByOrg(orgId).first).single;

  test(
    '${story.title} [${story.id}] — requester proposes a counter-delivery',
    () async {
      await db.upsertBasketExchange(openOffer);
      await db.writeCursor(orgScope, 'c0');

      await BasketExchangeRepository(
        db: db,
        idGenerator: _SequenceIdGenerator(['request', 'op-request']),
      ).submitRequest(
        basketExchange: openOffer,
        requesterMemberId: 'requester-1',
        proposedDeliveryId: 'delivery-d2',
        proposedContractId: 'contract-c2',
      );
      final pending = await db.readPendingMutations();
      final sent =
          ((pending.single.op as Upsert).payload as BasketExchangePayload)
              .basketExchange;
      // The whole aggregate is sent, with the new request as the only change.
      expect(sent.copyWith(requests: const []), openOffer);
      final sentRequest = sent.requests.single;
      expect(sentRequest.requestId, 'tmp_request');
      expect(sentRequest.status, BasketExchangeRequestStatus.pending);
      expect(sentRequest.proposedDeliveryId, 'delivery-d2');
      expect(sentRequest.proposedContractId, 'contract-c2');

      api = _ScriptedSyncApi([
        _ExpectedSyncCall(
          request: SyncRequest(
            cursors: const {orgScope: 'c0'},
            mutations: pending,
          ),
          response: appliedWith(
            'op-request',
            openOffer.copyWith(
              requests: [
                request(
                  requestId: 'req-1',
                  requester: 'requester-1',
                  proposedDeliveryId: 'delivery-d2',
                  proposedContractId: 'contract-c2',
                ),
              ],
            ),
          ),
        ),
      ]);
      expect(
        await SyncRepository(db: db, api: api).sync(tenantId: orgId),
        isA<SyncSuccess>(),
      );

      expect(await db.readPendingMutations(), isEmpty);
      final offer = await localOffer();
      expect(offer.requests.map((r) => r.requestId), ['req-1']);
      expect(offer.requests.single.proposedDeliveryId, 'delivery-d2');
    },
  );

  test(
    '${story.title} [${story.id}] — offerer validates one request',
    () async {
      final withRequests = openOffer.copyWith(
        requests: [
          request(
            requestId: 'req-1',
            requester: 'requester-1',
            proposedDeliveryId: 'delivery-d2',
            proposedContractId: 'contract-c2',
          ),
          request(
            requestId: 'req-2',
            requester: 'requester-2',
            proposedDeliveryId: 'delivery-d3',
            proposedContractId: 'contract-c3',
          ),
        ],
      );
      await db.upsertBasketExchange(withRequests);
      await db.writeCursor(orgScope, 'c0');

      const decidedAt = '2026-01-03T00:00:00Z';
      await BasketExchangeRepository(
        db: db,
        idGenerator: _SequenceIdGenerator(['op-accept']),
      ).acceptRequest(
        basketExchange: withRequests,
        requestId: 'req-1',
        decidedAt: decidedAt,
      );

      // Optimistic state mirrors the server fan-out: accepted + the other
      // pending request rejected in the same aggregate write.
      final optimistic = await localOffer();
      expect(optimistic.status, BasketExchangeStatus.accepted);
      expect(optimistic.acceptedRequestId, 'req-1');
      expect(
        {for (final r in optimistic.requests) r.requesterMemberId: r.status},
        {
          'requester-1': BasketExchangeRequestStatus.accepted,
          'requester-2': BasketExchangeRequestStatus.rejected,
        },
      );

      final pending = await db.readPendingMutations();
      final serverState = optimistic.copyWith(
        decidedAt: '2026-01-03T00:00:05Z',
      );
      api = _ScriptedSyncApi([
        _ExpectedSyncCall(
          request: SyncRequest(
            cursors: const {orgScope: 'c0'},
            mutations: pending,
          ),
          response: appliedWith('op-accept', serverState),
        ),
      ]);
      expect(
        await SyncRepository(db: db, api: api).sync(tenantId: orgId),
        isA<SyncSuccess>(),
      );

      expect(await db.readPendingMutations(), isEmpty);
      expect(await localOffer(), serverState);
    },
  );
}

// ---------------------------------------------------------------------------
// Scenario story loader
// ---------------------------------------------------------------------------

class _AcceptanceStory {
  const _AcceptanceStory({required this.id, required this.title});

  final String id;
  final String title;
}

_AcceptanceStory _loadStory(String id) {
  final uri = Directory.current.uri.resolve('../acceptance/scenarios/$id.json');
  final content = File.fromUri(uri).readAsStringSync();
  final json = jsonDecode(content) as Map<String, Object?>;
  return _AcceptanceStory(
    id: json['id']! as String,
    title: json['title']! as String,
  );
}

// ---------------------------------------------------------------------------
// Scripted SyncApi
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(Iterable<_ExpectedSyncCall> calls)
    : _calls = Queue.of(calls),
      super(Dio());

  final Queue<_ExpectedSyncCall> _calls;

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls remain.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    expect(_calls, isNotEmpty, reason: 'Unexpected sync request: $request');
    final call = _calls.removeFirst();
    expect(request, call.request);
    return call.response;
  }
}

class _ExpectedSyncCall {
  const _ExpectedSyncCall({required this.request, required this.response});

  final SyncRequest request;
  final SyncResponse response;
}

// ---------------------------------------------------------------------------
// Deterministic ID generator
// ---------------------------------------------------------------------------

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(Iterable<String> ids) : _ids = Queue.of(ids);

  final Queue<String> _ids;

  @override
  String next() {
    if (_ids.isEmpty) throw StateError('No ids left in _SequenceIdGenerator.');
    return _ids.removeFirst();
  }
}

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _orgId = 'org-1';
const _deliveryId = 'd-1';
const _contractId = 'c-1';
const _offeringMemberId = 'm-1';
const _requesterMemberId = 'm-2';

BasketExchange _buildExchange({
  String id = 'be-1',
  BasketExchangeStatus status = BasketExchangeStatus.open,
  List<BasketExchangeRequest> requests = const [],
  String? acceptedRequestId,
  String? decidedAt,
}) => BasketExchange(
  basketExchangeId: id,
  organizationId: _orgId,
  deliveryId: _deliveryId,
  contractId: _contractId,
  offeringMemberId: _offeringMemberId,
  status: status,
  createdAt: '2026-05-20T10:00:00Z',
  acceptedRequestId: acceptedRequestId,
  decidedAt: decidedAt,
  requests: requests,
);

BasketExchangeRequest _buildRequest({
  String id = 'req-1',
  BasketExchangeRequestStatus status = BasketExchangeRequestStatus.pending,
  String? decidedAt,
}) => BasketExchangeRequest(
  requestId: id,
  requesterMemberId: _requesterMemberId,
  createdAt: '2026-05-21T09:00:00Z',
  status: status,
  decidedAt: decidedAt,
);

void main() {
  late AppDatabase db;
  late BasketExchangeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BasketExchangeRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('createOffer', () {
    test('writes a tmp_ id locally and enqueues Upsert on org scope', () async {
      await repo.createOffer(
        orgId: _orgId,
        deliveryId: _deliveryId,
        contractId: _contractId,
        offeringMemberId: _offeringMemberId,
        motive: 'Je suis absent',
      );

      final rows = await db.watchBasketExchangesByOrg(_orgId).first;
      expect(rows.length, 1);
      expect(rows.single.basketExchangeId, startsWith('tmp_'));
      expect(rows.single.status, BasketExchangeStatus.open);
      expect(rows.single.motive, 'Je suis absent');

      final pending = await db.readPendingMutationEntries();
      expect(pending.length, 1);
      expect(pending.single.mutation.op, isA<Upsert>());
      final upsert = pending.single.mutation.op as Upsert;
      expect(upsert.payload, isA<BasketExchangePayload>());
      final be = (upsert.payload as BasketExchangePayload).basketExchange;
      expect(be.basketExchangeId, startsWith('tmp_'));
      expect(pending.single.scopeKey, organizationScopeKey(_orgId));
    });

    test('createOffer without motive stores null motive', () async {
      await repo.createOffer(
        orgId: _orgId,
        deliveryId: _deliveryId,
        contractId: _contractId,
        offeringMemberId: _offeringMemberId,
      );

      final rows = await db.watchBasketExchangesByOrg(_orgId).first;
      expect(rows.single.motive, isNull);
    });
  });

  group('submitRequest', () {
    test(
      'adds a tmp_ request to the offer locally and enqueues Upsert',
      () async {
        final exchange = _buildExchange();
        await db.upsertBasketExchange(exchange);

        await repo.submitRequest(
          basketExchange: exchange,
          requesterMemberId: _requesterMemberId,
          proposedDeliveryId: 'delivery-counter',
          proposedContractId: 'contract-counter',
        );

        final rows = await db.watchBasketExchangesByOrg(_orgId).first;
        expect(rows.single.requests.length, 1);
        final request = rows.single.requests.single;
        expect(request.requestId, startsWith('tmp_'));
        expect(request.requesterMemberId, _requesterMemberId);
        expect(request.status, BasketExchangeRequestStatus.pending);
        expect(request.proposedDeliveryId, 'delivery-counter');
        expect(request.proposedContractId, 'contract-counter');

        final pending = await db.readPendingMutationEntries();
        expect(pending.length, 1);
        final upsert = pending.single.mutation.op as Upsert;
        final be = (upsert.payload as BasketExchangePayload).basketExchange;
        expect(be.requests.length, 1);
        expect(be.requests.single.requestId, startsWith('tmp_'));
      },
    );
  });

  group('acceptRequest', () {
    test(
      'sets offer ACCEPTED, accepted request ACCEPTED, PENDING others REJECTED',
      () async {
        final req1 = _buildRequest(id: 'req-1');
        final req2 = _buildRequest(id: 'req-2');
        final exchange = _buildExchange(requests: [req1, req2]);
        await db.upsertBasketExchange(exchange);

        const decidedAt = '2026-05-22T14:00:00Z';
        await repo.acceptRequest(
          basketExchange: exchange,
          requestId: 'req-1',
          decidedAt: decidedAt,
        );

        final rows = await db.watchBasketExchangesByOrg(_orgId).first;
        final updated = rows.single;
        expect(updated.status, BasketExchangeStatus.accepted);
        expect(updated.acceptedRequestId, 'req-1');
        expect(updated.decidedAt, decidedAt);

        final acceptedReq = updated.requests.firstWhere(
          (r) => r.requestId == 'req-1',
        );
        expect(acceptedReq.status, BasketExchangeRequestStatus.accepted);
        expect(acceptedReq.decidedAt, decidedAt);

        final rejectedReq = updated.requests.firstWhere(
          (r) => r.requestId == 'req-2',
        );
        expect(rejectedReq.status, BasketExchangeRequestStatus.rejected);
        expect(rejectedReq.decidedAt, decidedAt);

        // Verify mutation payload
        final pending = await db.readPendingMutationEntries();
        expect(pending.length, 1);
        final upsert = pending.single.mutation.op as Upsert;
        final be = (upsert.payload as BasketExchangePayload).basketExchange;
        expect(be.status, BasketExchangeStatus.accepted);
        expect(be.acceptedRequestId, 'req-1');
      },
    );
  });

  group('cancelOffer', () {
    test('sets offer CANCELLED and all PENDING requests REJECTED', () async {
      final req1 = _buildRequest(id: 'req-1');
      final req2 = _buildRequest(
        id: 'req-2',
        status: BasketExchangeRequestStatus.withdrawn,
      );
      final exchange = _buildExchange(requests: [req1, req2]);
      await db.upsertBasketExchange(exchange);

      const decidedAt = '2026-05-23T10:00:00Z';
      await repo.cancelOffer(basketExchange: exchange, decidedAt: decidedAt);

      final rows = await db.watchBasketExchangesByOrg(_orgId).first;
      final updated = rows.single;
      expect(updated.status, BasketExchangeStatus.cancelled);
      expect(updated.decidedAt, decidedAt);

      // PENDING request should be REJECTED.
      final pendingReq = updated.requests.firstWhere(
        (r) => r.requestId == 'req-1',
      );
      expect(pendingReq.status, BasketExchangeRequestStatus.rejected);
      expect(pendingReq.decidedAt, decidedAt);

      // WITHDRAWN request should remain WITHDRAWN.
      final withdrawnReq = updated.requests.firstWhere(
        (r) => r.requestId == 'req-2',
      );
      expect(withdrawnReq.status, BasketExchangeRequestStatus.withdrawn);

      final pendingMut = await db.readPendingMutationEntries();
      expect(pendingMut.length, 1);
      expect(pendingMut.single.scopeKey, organizationScopeKey(_orgId));
    });
  });

  group('withdrawRequest', () {
    test('sets the target request to WITHDRAWN', () async {
      final req1 = _buildRequest(id: 'req-1');
      final exchange = _buildExchange(requests: [req1]);
      await db.upsertBasketExchange(exchange);

      await repo.withdrawRequest(basketExchange: exchange, requestId: 'req-1');

      final rows = await db.watchBasketExchangesByOrg(_orgId).first;
      expect(
        rows.single.requests.single.status,
        BasketExchangeRequestStatus.withdrawn,
      );

      final pending = await db.readPendingMutationEntries();
      expect(pending.length, 1);
    });
  });

  group('watchMyOffers', () {
    test('returns only exchanges where offeringMemberId matches', () async {
      final myExchange = _buildExchange(id: 'be-mine');
      final otherExchange = _buildExchange(
        id: 'be-other',
      ).copyWith(offeringMemberId: 'other-member');
      await db.upsertBasketExchange(myExchange);
      await db.upsertBasketExchange(otherExchange);

      final myOffers = await repo
          .watchMyOffers(_orgId, _offeringMemberId)
          .first;
      expect(myOffers.length, 1);
      expect(myOffers.single.basketExchangeId, 'be-mine');
    });
  });

  group('watchAvailableOffers', () {
    test('returns only OPEN offers from other members', () async {
      final openOther = _buildExchange(
        id: 'open-other',
      ).copyWith(offeringMemberId: 'other-m');
      final openMine = _buildExchange(id: 'open-mine');
      final acceptedOther = _buildExchange(
        id: 'accepted-other',
        status: BasketExchangeStatus.accepted,
      ).copyWith(offeringMemberId: 'other-m');

      await db.upsertBasketExchange(openOther);
      await db.upsertBasketExchange(openMine);
      await db.upsertBasketExchange(acceptedOther);

      final available = await repo
          .watchAvailableOffers(_orgId, _offeringMemberId)
          .first;
      expect(available.length, 1);
      expect(available.single.basketExchangeId, 'open-other');
    });
  });

  group('watchHistory', () {
    test('returns non-open exchanges where the member is involved', () async {
      // Member (_offeringMemberId='m-1') is offerer on a cancelled offer.
      final cancelled = _buildExchange(
        id: 'cancelled',
        status: BasketExchangeStatus.cancelled,
      );
      // Member ('m-1') is requester on an accepted offer from someone else.
      // The request must use requesterMemberId='m-1'.
      final req = BasketExchangeRequest(
        requestId: 'req-for-m1',
        requesterMemberId: _offeringMemberId, // m-1
        createdAt: '2026-05-21T09:00:00Z',
        status: BasketExchangeRequestStatus.accepted,
      );
      final acceptedFromOther = _buildExchange(
        id: 'accepted',
        status: BasketExchangeStatus.accepted,
        requests: [req],
      ).copyWith(offeringMemberId: 'other-m');
      // Open offer not involving this member — must be excluded.
      final openOther = _buildExchange(
        id: 'open-other',
      ).copyWith(offeringMemberId: 'other-m');

      await db.upsertBasketExchange(cancelled);
      await db.upsertBasketExchange(acceptedFromOther);
      await db.upsertBasketExchange(openOther);

      final history = await repo.watchHistory(_orgId, _offeringMemberId).first;
      expect(history.length, 2);
      final ids = history.map((e) => e.basketExchangeId).toSet();
      expect(ids, contains('cancelled'));
      expect(ids, contains('accepted'));
    });
  });
}

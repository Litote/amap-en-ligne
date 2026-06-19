import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange_view.dart';
import 'package:flutter_test/flutter_test.dart';

BasketExchange _open({
  required String id,
  required String offerer,
  required String deliveryId,
  List<BasketExchangeRequest> requests = const [],
  BasketExchangeStatus status = BasketExchangeStatus.open,
  String? acceptedRequestId,
}) => BasketExchange(
  basketExchangeId: id,
  organizationId: 'org-1',
  deliveryId: deliveryId,
  contractId: 'c-1',
  offeringMemberId: offerer,
  status: status,
  createdAt: '2026-06-01T10:00:00Z',
  acceptedRequestId: acceptedRequestId,
  requests: requests,
);

BasketExchangeRequest _req({
  required String id,
  required String requester,
  BasketExchangeRequestStatus status = BasketExchangeRequestStatus.pending,
  String? proposedDeliveryId,
}) => BasketExchangeRequest(
  requestId: id,
  requesterMemberId: requester,
  createdAt: '2026-06-02T10:00:00Z',
  status: status,
  proposedDeliveryId: proposedDeliveryId,
);

void main() {
  group('basketExchangeSummaryFor', () {
    test('counts requests to validate on my open offers', () {
      final all = [
        _open(
          id: 'e1',
          offerer: 'me',
          deliveryId: 'd1',
          requests: [
            _req(id: 'r1', requester: 'a'),
            _req(id: 'r2', requester: 'b'),
            _req(
              id: 'r3',
              requester: 'c',
              status: BasketExchangeRequestStatus.withdrawn,
            ),
          ],
        ),
      ];
      final s = basketExchangeSummaryFor(all, 'me');
      expect(s.requestsToValidate, 2);
      expect(s.proposalsAwaitingValidation, 0);
      expect(s.confirmedExchanges, 0);
      expect(s.hasActivity, isTrue);
    });

    test('counts my pending proposals on others offers', () {
      final all = [
        _open(
          id: 'e1',
          offerer: 'other',
          deliveryId: 'd1',
          requests: [_req(id: 'r1', requester: 'me', proposedDeliveryId: 'd9')],
        ),
      ];
      final s = basketExchangeSummaryFor(all, 'me');
      expect(s.proposalsAwaitingValidation, 1);
      expect(s.requestsToValidate, 0);
    });

    test(
      'counts confirmed exchanges where I am offerer or accepted requester',
      () {
        final all = [
          _open(
            id: 'e1',
            offerer: 'me',
            deliveryId: 'd1',
            status: BasketExchangeStatus.accepted,
            acceptedRequestId: 'r1',
            requests: [
              _req(
                id: 'r1',
                requester: 'other',
                status: BasketExchangeRequestStatus.accepted,
                proposedDeliveryId: 'd9',
              ),
            ],
          ),
          _open(
            id: 'e2',
            offerer: 'someone',
            deliveryId: 'd2',
            status: BasketExchangeStatus.accepted,
            acceptedRequestId: 'r2',
            requests: [
              _req(
                id: 'r2',
                requester: 'me',
                status: BasketExchangeRequestStatus.accepted,
                proposedDeliveryId: 'd8',
              ),
            ],
          ),
        ];
        final s = basketExchangeSummaryFor(all, 'me');
        expect(s.confirmedExchanges, 2);
      },
    );

    test('no activity when nothing involves the member', () {
      final all = [_open(id: 'e1', offerer: 'other', deliveryId: 'd1')];
      expect(basketExchangeSummaryFor(all, 'me').hasActivity, isFalse);
    });
  });

  group('committedDeliveryIdsFor', () {
    test('includes offered deliveries plus both sides of accepted swaps', () {
      final all = [
        _open(id: 'e1', offerer: 'me', deliveryId: 'd1'), // open offer
        // I offered d2, accepted x's counter d5 → I gave d2 and received d5.
        _open(
          id: 'e2',
          offerer: 'me',
          deliveryId: 'd2',
          status: BasketExchangeStatus.accepted,
          acceptedRequestId: 'r1',
          requests: [
            _req(
              id: 'r1',
              requester: 'x',
              status: BasketExchangeRequestStatus.accepted,
              proposedDeliveryId: 'd5',
            ),
          ],
        ),
        // y offered d3, accepted my counter d7 → I gave d7 and received d3.
        _open(
          id: 'e3',
          offerer: 'y',
          deliveryId: 'd3',
          status: BasketExchangeStatus.accepted,
          acceptedRequestId: 'r2',
          requests: [
            _req(
              id: 'r2',
              requester: 'me',
              status: BasketExchangeRequestStatus.accepted,
              proposedDeliveryId: 'd7',
            ),
          ],
        ),
      ];
      final committed = committedDeliveryIdsFor(all, 'me');
      // Offered (d1), exchanged away (d2, d7) and received (d5, d3) are all locked.
      expect(committed, <String>{'d1', 'd2', 'd5', 'd3', 'd7'});
    });

    test('does not commit deliveries of exchanges I am not part of', () {
      final all = [
        _open(
          id: 'e1',
          offerer: 'a',
          deliveryId: 'd1',
          status: BasketExchangeStatus.accepted,
          acceptedRequestId: 'r1',
          requests: [
            _req(
              id: 'r1',
              requester: 'b',
              status: BasketExchangeRequestStatus.accepted,
              proposedDeliveryId: 'd2',
            ),
          ],
        ),
      ];
      expect(committedDeliveryIdsFor(all, 'me'), isEmpty);
    });

    test('a basket received in an accepted swap cannot be re-committed', () {
      // y offered d3 and accepted my counter d7: I now hold d3 (received).
      final all = [
        _open(
          id: 'e1',
          offerer: 'y',
          deliveryId: 'd3',
          status: BasketExchangeStatus.accepted,
          acceptedRequestId: 'r1',
          requests: [
            _req(
              id: 'r1',
              requester: 'me',
              status: BasketExchangeRequestStatus.accepted,
              proposedDeliveryId: 'd7',
            ),
          ],
        ),
      ];
      expect(committedDeliveryIdsFor(all, 'me'), contains('d3'));
    });
  });

  group('basketPickupsForDelivery', () {
    final confirmed = _open(
      id: 'e1',
      offerer: 'A',
      deliveryId: 'D1',
      status: BasketExchangeStatus.accepted,
      acceptedRequestId: 'r1',
      requests: [
        _req(
          id: 'r1',
          requester: 'B',
          status: BasketExchangeRequestStatus.accepted,
          proposedDeliveryId: 'D2',
        ),
      ],
    );

    test('on D1 the offerer basket is collected by the requester', () {
      final pickups = basketPickupsForDelivery([confirmed], 'D1');
      expect(pickups, {'A': 'B'});
    });

    test('on D2 the requester basket is collected by the offerer', () {
      final pickups = basketPickupsForDelivery([confirmed], 'D2');
      expect(pickups, {'B': 'A'});
    });

    test('ignores non-accepted exchanges', () {
      final open = _open(
        id: 'e2',
        offerer: 'A',
        deliveryId: 'D1',
        requests: [_req(id: 'r9', requester: 'B', proposedDeliveryId: 'D2')],
      );
      expect(basketPickupsForDelivery([open], 'D1'), isEmpty);
    });

    test('no pickups for an unrelated delivery', () {
      expect(basketPickupsForDelivery([confirmed], 'D3'), isEmpty);
    });
  });

  test('pendingRequestCount counts only pending requests', () {
    final offer = _open(
      id: 'e1',
      offerer: 'me',
      deliveryId: 'd1',
      requests: [
        _req(id: 'r1', requester: 'a'),
        _req(
          id: 'r2',
          requester: 'b',
          status: BasketExchangeRequestStatus.rejected,
        ),
      ],
    );
    expect(pendingRequestCount(offer), 1);
  });
}

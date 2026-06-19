import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:flutter_test/flutter_test.dart';

Delivery _delivery(String id, String date, String contractId) => Delivery(
      deliveryId: id,
      organizationId: 'org-1',
      scheduledDate: date,
      status: DeliveryStatus.planned,
      minVolunteersRequired: 0,
      contracts: [
        DeliveryContract(
          contractId: contractId,
          basketQuantity: 1,
          deliveryDescription: '',
          status: DeliveryContractStatus.pending,
        ),
      ],
    );

Contract _contractWith(List<SharedBasket> baskets) => Contract(
      contractId: 'c-1',
      name: 'Contrat',
      organizationId: 'org-1',
      producerAccountId: 'pa-1',
      minDeliveryDate: '2026-01-01',
      maxDeliveryDate: '2026-12-31',
      deliveryCount: 4,
      seasonYear: 2026,
      sharedBaskets: baskets,
    );

void main() {
  group('contractDeliveriesOrdered', () {
    test('filters by contract and orders by (scheduledDate, deliveryId)', () {
      final org = Organization(
        organizationId: 'org-1',
        name: 'Org',
        contactEmail: 'org@example.com',
        deliveries: [
          _delivery('d2', '2026-02-08T09:00:00', 'c-1'),
          _delivery('d1', '2026-02-01T09:00:00', 'c-1'),
          _delivery('other', '2026-02-15T09:00:00', 'c-2'),
          _delivery('d3', '2026-02-15T09:00:00', 'c-1'),
        ],
      );

      final ordered = contractDeliveriesOrdered(org, 'c-1');

      expect(ordered.map((d) => d.deliveryId), ['d1', 'd2', 'd3']);
    });
  });

  group('sharedBasketPickerFor', () {
    final ordered = [
      _delivery('d0', '2026-01-04T09:00:00', 'c-1'),
      _delivery('d1', '2026-01-11T09:00:00', 'c-1'),
      _delivery('d2', '2026-01-18T09:00:00', 'c-1'),
      _delivery('d3', '2026-01-25T09:00:00', 'c-1'),
    ];

    test('alternates round-robin between two members', () {
      const basket = SharedBasket(
        sharedBasketId: 'sb-1',
        memberIds: ['a', 'b'],
      );
      expect(sharedBasketPickerFor(basket, ordered, 'd0'), 'a');
      expect(sharedBasketPickerFor(basket, ordered, 'd1'), 'b');
      expect(sharedBasketPickerFor(basket, ordered, 'd2'), 'a');
      expect(sharedBasketPickerFor(basket, ordered, 'd3'), 'b');
    });

    test('rotation starts at the anchor delivery', () {
      const basket = SharedBasket(
        sharedBasketId: 'sb-1',
        memberIds: ['a', 'b'],
        anchorDeliveryId: 'd1',
      );
      expect(sharedBasketPickerFor(basket, ordered, 'd1'), 'a');
      expect(sharedBasketPickerFor(basket, ordered, 'd2'), 'b');
      expect(sharedBasketPickerFor(basket, ordered, 'd0'), 'b');
    });

    test('unknown anchor falls back to index zero', () {
      const basket = SharedBasket(
        sharedBasketId: 'sb-1',
        memberIds: ['a', 'b'],
        anchorDeliveryId: 'gone',
      );
      expect(sharedBasketPickerFor(basket, ordered, 'd0'), 'a');
      expect(sharedBasketPickerFor(basket, ordered, 'd1'), 'b');
    });

    test('returns null for a delivery outside the contract', () {
      const basket = SharedBasket(sharedBasketId: 'sb-1', memberIds: ['a', 'b']);
      expect(sharedBasketPickerFor(basket, ordered, 'other'), isNull);
    });

    test('three members rotate every third week', () {
      const basket = SharedBasket(
        sharedBasketId: 'sb-1',
        memberIds: ['a', 'b', 'c'],
      );
      expect(sharedBasketPickerFor(basket, ordered, 'd0'), 'a');
      expect(sharedBasketPickerFor(basket, ordered, 'd1'), 'b');
      expect(sharedBasketPickerFor(basket, ordered, 'd2'), 'c');
      expect(sharedBasketPickerFor(basket, ordered, 'd3'), 'a');
    });
  });

  group('member-facing helpers', () {
    final org = Organization(
      organizationId: 'org-1',
      name: 'Org',
      contactEmail: 'org@example.com',
      deliveries: [
        _delivery('d0', '2026-01-04T09:00:00', 'c-1'),
        _delivery('d1', '2026-01-11T09:00:00', 'c-1'),
        _delivery('d2', '2026-01-18T09:00:00', 'c-1'),
      ],
    );
    final contract = _contractWith(const [
      SharedBasket(sharedBasketId: 'sb-1', memberIds: ['a', 'b']),
    ]);

    test('memberPicksUpOn reflects alternation', () {
      final ordered = contractDeliveriesOrdered(org, 'c-1');
      expect(memberPicksUpOn(contract, ordered, 'd0', 'a'), isTrue);
      expect(memberPicksUpOn(contract, ordered, 'd0', 'b'), isFalse);
      expect(memberPicksUpOn(contract, ordered, 'd1', 'b'), isTrue);
    });

    test('memberPicksUpOn is false for a non-shared member', () {
      final ordered = contractDeliveriesOrdered(org, 'c-1');
      expect(memberPicksUpOn(contract, ordered, 'd0', 'z'), isFalse);
    });

    test('pickupDeliveriesFor lists only the member weeks', () {
      final ordered = contractDeliveriesOrdered(org, 'c-1');
      expect(
        pickupDeliveriesFor(contract, ordered, 'a').map((d) => d.deliveryId),
        ['d0', 'd2'],
      );
      expect(
        pickupDeliveriesFor(contract, ordered, 'b').map((d) => d.deliveryId),
        ['d1'],
      );
    });

    test('memberHoldsBasketOn matches the alternation, true for non-shared members', () {
      final ordered = contractDeliveriesOrdered(org, 'c-1');
      // 'a' holds d0 (their turn) but not d1 (b's turn).
      expect(memberHoldsBasketOn(contract, ordered, 'd0', 'a'), isTrue);
      expect(memberHoldsBasketOn(contract, ordered, 'd1', 'a'), isFalse);
      expect(memberHoldsBasketOn(contract, ordered, 'd1', 'b'), isTrue);
      // A member not in any shared basket always holds their own basket.
      expect(memberHoldsBasketOn(contract, ordered, 'd1', 'z'), isTrue);
    });

    test('coSharersFor excludes the member', () {
      expect(coSharersFor(contract, 'a'), ['b']);
      expect(coSharersFor(contract, 'z'), isEmpty);
    });

    test('sharedBasketPickupsForDelivery maps shared basket id to picker', () {
      final ordered = contractDeliveriesOrdered(org, 'c-1');
      expect(sharedBasketPickupsForDelivery(contract, ordered, 'd0'),
          {'sb-1': 'a'});
      expect(sharedBasketPickupsForDelivery(contract, ordered, 'd1'),
          {'sb-1': 'b'});
    });
  });
}

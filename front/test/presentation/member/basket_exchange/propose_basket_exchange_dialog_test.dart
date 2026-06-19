import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_event.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/propose_basket_exchange_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// A delivery far in the future so it always passes the "upcoming" filter.
const _futureDate = '2099-06-15T10:00:00';

Delivery _delivery({
  String id = 'd-1',
  String contractId = 'c-1',
  String description = 'Légumes Bio',
  DeliveryStatus status = DeliveryStatus.planned,
}) => Delivery(
  deliveryId: id,
  organizationId: 'org-1',
  scheduledDate: _futureDate,
  status: status,
  minVolunteersRequired: 0,
  contracts: [
    DeliveryContract(
      contractId: contractId,
      basketQuantity: 1,
      deliveryDescription: description,
      status: DeliveryContractStatus.pending,
    ),
  ],
);

Organization _org(List<Delivery> deliveries) => Organization(
  organizationId: 'org-1',
  name: 'Test AMAP',
  contactEmail: 'c@test.com',
  deliveries: deliveries,
);

Future<BasketExchangeProposeSubmitted?> _pumpDialog(
  WidgetTester tester, {
  required Organization org,
  List<BasketExchange> allExchanges = const [],
  List<Contract> contracts = const [],
}) async {
  BasketExchangeProposeSubmitted? captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ProposeBasketExchangeDialog(
                  org: org,
                  memberId: 'm-me',
                  allExchanges: allExchanges,
                  contracts: contracts,
                  onSubmit: (e) => captured = e,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  testWidgets('renders title, rules and PROPOSER disabled with no selection', (
    tester,
  ) async {
    await _pumpDialog(tester, org: _org([_delivery()]));

    expect(find.text('Proposer un échange'), findsOneWidget);
    expect(find.textContaining("Règles d'échange"), findsOneWidget);
    // No delivery selected yet → submit disabled.
    final proposeBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'PROPOSER'),
    );
    expect(proposeBtn.onPressed, isNull);
  });

  testWidgets('shows empty message when no delivery is eligible', (
    tester,
  ) async {
    // Only a completed delivery → filtered out (not active).
    await _pumpDialog(
      tester,
      org: _org([_delivery(status: DeliveryStatus.completed)]),
    );

    expect(
      find.text('Aucune livraison disponible pour un échange.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'excludes a delivery whose basket is already committed in another exchange',
    (tester) async {
      // An OPEN offer by me on d-1 commits that basket → d-1 must be filtered out.
      const myOpenOffer = BasketExchange(
        basketExchangeId: 'be-1',
        organizationId: 'org-1',
        deliveryId: 'd-1',
        contractId: 'c-1',
        offeringMemberId: 'm-me',
        status: BasketExchangeStatus.open,
        createdAt: '2026-01-01T00:00:00Z',
      );

      await _pumpDialog(
        tester,
        org: _org([_delivery()]),
        allExchanges: const [myOpenOffer],
      );

      expect(
        find.text('Aucune livraison disponible pour un échange.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selecting a single-contract delivery enables PROPOSER and submits correct ids',
    (tester) async {
      final captured = <BasketExchangeProposeSubmitted>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ProposeBasketExchangeDialog(
                      org: _org([_delivery()]),
                      memberId: 'm-me',
                      allExchanges: const [],
                      contracts: const [],
                      onSubmit: captured.add,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Open the delivery dropdown and pick the only item.
      await tester.tap(find.byType(DropdownButtonFormField<Delivery>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lundi 15 juin • Légumes Bio').last);
      await tester.pumpAndSettle();

      // Submit.
      await tester.tap(find.widgetWithText(FilledButton, 'PROPOSER'));
      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      expect(captured.single.deliveryId, 'd-1');
      expect(captured.single.contractId, 'c-1');
      expect(captured.single.motive, isNull);
      // Dialog closed after submit.
      expect(find.text('Proposer un échange'), findsNothing);
    },
  );

  testWidgets('ANNULER closes the dialog without submitting', (tester) async {
    final captured = await _pumpDialog(tester, org: _org([_delivery()]));
    expect(captured, isNull);

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('Proposer un échange'), findsNothing);
  });
}

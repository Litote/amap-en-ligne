import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/submit_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _futureDate = '2099-06-15T10:00:00';

// The offer being requested (offered by someone else, on a different delivery).
const _offer = BasketExchange(
  basketExchangeId: 'be-1',
  organizationId: 'org-1',
  deliveryId: 'd-offered',
  contractId: 'c-offered',
  offeringMemberId: 'm-bob',
  status: BasketExchangeStatus.open,
  createdAt: '2026-01-01T00:00:00Z',
  motive: 'Absent cette semaine',
);

Delivery _myDelivery({String id = 'd-mine', String contractId = 'c-mine'}) =>
    Delivery(
      deliveryId: id,
      organizationId: 'org-1',
      scheduledDate: _futureDate,
      status: DeliveryStatus.planned,
      minVolunteersRequired: 0,
      contracts: [
        DeliveryContract(
          contractId: contractId,
          basketQuantity: 1,
          deliveryDescription: 'Mon panier',
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

Future<void> _open(
  WidgetTester tester, {
  required Organization org,
  required void Function({
    required String proposedDeliveryId,
    String? proposedContractId,
  })
  onConfirm,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SubmitRequestDialog(
                  offer: _offer,
                  offererDisplayName: 'Bob Durand',
                  contractDescription: 'Panier Légumes',
                  org: org,
                  memberId: 'm-me',
                  allExchanges: const [],
                  contracts: const [],
                  onConfirm: onConfirm,
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
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  testWidgets('shows the offer recap (contract, offerer, motive)', (
    tester,
  ) async {
    await _open(
      tester,
      org: _org([_myDelivery()]),
      onConfirm: ({required proposedDeliveryId, proposedContractId}) {},
    );

    expect(find.text('Demander cet échange'), findsOneWidget);
    expect(find.textContaining('Panier Légumes'), findsOneWidget);
    expect(find.textContaining('Bob Durand'), findsWidgets);
    expect(find.textContaining('Absent cette semaine'), findsOneWidget);
  });

  testWidgets('ENVOYER disabled until a counter-delivery is selected', (
    tester,
  ) async {
    await _open(
      tester,
      org: _org([_myDelivery()]),
      onConfirm: ({required proposedDeliveryId, proposedContractId}) {},
    );

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'ENVOYER'),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets(
    'shows empty message when the requester has no eligible counter-delivery',
    (tester) async {
      // Only the offered delivery exists → nothing to offer in return.
      await _open(
        tester,
        org: _org([
          _myDelivery(id: 'd-offered'), // same id as the offer → excluded
        ]),
        onConfirm: ({required proposedDeliveryId, proposedContractId}) {},
      );

      expect(
        find.textContaining("Aucune de vos livraisons à venir"),
        findsOneWidget,
      );
    },
  );

  testWidgets('selecting a counter-delivery and tapping ENVOYER confirms ids', (
    tester,
  ) async {
    String? deliveryId;
    String? contractId;
    var called = 0;
    await _open(
      tester,
      org: _org([_myDelivery()]),
      onConfirm: ({required proposedDeliveryId, proposedContractId}) {
        called++;
        deliveryId = proposedDeliveryId;
        contractId = proposedContractId;
      },
    );

    await tester.tap(find.byType(DropdownButtonFormField<Delivery>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lundi 15 juin • Mon panier').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'ENVOYER'));
    await tester.pumpAndSettle();

    expect(called, 1);
    expect(deliveryId, 'd-mine');
    expect(contractId, 'c-mine');
    expect(find.text('Demander cet échange'), findsNothing);
  });

  testWidgets('ANNULER closes without confirming', (tester) async {
    var called = 0;
    await _open(
      tester,
      org: _org([_myDelivery()]),
      onConfirm: ({required proposedDeliveryId, proposedContractId}) {
        called++;
      },
    );

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(called, 0);
    expect(find.text('Demander cet échange'), findsNothing);
  });
}

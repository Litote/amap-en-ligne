import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/contract_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Contract _contract(int i) => Contract(
  contractId: 'c-$i',
  name: 'Contrat $i',
  organizationId: 'org-1',
  producerAccountId: 'pa-1',
  minDeliveryDate: '2026-10-01',
  maxDeliveryDate: '2026-12-17',
  deliveryCount: 12,
  seasonYear: 2026,
);

void main() {
  testWidgets('with shrinkWrap every contract is laid out (phone layout: the '
      'page scrolls, not a short inner box)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ContractList(
                contracts: [for (var i = 0; i < 12; i++) _contract(i)],
                organization: const Organization(
                  organizationId: 'org-1',
                  name: 'AMAP',
                  contactEmail: 'a@b.fr',
                ),
                producerAccounts: const [],
                selectedContractId: null,
                onCreateRequested: () {},
                onSelected: (_) {},
                shrinkWrap: true,
              ),
            ],
          ),
        ),
      ),
    );

    // All tiles exist (a nested lazy list would only build the visible ones).
    expect(find.byType(ListTile), findsNWidgets(12));
  });

  testWidgets('flags a contract whose last delivery is past as « Terminé », '
      'even when its status is still ACTIVE', (tester) async {
    final ended = _contract(1).copyWith(
      name: 'Fruits rouges',
      status: ContractStatus.active,
      minDeliveryDate: '2020-05-27',
      maxDeliveryDate: '2020-07-01',
      seasonYear: 2020,
    );
    final running = _contract(2).copyWith(
      name: 'Légumes',
      status: ContractStatus.active,
      minDeliveryDate: '2020-04-08',
      maxDeliveryDate: '2099-12-23',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContractList(
            contracts: [ended, running],
            organization: const Organization(
              organizationId: 'org-1',
              name: 'AMAP',
              contactEmail: 'a@b.fr',
            ),
            producerAccounts: const [],
            selectedContractId: null,
            onCreateRequested: () {},
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Fruits rouges'),
        matching: find.textContaining('• Terminé'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Légumes'),
        matching: find.textContaining('Terminé'),
      ),
      findsNothing,
    );
  });
}

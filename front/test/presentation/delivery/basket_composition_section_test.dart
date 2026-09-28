import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/organization_fixtures.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester) async {
    final delivery = buildDelivery(
      basketDescriptions: const [
        BasketDeliveryDescription(
          productTypeId: 'pt-cheese',
          basketSizeName: 'Petit',
          items: [DeliveryItem(itemTypeId: 'free-1', name: 'Comté')],
        ),
        BasketDeliveryDescription(
          productTypeId: 'pt-eggs',
          basketSizeName: 'Petit',
          items: [DeliveryItem(itemTypeId: 'free-2', name: 'Oeufs')],
        ),
      ],
    );
    final org = buildOrg(
      deliveries: [delivery],
      products: const [
        OrgProduct(
          name: 'Fromages',
          productTypeId: 'pt-cheese',
          producerAccountId: 'producer-1',
        ),
        OrgProduct(
          name: 'Oeufs',
          productTypeId: 'pt-eggs',
          producerAccountId: 'producer-2',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BasketCompositionSection(delivery: delivery, org: org),
        ),
      ),
    );
    await tester.tap(find.text('🧺 Composition du panier'));
    await tester.pumpAndSettle();
  }

  testWidgets('names the product of each basket size', (tester) async {
    await pumpSection(tester);

    expect(find.text('Fromages — Petit'), findsOneWidget);
    expect(find.text('Oeufs — Petit'), findsOneWidget);
    expect(find.text('Petit'), findsNothing);
  });

  testWidgets('a component without icon shows a neutral icon, not a broken '
      'image', (tester) async {
    await pumpSection(tester);

    expect(find.byIcon(Icons.image_not_supported), findsNothing);
    expect(find.byIcon(Icons.eco_outlined), findsNWidgets(2));
  });
}

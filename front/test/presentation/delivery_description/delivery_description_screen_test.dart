import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

const _productType = ProductType(
  productTypeId: 'pt-1',
  producerAccountId: 'pa-1',
  name: 'Légumes',
  itemTypes: [
    ItemType(id: 'it-1', name: 'carottes'),
    ItemType(id: 'it-2', name: 'courgettes'),
  ],
);

final _delivery = Delivery(
  deliveryId: 'd-1',
  organizationId: 'org-1',
  scheduledDate: '2025-06-14T09:00:00',
  status: DeliveryStatus.planned,
  minVolunteersRequired: 2,
);

final _org = Organization(
  organizationId: 'org-1',
  name: 'AMAP test',
  contactEmail: 'test@example.com',
  products: const [
    OrgProduct(
      name: 'Légumes',
      productTypeId: 'pt-1',
      producerAccountId: 'pa-1',
      supportedBasketSizes: [BasketSize(name: 'Medium')],
    ),
  ],
  deliveries: [_delivery],
);

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockProductTypeRepository productTypeRepo;

  setUpAll(() {
    registerFallbackValue(_org);
    registerFallbackValue(const <BasketDeliveryDescription>[]);
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    productTypeRepo = _MockProductTypeRepository();
    when(
      () => productTypeRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const [_productType]));
  });

  Future<void> pump(WidgetTester tester, {String deliveryId = 'd-1'}) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
          RepositoryProvider<ProductTypeRepository>.value(
            value: productTypeRepo,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DeliveryDescriptionScreen(
                      org: _org,
                      deliveryId: deliveryId,
                    ),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the product list with the delivery date in the title', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('Description du 2025-06-14'), findsOneWidget);
    expect(find.text('Légumes'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('adding a component from the picker lists it with its weight '
      'field and removing it clears the list', (tester) async {
    await pump(tester);

    // Expand the product, open the picker.
    await tester.tap(find.text('Légumes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    // Pick "carottes" — the sheet closes and the item appears with a weight
    // field and a remove button.
    await tester.tap(find.text('carottes'));
    await tester.pumpAndSettle();
    expect(find.text('carottes'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Poids'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Poids'), '500g');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('carottes'), findsNothing);
  });

  testWidgets('saving shows the confirmation snackbar and closes the screen', (
    tester,
  ) async {
    when(
      () => orgRepo.updateDeliveryDescription(
        currentOrg: any(named: 'currentOrg'),
        deliveryId: any(named: 'deliveryId'),
        basketDescriptions: any(named: 'basketDescriptions'),
        itemTypes: any(named: 'itemTypes'),
      ),
    ).thenAnswer((_) async {});

    await pump(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Description enregistrée'), findsOneWidget);
    // The screen popped back to the host page.
    expect(find.text('OPEN'), findsOneWidget);

    // Let the snackbar auto-dismiss so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the error message for an unknown delivery', (
    tester,
  ) async {
    await pump(tester, deliveryId: 'unknown');

    expect(
      find.text('Une erreur est survenue. Veuillez réessayer.'),
      findsOneWidget,
    );
  });
}

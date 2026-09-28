import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

const _productType = ProductType(
  productTypeId: 'pt-1',
  producerAccountId: 'pa-1',
  name: 'Fromages',
  itemTypes: [ItemType(id: 'it-1', name: 'Comté')],
);

void main() {
  late _MockProductTypeRepository repo;

  setUpAll(() => registerFallbackValue(_productType));

  setUp(() {
    repo = _MockProductTypeRepository();
    when(() => repo.updateItemTypes(any(), any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ProductTypeRepository>.value(
        value: repo,
        child: const MaterialApp(
          home: ItemTypesScreen(productType: _productType),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opened by its URL, it reads the product type from the cache and '
      'goes back to its form', (tester) async {
    when(
      () => repo.watch('pa-1'),
    ).thenAnswer((_) => Stream.value(const [_productType]));
    await tester.pumpWidget(
      RepositoryProvider<ProductTypeRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/product-types/pt-1/items',
            routes: [
              GoRoute(
                path: '/product-types/:id',
                builder: (_, st) => Text('form:${st.pathParameters['id']}'),
              ),
              GoRoute(
                path: '/product-types/:productTypeId/items',
                builder: (_, st) => ItemTypesRouteScreen(
                  tenantId: 'pa-1',
                  productTypeId: st.pathParameters['productTypeId']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catalogue de composants — Fromages'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('form:pt-1'), findsOneWidget);
  });

  testWidgets('speaks of components and labels its icon buttons', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Catalogue de composants — Fromages'), findsOneWidget);
    expect(find.byTooltip('Ajouter un composant'), findsOneWidget);
    expect(find.byTooltip('Supprimer Comté'), findsOneWidget);
  });

  testWidgets('the add sheet can be cancelled and requires a name', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Ajouter un composant'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un composant'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est requis.'), findsOneWidget);
    verifyNever(() => repo.updateItemTypes(any(), any()));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est requis.'), findsNothing);
  });

  testWidgets('an oversized SVG icon is refused before saving', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Ajouter un composant'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Brie');
    await tester.enterText(
      find.widgetWithText(TextField, 'Image SVG (optionnel)'),
      '<svg>${'x' * 10000}</svg>',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Image trop lourde'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ajouter'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.updateItemTypes(any(), any()));
    expect(find.textContaining('Image trop lourde'), findsOneWidget);
  });
}

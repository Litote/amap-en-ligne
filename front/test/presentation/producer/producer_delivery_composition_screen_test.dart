import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/producer/producer_delivery_composition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockProducerScheduleRepository extends Mock
    implements ProducerScheduleRepository {}

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

const _cheese = ProductType(
  productTypeId: 'pt-cheese',
  producerAccountId: 'pa-1',
  name: 'Fromages',
  supportedBasketSizes: [
    BasketSize(name: 'Petit'),
    BasketSize(name: 'Grand'),
  ],
  itemTypes: [ItemType(id: 'it-brie', name: 'Brie')],
);

const _yogurt = ProductType(
  productTypeId: 'pt-yogurt',
  producerAccountId: 'pa-1',
  name: 'Yaourts',
);

const _schedule = ProducerSchedule(
  organizationId: 'org-1',
  producerAccountId: 'pa-1',
  organizationName: 'AMAP Test',
  deliveries: [
    ProducerScheduleDelivery(
      deliveryId: 'd-1',
      scheduledDate: '2099-10-01T18:00',
      status: DeliveryStatus.planned,
      // The AMAP only carries the cheese, small size.
      basketDescriptions: [
        BasketDeliveryDescription(
          productTypeId: 'pt-cheese',
          basketSizeName: 'Petit',
        ),
      ],
    ),
  ],
);

void main() {
  late _MockProducerScheduleRepository scheduleRepository;
  late _MockProductTypeRepository productTypeRepository;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(_schedule);
  });

  setUp(() {
    scheduleRepository = _MockProducerScheduleRepository();
    productTypeRepository = _MockProductTypeRepository();
    when(
      () => scheduleRepository.watch('pa-1'),
    ).thenAnswer((_) => Stream.value(const [_schedule]));
    when(
      () => productTypeRepository.watch('pa-1'),
    ).thenAnswer((_) => Stream.value(const [_cheese, _yogurt]));
    when(
      () => scheduleRepository.updateBasketDescriptions(
        schedule: any(named: 'schedule'),
        deliveryId: any(named: 'deliveryId'),
        basketDescriptions: any(named: 'basketDescriptions'),
      ),
    ).thenAnswer((_) async {});
  });

  group('producerCompositionView', () {
    test('keeps only the products and sizes the delivery carries', () {
      final org = producerCompositionView(_schedule, 'd-1', const [
        _cheese,
        _yogurt,
      ])!;

      expect(org.products.map((p) => p.name), ['Fromages']);
      expect(org.products.single.supportedBasketSizes.map((s) => s.name), [
        'Petit',
      ]);
      expect(org.deliveries.single.deliveryId, 'd-1');
    });

    test('a delivery without description offers the whole catalog', () {
      final legacy = _schedule.copyWith(
        deliveries: [
          _schedule.deliveries.single.copyWith(basketDescriptions: const []),
        ],
      );

      final org = producerCompositionView(legacy, 'd-1', const [
        _cheese,
        _yogurt,
      ])!;

      expect(org.products.map((p) => p.name), ['Fromages', 'Yaourts']);
      expect(org.products.first.supportedBasketSizes.length, 2);
    });

    test('an unknown delivery gives null', () {
      expect(producerCompositionView(_schedule, 'nope', const []), isNull);
    });
  });

  Future<void> pump(WidgetTester tester, {String deliveryId = 'd-1'}) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProducerScheduleRepository>.value(
            value: scheduleRepository,
          ),
          RepositoryProvider<ProductTypeRepository>.value(
            value: productTypeRepository,
          ),
          RepositoryProvider<OrganizationRepository>.value(
            value: _MockOrganizationRepository(),
          ),
        ],
        // Opened by its URL, as the producer deliveries do.
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation:
                '/producer-deliveries/org-1/$deliveryId/composition',
            routes: [
              GoRoute(
                path: '/producer-deliveries',
                builder: (_, _) => const Text('producer-deliveries'),
              ),
              GoRoute(
                path:
                    '/producer-deliveries/:organizationId/:deliveryId/composition',
                builder: (_, st) => ProducerDeliveryCompositionScreen(
                  producerAccountId: 'pa-1',
                  organizationId: st.pathParameters['organizationId']!,
                  deliveryId: st.pathParameters['deliveryId']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the producer composes its product and saves through its '
      'schedule', (tester) async {
    await pump(tester);

    expect(find.text('Composition du jeudi 1er octobre'), findsOneWidget);
    expect(find.text('Yaourts'), findsNothing);
    await tester.tap(find.text('Fromages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final saved =
        verify(
              () => scheduleRepository.updateBasketDescriptions(
                schedule: _schedule,
                deliveryId: 'd-1',
                basketDescriptions: captureAny(named: 'basketDescriptions'),
              ),
            ).captured.single
            as List<BasketDeliveryDescription>;
    final description = saved.single;
    expect(description.items.map((i) => i.itemTypeId), ['it-brie']);
    expect(description.itemsUpdatedAt, isNotNull);
    // Nothing to pop (opened by its URL): back to the producer deliveries.
    expect(find.text('producer-deliveries'), findsOneWidget);
  });

  testWidgets('the back button returns to the producer deliveries', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('producer-deliveries'), findsOneWidget);
  });

  testWidgets('an unknown delivery shows a message', (tester) async {
    await pump(tester, deliveryId: 'nope');

    expect(find.text('Livraison introuvable.'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/presentation/producer/producer_deliveries_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockProducerScheduleRepository extends Mock
    implements ProducerScheduleRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _producerAccountId = 'pa-1';

ProducerScheduleDelivery _delivery(
  String id,
  String date, {
  String contractName = 'Fromages 2026',
  int baskets = 12,
}) => ProducerScheduleDelivery(
  deliveryId: id,
  scheduledDate: date,
  status: DeliveryStatus.planned,
  contracts: [
    ProducerScheduleContract(
      contractId: 'c-$id',
      contractName: contractName,
      basketQuantity: baskets,
      status: DeliveryContractStatus.pending,
    ),
  ],
);

void main() {
  late _MockProducerScheduleRepository repository;
  late StreamController<List<ProducerSchedule>> schedules;

  setUpAll(() async => initializeDateFormatting('fr'));

  setUp(() {
    repository = _MockProducerScheduleRepository();
    schedules = StreamController<List<ProducerSchedule>>();
    when(
      () => repository.watch(_producerAccountId),
    ).thenAnswer((_) => schedules.stream);
  });

  tearDown(() => schedules.close());

  Future<void> pump(WidgetTester tester) async {
    final syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      RepositoryProvider<ProducerScheduleRepository>.value(
        value: repository,
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const MaterialApp(
            home: ProducerDeliveriesScreen(
              producerAccountId: _producerAccountId,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders screen title', (tester) async {
    await pump(tester);

    expect(find.text('Mes livraisons'), findsOneWidget);
  });

  testWidgets('shows a spinner only until the local schedules are read', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // A producer has no AMAP data at all: the screen must settle on the
    // empty state instead of spinning forever.
    schedules.add(const []);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Aucune livraison à venir pour vos produits.'), findsOne);
  });

  testWidgets('lists the upcoming deliveries of every AMAP, soonest first, '
      'with the AMAP, the contract and the number of baskets', (tester) async {
    await pump(tester);
    schedules.add([
      ProducerSchedule(
        organizationId: 'org-1',
        producerAccountId: _producerAccountId,
        organizationName: 'AMAP des Collines',
        deliveries: [
          _delivery('d-late', '2099-06-18T18:00:00'),
          _delivery('d-past', '2000-06-11T18:00:00'),
        ],
      ),
      ProducerSchedule(
        organizationId: 'org-2',
        producerAccountId: _producerAccountId,
        organizationName: 'AMAP du Lac',
        deliveries: [
          _delivery(
            'd-soon',
            '2099-06-04T18:00:00',
            contractName: 'Tomme 2099',
            baskets: 1,
          ),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    final soon = tester.getTopLeft(find.text('AMAP du Lac'));
    final late = tester.getTopLeft(find.text('AMAP des Collines'));
    expect(soon.dy, lessThan(late.dy));
    expect(find.text('Tomme 2099 — 1 panier'), findsOneWidget);
    expect(find.text('Fromages 2026 — 12 paniers'), findsOneWidget);
    // Past deliveries are not listed.
    expect(find.textContaining('2000'), findsNothing);
  });

  testWidgets('offers the basket composition on active deliveries only', (
    tester,
  ) async {
    await pump(tester);
    schedules.add([
      ProducerSchedule(
        organizationId: 'org-1',
        producerAccountId: _producerAccountId,
        organizationName: 'AMAP des Collines',
        deliveries: [
          _delivery('d-open', '2099-06-04T18:00:00'),
          _delivery(
            'd-done',
            '2099-06-11T18:00:00',
          ).copyWith(status: DeliveryStatus.completed),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('COMPOSITION DU PANIER'), findsOneWidget);
  });
}

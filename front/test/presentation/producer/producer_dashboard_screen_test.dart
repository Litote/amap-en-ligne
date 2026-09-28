import 'dart:async';

import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/producer/producer_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth_bloc.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _MockProducerScheduleRepository extends Mock
    implements ProducerScheduleRepository {}

const _producerAccountId = 'pa-1';

_MockSyncBloc _makeSyncBloc({SyncState state = const SyncState.idle()}) {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

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
      contractId: 'c-$contractName',
      contractName: contractName,
      basketQuantity: baskets,
      status: DeliveryContractStatus.pending,
    ),
  ],
);

void main() {
  late _MockProducerScheduleRepository repository;
  late StreamController<List<ProducerSchedule>> schedules;
  late MockAuthBloc authBloc;

  setUpAll(() async => initializeDateFormatting('fr'));

  setUp(() {
    repository = _MockProducerScheduleRepository();
    schedules = StreamController<List<ProducerSchedule>>.broadcast();
    when(
      () => repository.watch(_producerAccountId),
    ).thenAnswer((_) => schedules.stream);
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthViewState(
        role: UserRole.producer,
        firstName: 'Ferme Test Claude',
      ),
    );
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => schedules.close());

  Future<void> pump(
    WidgetTester tester, {
    String? tenantId,
    SyncState syncState = const SyncState.idle(),
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SyncBloc>.value(value: _makeSyncBloc(state: syncState)),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: RepositoryProvider<ProducerScheduleRepository>.value(
          value: repository,
          child: MaterialApp(home: ProducerDashboardScreen(tenantId: tenantId)),
        ),
      ),
    );
  }

  testWidgets('greets the producer by name', (tester) async {
    await pump(tester);

    expect(find.text('Bonjour Ferme Test Claude 👋'), findsOneWidget);
  });

  testWidgets('falls back to a plain greeting without a name', (tester) async {
    when(
      () => authBloc.state,
    ).thenReturn(const AuthViewState(role: UserRole.producer));
    await pump(tester);

    expect(find.text('Bonjour 👋'), findsOneWidget);
  });

  testWidgets('keeps the quick-access tiles', (tester) async {
    await pump(tester);

    expect(find.text('Catalogue de produits'), findsOneWidget);
    expect(find.text('Mes livraisons'), findsOneWidget);
    expect(find.text('Préférences'), findsOneWidget);
  });

  testWidgets('summarises the upcoming activity', (tester) async {
    await pump(tester, tenantId: _producerAccountId);
    schedules.add([
      ProducerSchedule(
        organizationId: 'org-1',
        producerAccountId: _producerAccountId,
        organizationName: 'AMAP Test',
        deliveries: [
          _delivery('d1', '2099-10-01T18:00'),
          _delivery('d2', '2099-10-08T18:00'),
          _delivery('d3', '2099-10-15T18:00'),
          _delivery('d4', '2099-10-22T18:00'),
        ],
      ),
      const ProducerSchedule(
        organizationId: 'org-2',
        producerAccountId: _producerAccountId,
        organizationName: 'AMAP Deux',
      ),
    ]);
    await tester.pump();

    expect(find.text('• 2 organismes partenaires'), findsOneWidget);
    expect(find.text('• 1 contrat en cours'), findsOneWidget);
    expect(find.textContaining('• Prochaine livraison : '), findsOneWidget);
    // Only the 3 soonest deliveries, then a link to the full list.
    expect(
      find.textContaining(RegExp(r'^📅 .* • AMAP Test$')),
      findsNWidgets(3),
    );
    expect(find.text('VOIR TOUTES MES LIVRAISONS'), findsOneWidget);
    expect(
      find.text('• AMAP Test - Fromages 2026 (12 paniers/livraison)'),
      findsOneWidget,
    );
  });

  testWidgets('shows explicit empty states', (tester) async {
    await pump(tester, tenantId: _producerAccountId);
    schedules.add(const []);
    await tester.pump();

    expect(find.text('• Aucune livraison à venir'), findsOneWidget);
    expect(
      find.text('Aucune livraison à venir pour vos produits.'),
      findsOneWidget,
    );
    expect(find.text('Aucun contrat en cours.'), findsOneWidget);
  });

  group('first sync (nothing cached yet)', () {
    testWidgets('says the data is coming before the tenant is resolved', (
      tester,
    ) async {
      await pump(tester, syncState: const SyncState.syncing());

      expect(find.text('🔄 Synchronisation en cours…'), findsOneWidget);
    });

    testWidgets('says the data is coming instead of empty states', (
      tester,
    ) async {
      await pump(
        tester,
        tenantId: _producerAccountId,
        syncState: const SyncState.syncing(),
      );
      schedules.add(const []);
      await tester.pump();

      expect(find.text('🔄 Synchronisation en cours…'), findsOneWidget);
      expect(find.text('Aucun contrat en cours.'), findsNothing);
    });

    testWidgets('no notice once synced', (tester) async {
      await pump(tester, tenantId: _producerAccountId);
      schedules.add(const []);
      await tester.pump();

      expect(find.text('🔄 Synchronisation en cours…'), findsNothing);
    });
  });
}

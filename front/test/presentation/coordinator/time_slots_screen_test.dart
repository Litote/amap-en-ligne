import 'dart:async';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRepository repo,
  required ContractRepository contractRepo,
  required SyncBloc syncBloc,
  String tenantId = 'org-1',
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: repo),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(home: TimeSlotsScreen(tenantId: tenantId)),
      ),
    ),
  );
}

/// Pumps the screen behind a [GoRouter] so navigation pushes can be asserted.
/// The destination routes render a marker text echoing the resolved path.
Future<void> _pumpRouter(
  WidgetTester tester, {
  required OrganizationRepository repo,
  required ContractRepository contractRepo,
  required SyncBloc syncBloc,
  String tenantId = 'org-1',
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());

  final router = GoRouter(
    initialLocation: '/coordinator/time-slots',
    routes: [
      GoRoute(
        path: '/coordinator/time-slots',
        builder: (_, _) => TimeSlotsScreen(tenantId: tenantId),
      ),
      GoRoute(
        path: '/coordinator/time-slots/:deliveryId',
        builder: (_, st) => Text('edit:${st.pathParameters['deliveryId']}'),
      ),
      GoRoute(
        path: '/coordinator/tracking/:deliveryId',
        builder: (_, st) => Text('track:${st.pathParameters['deliveryId']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: repo),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository repo;
  late _MockContractRepository contractRepo;
  late _MockSyncBloc syncBloc;
  late StreamController<Organization?> orgStream;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    repo = _MockOrganizationRepository();
    contractRepo = _MockContractRepository();
    syncBloc = _MockSyncBloc();
    orgStream = StreamController<Organization?>.broadcast();
    when(() => repo.watch(any())).thenAnswer((_) => orgStream.stream);
    when(() => contractRepo.watch(any())).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await orgStream.close();
  });

  testWidgets(
    'shows min volunteers when a delivery has no slot breakdown yet',
    (tester) async {
      final delivery = buildDelivery(
        scheduledDate: tomorrowIso(),
        minVolunteersRequired: 4,
      );

      await _pump(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('0/4 bénévoles'), findsOneWidget);
    },
  );

  testWidgets('shows only the products concerned by the delivery', (
    tester,
  ) async {
    final delivery = buildDelivery(
      scheduledDate: tomorrowIso(),
      basketDescriptions: const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Petit',
        ),
      ],
    );

    await _pump(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
    await tester.pump();

    orgStream.add(
      buildOrg(
        deliveries: [delivery],
        products: const [
          OrgProduct(
            name: 'Tomates',
            productTypeId: 'pt-1',
            producerAccountId: 'producer-1',
          ),
          OrgProduct(
            name: 'Oeufs',
            productTypeId: 'pt-2',
            producerAccountId: 'producer-2',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Produits : Tomates'), findsOneWidget);
    expect(find.textContaining('Oeufs'), findsNothing);
  });

  testWidgets('groups deliveries into En cours / À venir / Passées sections', (
    tester,
  ) async {
    await _pump(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
    await tester.pump();

    orgStream.add(
      buildOrg(
        deliveries: [
          buildDelivery(deliveryId: 'live', status: DeliveryStatus.inProgress),
          buildDelivery(
            deliveryId: 'next',
            scheduledDate: tomorrowIso(),
            status: DeliveryStatus.planned,
          ),
          buildDelivery(
            deliveryId: 'old',
            scheduledDate: pastIso(),
            status: DeliveryStatus.completed,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Passées'), findsOneWidget);
  });

  testWidgets('hides empty section headers', (tester) async {
    await _pump(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
    await tester.pump();

    orgStream.add(
      buildOrg(deliveries: [buildDelivery(scheduledDate: tomorrowIso())]),
    );
    await tester.pump();

    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('En cours'), findsNothing);
    expect(find.text('Passées'), findsNothing);
  });

  testWidgets('MODIFIER navigates to the delivery edit form', (tester) async {
    await _pumpRouter(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
    await tester.pump();

    orgStream.add(
      buildOrg(
        deliveries: [
          buildDelivery(deliveryId: 'd-9', scheduledDate: tomorrowIso()),
        ],
      ),
    );
    await tester.pump();

    await tester.tap(find.text('MODIFIER'));
    await tester.pumpAndSettle();

    expect(find.text('edit:d-9'), findsOneWidget);
  });

  testWidgets('SUIVRE navigates to the live tracking screen', (tester) async {
    await _pumpRouter(tester, repo: repo, contractRepo: contractRepo, syncBloc: syncBloc);
    await tester.pump();

    orgStream.add(
      buildOrg(
        deliveries: [
          buildDelivery(deliveryId: 'd-9', scheduledDate: tomorrowIso()),
        ],
      ),
    );
    await tester.pump();

    await tester.tap(find.text('SUIVRE'));
    await tester.pumpAndSettle();

    expect(find.text('track:d-9'), findsOneWidget);
  });
}

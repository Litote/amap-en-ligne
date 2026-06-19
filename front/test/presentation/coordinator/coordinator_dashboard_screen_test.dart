import 'dart:async';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_dashboard_screen.dart';
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

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRepository repo,
  required MemberRepository memberRepo,
  required ContractRepository contractRepo,
  required SyncBloc syncBloc,
  required AuthService authService,
  String tenantId = 'org-1',
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: repo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: CoordinatorDashboardScreen(tenantId: tenantId),
        ),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository repo;
  late _MockMemberRepository memberRepo;
  late _MockContractRepository contractRepo;
  late _MockSyncBloc syncBloc;
  late _MockAuthService authService;
  late StreamController<Organization?> orgStream;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    repo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    contractRepo = _MockContractRepository();
    syncBloc = _MockSyncBloc();
    authService = _MockAuthService();
    orgStream = StreamController<Organization?>.broadcast();
    when(() => repo.watch(any())).thenAnswer((_) => orgStream.stream);
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => authService.currentState,
    ).thenReturn(const AuthState.unauthenticated());
  });

  tearDown(() async {
    await orgStream.close();
  });

  group('CoordinatorDashboardScreen', () {
    testWidgets('shows loading indicator when tenantId is empty', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: repo,
        memberRepo: memberRepo,
        contractRepo: contractRepo,
        syncBloc: syncBloc,
        authService: authService,
        tenantId: '',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Aucune livraison active." when org has no deliveries', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: repo,
        memberRepo: memberRepo,
        contractRepo: contractRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      await tester.pump();

      expect(find.text('Aucune livraison active.'), findsOneWidget);
    });

    testWidgets('shows inProgress delivery in "Livraisons en cours" section', (
      tester,
    ) async {
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        scheduledDate: tomorrowIso(),
      );

      await _pump(
        tester,
        repo: repo,
        memberRepo: memberRepo,
        contractRepo: contractRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('Livraisons en cours'), findsOneWidget);
      expect(find.textContaining('En cours'), findsOneWidget);
    });

    testWidgets('shows upcoming planned delivery in "Prochaines livraisons"', (
      tester,
    ) async {
      final delivery = buildDelivery(
        status: DeliveryStatus.planned,
        scheduledDate: tomorrowIso(),
      );

      await _pump(
        tester,
        repo: repo,
        memberRepo: memberRepo,
        contractRepo: contractRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('Prochaines livraisons'), findsOneWidget);
      expect(find.text('Aucune livraison active.'), findsNothing);
    });

    testWidgets(
      'shows min volunteers when a delivery has no slot breakdown yet',
      (tester) async {
        final delivery = buildDelivery(
          scheduledDate: tomorrowIso(),
          minVolunteersRequired: 6,
        );

        await _pump(
          tester,
          repo: repo,
          memberRepo: memberRepo,
          contractRepo: contractRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        await tester.pump();

        expect(find.text('0/6 bénévoles'), findsOneWidget);
      },
    );

    testWidgets(
      'does not show "Aucune livraison active." when deliveries exist',
      (tester) async {
        final delivery = buildDelivery(status: DeliveryStatus.inProgress);

        await _pump(
          tester,
          repo: repo,
          memberRepo: memberRepo,
          contractRepo: contractRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        await tester.pump();

        expect(find.text('Aucune livraison active.'), findsNothing);
      },
    );

    testWidgets(
      'shows the "➕ NOUVEAU CRÉNEAU" action and opens new time-slot form',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<OrganizationRepository>.value(value: repo),
                  RepositoryProvider<MemberRepository>.value(value: memberRepo),
                  RepositoryProvider<ContractRepository>.value(
                    value: contractRepo,
                  ),
                  RepositoryProvider<AuthService>.value(value: authService),
                ],
                child: BlocProvider<SyncBloc>.value(
                  value: syncBloc,
                  child: const CoordinatorDashboardScreen(tenantId: 'org-1'),
                ),
              ),
            ),
            GoRoute(
              path: '/coordinator/time-slots/new',
              builder: (_, _) => const Scaffold(body: Text('nouveau-creneau')),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        orgStream.add(buildOrg(deliveries: []));
        await tester.pumpAndSettle();

        expect(find.text('➕ NOUVEAU CRÉNEAU'), findsOneWidget);

        await tester.tap(find.text('➕ NOUVEAU CRÉNEAU'));
        await tester.pumpAndSettle();

        expect(find.text('nouveau-creneau'), findsOneWidget);
      },
    );

    testWidgets('tapping a delivery card opens the tracking detail route', (
      tester,
    ) async {
      final delivery = buildDelivery(
        deliveryId: 'd-99',
        status: DeliveryStatus.inProgress,
        scheduledDate: tomorrowIso(),
      );
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => MultiRepositoryProvider(
              providers: [
                RepositoryProvider<OrganizationRepository>.value(value: repo),
                RepositoryProvider<MemberRepository>.value(value: memberRepo),
                RepositoryProvider<ContractRepository>.value(
                  value: contractRepo,
                ),
                RepositoryProvider<AuthService>.value(value: authService),
              ],
              child: BlocProvider<SyncBloc>.value(
                value: syncBloc,
                child: const CoordinatorDashboardScreen(tenantId: 'org-1'),
              ),
            ),
          ),
          GoRoute(
            path: '/coordinator/tracking/:deliveryId',
            builder: (_, state) => Scaffold(
              body: Text('tracking-${state.pathParameters['deliveryId']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.text('tracking-d-99'), findsOneWidget);
    });
  });
}

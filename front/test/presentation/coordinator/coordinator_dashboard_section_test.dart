import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRepository orgRepo,
  required MemberRepository memberRepo,
  required SyncBloc syncBloc,
  required AuthService authService,
  String tenantId = 'org-1',
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoordinatorDashboardSection(tenantId: tenantId),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Member _buildMember({
  String memberId = 'member-1',
  String? firstName = 'Jean',
  String? lastName = 'Morel',
  String? phone,
}) => Member(
  memberId: memberId,
  organizationId: 'org-1',
  firstName: firstName,
  lastName: lastName,
  phone: phone,
);

/// Builds a minimal (unsigned) JWT with the given sub claim.
String _fakeJwt(String sub) {
  final payload = base64Url
      .encode(utf8.encode('{"sub":"$sub","exp":9999999999}'))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockSyncBloc syncBloc;
  late _MockAuthService authService;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(const SyncEvent.mutationApplied());
    registerFallbackValue(
      const Organization(
        organizationId: 'fallback',
        name: '',
        contactEmail: '',
      ),
    );
    registerFallbackValue(
      const Delivery(
        deliveryId: 'fallback',
        organizationId: 'fallback',
        scheduledDate: '2099-01-01T00:00:00',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 1,
      ),
    );
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    syncBloc = _MockSyncBloc();
    authService = _MockAuthService();
    when(
      () => authService.currentState,
    ).thenReturn(const AuthState.unauthenticated());
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(null));
  });

  group('CoordinatorDashboardSection — delivery sort order', () {
    testWidgets('in-progress deliveries are sorted by date ascending', (
      tester,
    ) async {
      final earlyDate = daysFromNowIso(2);
      final lateDate = daysFromNowIso(5);

      final dLate = buildDelivery(
        deliveryId: 'd-late',
        status: DeliveryStatus.inProgress,
        scheduledDate: lateDate,
      );
      final dEarly = buildDelivery(
        deliveryId: 'd-early',
        status: DeliveryStatus.inProgress,
        scheduledDate: earlyDate,
      );
      // Pass late first to prove sorting is needed.
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [dLate, dEarly])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      String formatTitle(String isoDate) {
        final raw = DateFormat(
          "EEEE d MMMM • HH'h'mm",
          'fr',
        ).format(DateTime.parse(isoDate));
        return raw[0].toUpperCase() + raw.substring(1);
      }

      final earlyTitle = formatTitle(earlyDate);
      final lateTitle = formatTitle(lateDate);

      expect(find.text(earlyTitle), findsOneWidget);
      expect(find.text(lateTitle), findsOneWidget);

      // Earlier delivery card must appear above the later one.
      expect(
        tester.getTopLeft(find.text(earlyTitle)).dy,
        lessThan(tester.getTopLeft(find.text(lateTitle)).dy),
      );
    });

    testWidgets('upcoming deliveries are sorted by date ascending', (
      tester,
    ) async {
      final earlyDate = daysFromNowIso(3);
      final lateDate = daysFromNowIso(7);

      final dLate = buildDelivery(
        deliveryId: 'd-late',
        status: DeliveryStatus.planned,
        scheduledDate: lateDate,
      );
      final dEarly = buildDelivery(
        deliveryId: 'd-early',
        status: DeliveryStatus.planned,
        scheduledDate: earlyDate,
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [dLate, dEarly])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      String formatTitle(String isoDate) {
        final raw = DateFormat(
          "EEEE d MMMM • HH'h'mm",
          'fr',
        ).format(DateTime.parse(isoDate));
        return raw[0].toUpperCase() + raw.substring(1);
      }

      final earlyTitle = formatTitle(earlyDate);
      final lateTitle = formatTitle(lateDate);

      expect(find.text(earlyTitle), findsOneWidget);
      expect(find.text(lateTitle), findsOneWidget);

      expect(
        tester.getTopLeft(find.text(earlyTitle)).dy,
        lessThan(tester.getTopLeft(find.text(lateTitle)).dy),
      );
    });
  });

  group('CoordinatorDashboardSection — compact coordinator line', () {
    testWidgets('shows compact coordinator line on in-progress delivery card', (
      tester,
    ) async {
      final coordinator = _buildMember(
        memberId: 'coord-1',
        firstName: 'Jean',
        lastName: 'Morel',
      );
      when(
        () => memberRepo.watch(any()),
      ).thenAnswer((_) => Stream.value([coordinator]));

      final contract = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Panier légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Coord. :'), findsOneWidget);
      expect(find.textContaining('J. Morel'), findsOneWidget);
    });

    testWidgets('shows "—" in compact line when contract has no coordinator', (
      tester,
    ) async {
      final contract = buildContract(
        contractId: 'c-1',
        coordinators: const [],
        deliveryDescription: 'Panier légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.planned,
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Coord. :'), findsOneWidget);
      // The compact format uses '—' for empty coordinators.
      expect(find.textContaining('—'), findsOneWidget);
    });

    testWidgets('shows compact line on upcoming delivery card', (tester) async {
      final coordinator = _buildMember(
        memberId: 'coord-1',
        firstName: 'Claire',
        lastName: 'Petit',
      );
      when(
        () => memberRepo.watch(any()),
      ).thenAnswer((_) => Stream.value([coordinator]));

      final contract = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Panier légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.planned,
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Coord. :'), findsOneWidget);
      expect(find.textContaining('C. Petit'), findsOneWidget);
    });

    testWidgets('shows multiple contracts separated by " · " in compact line', (
      tester,
    ) async {
      final coord1 = _buildMember(
        memberId: 'coord-1',
        firstName: 'Jean',
        lastName: 'Morel',
      );
      final coord2 = _buildMember(
        memberId: 'coord-2',
        firstName: 'Marc',
        lastName: 'Olivier',
      );
      when(
        () => memberRepo.watch(any()),
      ).thenAnswer((_) => Stream.value([coord1, coord2]));

      final contract1 = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Légumes',
      );
      final contract2 = buildContract(
        contractId: 'c-2',
        coordinators: ['coord-2'],
        deliveryDescription: 'Pain',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.planned,
        scheduledDate: tomorrowIso(),
        contracts: [contract1, contract2],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Both coordinator abbreviations should appear in the compact line.
      expect(find.textContaining('J. Morel'), findsOneWidget);
      expect(find.textContaining('M. Olivier'), findsOneWidget);
    });
  });

  group('CoordinatorDashboardSection — missing coordinator banner', () {
    testWidgets(
      'shows ⚠️ banner when at least one contract has no coordinator',
      (tester) async {
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const [],
          deliveryDescription: 'Pain artisanal',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();

        expect(find.textContaining('Coordinateur manquant'), findsOneWidget);
        expect(find.textContaining('Pain artisanal'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'does not show ⚠️ banner when all contracts have at least one coordinator',
      (tester) async {
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const ['coord-1'],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();

        expect(find.textContaining('Coordinateur manquant'), findsNothing);
      },
    );
  });

  group('CoordinatorDashboardSection — ME PORTER COORDINATEUR', () {
    testWidgets(
      'button is present on a card with one empty contract and active delivery',
      (tester) async {
        when(() => memberRepo.watchMyMember(any())).thenAnswer(
          (_) => Stream.value(
            _buildMember(memberId: 'me-1', firstName: 'Marie', lastName: 'P'),
          ),
        );
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'tenant-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const [],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));
        when(
          () => orgRepo.assignCoordinator(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('ME PORTER COORDINATEUR'), findsOneWidget);
      },
    );

    testWidgets(
      'tap on single-contract card calls assignCoordinator with correct ids',
      (tester) async {
        const myId = 'me-1';
        const cId = 'c-single';
        const dId = 'd-single';

        when(() => memberRepo.watchMyMember(any())).thenAnswer(
          (_) => Stream.value(Member(memberId: myId, organizationId: 'org-1')),
        );
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'tenant-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        final contract = buildContract(
          contractId: cId,
          coordinators: const [],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          deliveryId: dId,
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        final org = buildOrg(deliveries: [delivery]);
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => orgRepo.assignCoordinator(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.text('ME PORTER COORDINATEUR'));
        await tester.pumpAndSettle();

        verify(
          () => orgRepo.assignCoordinator(
            currentOrg: org,
            deliveryId: dId,
            contractId: cId,
            memberId: myId,
          ),
        ).called(1);
        verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      },
    );

    testWidgets(
      'tap on multi-contract card opens selector; choosing a contract calls assignCoordinator',
      (tester) async {
        const myId = 'me-2';
        const c1Id = 'c-vegs';
        const c2Id = 'c-bread';
        const dId = 'd-multi';

        when(() => memberRepo.watchMyMember(any())).thenAnswer(
          (_) => Stream.value(Member(memberId: myId, organizationId: 'org-1')),
        );
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'tenant-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        final c1 = buildContract(
          contractId: c1Id,
          coordinators: const [],
          deliveryDescription: 'Légumes',
        );
        final c2 = buildContract(
          contractId: c2Id,
          coordinators: const [],
          deliveryDescription: 'Pain',
        );
        final delivery = buildDelivery(
          deliveryId: dId,
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [c1, c2],
        );
        final org = buildOrg(deliveries: [delivery]);
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => orgRepo.assignCoordinator(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Only one "ME PORTER COORDINATEUR" button visible.
        expect(find.text('ME PORTER COORDINATEUR'), findsOneWidget);

        await tester.tap(find.text('ME PORTER COORDINATEUR'));
        await tester.pumpAndSettle();

        // Bottom sheet should list both contracts.
        expect(find.text('Légumes'), findsAtLeastNWidgets(1));
        expect(find.text('Pain'), findsAtLeastNWidgets(1));

        // Select "Pain".
        await tester.tap(find.text('Pain').last);
        await tester.pumpAndSettle();

        verify(
          () => orgRepo.assignCoordinator(
            currentOrg: org,
            deliveryId: dId,
            contractId: c2Id,
            memberId: myId,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'button is absent when all contracts have at least one coordinator',
      (tester) async {
        when(() => memberRepo.watchMyMember(any())).thenAnswer(
          (_) => Stream.value(
            _buildMember(memberId: 'me-1', firstName: 'A', lastName: 'B'),
          ),
        );
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'tenant-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const ['me-1'],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('ME PORTER COORDINATEUR'), findsNothing);
      },
    );

    testWidgets(
      'button is absent when me is null and there are no missing contracts either',
      (tester) async {
        // All contracts filled, me is null
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const ['someone'],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          syncBloc: syncBloc,
          authService: authService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('ME PORTER COORDINATEUR'), findsNothing);
      },
    );

    testWidgets('MISSING_COORDINATOR sync rejection shows a generic SnackBar', (
      tester,
    ) async {
      final contract = buildContract(
        contractId: 'c-1',
        coordinators: const [],
        deliveryDescription: 'Légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.confirmed,
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      // Broadcast stream supports multiple listeners (BlocProvider + MissingCoordinatorListener).
      final syncStateController = StreamController<SyncState>.broadcast();
      when(() => syncBloc.stream).thenAnswer((_) => syncStateController.stream);

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        syncBloc: syncBloc,
        authService: authService,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Emit a SyncSucceeded with a MISSING_COORDINATOR rejection.
      syncStateController.add(
        const SyncState.success(
          rejectedMutations: [
            MutationOutcome(
              clientOpId: 'op-confirm',
              status: MutationStatus.rejected,
              error: MutationError(
                code: MutationErrorCode.missingCoordinator,
                message: 'missing',
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('ne peut pas être confirmée'), findsOneWidget);

      await syncStateController.close();
    });
  });
}

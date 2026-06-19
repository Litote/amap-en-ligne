import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/volunteer_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

// ---------------------------------------------------------------------------
// Coordinator member fixture
// ---------------------------------------------------------------------------

Member _buildCoordinatorMember({
  String memberId = 'coord-1',
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

// ---------------------------------------------------------------------------
// Mocks and fakes
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _FakeOrganization extends Fake implements Organization {}

class _FakeMember extends Fake implements Member {}

// ---------------------------------------------------------------------------
// Minimal JWT token whose 'sub' claim is readable by JwtClaims.decode.
// The front only reads the payload — the header and signature are irrelevant.
// ---------------------------------------------------------------------------
String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockMemberRepository memberRepo,
  required _MockDeliveryTemplateRepository templateRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
  String tenantId = 'org-1',
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: templateRepo,
        ),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolunteerDashboardSection(tenantId: tenantId),
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

const _kSub = 'user-sub-1';
const _kMemberId = 'member-1';

Member _buildMember({String memberId = _kMemberId}) => Member(
  memberId: memberId,
  organizationId: 'org-1',
  firstName: 'Marie',
  lastName: 'Dupont',
);

String _futureDate() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return '${tomorrow.year}-'
      '${tomorrow.month.toString().padLeft(2, '0')}-'
      '${tomorrow.day.toString().padLeft(2, '0')}'
      'T18:00:00';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(_FakeOrganization());
    registerFallbackValue(_FakeMember());
    registerFallbackValue(SlotKind.standard);
  });

  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockDeliveryTemplateRepository templateRepo;
  late _MockAuthService authService;
  late _MockSyncBloc syncBloc;
  late StreamController<Organization?> orgStream;
  late StreamController<Member?> memberStream;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    templateRepo = _MockDeliveryTemplateRepository();
    authService = _MockAuthService();
    syncBloc = _MockSyncBloc();

    orgStream = StreamController<Organization?>.broadcast();
    memberStream = StreamController<Member?>.broadcast();

    when(() => orgRepo.watch(any())).thenAnswer((_) => orgStream.stream);
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => memberStream.stream);
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => templateRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <DeliveryTemplate>[]));
    when(() => authService.currentState).thenReturn(
      AuthState.authenticated(
        producerId: 'prod-1',
        accessToken: _fakeToken(_kSub),
        roles: ['VOLUNTEER'],
      ),
    );
    whenListen(
      syncBloc,
      const Stream<SyncState>.empty(),
      initialState: const SyncState.idle(),
    );
  });

  tearDown(() async {
    await orgStream.close();
    await memberStream.close();
  });

  group('VolunteerDashboardSection', () {
    testWidgets('shows loading indicator before org is available', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator when org loaded but member is null', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      await tester.pump();

      // Emit org but no member.
      orgStream.add(buildOrg(deliveries: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows "Prochaines livraisons" section when org and member are loaded',
      (tester) async {
        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: []));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('📋 Prochaines livraisons'), findsOneWidget);
      },
    );

    testWidgets(
      "not-registered member sees S'INSCRIRE button; tap calls registerToSlot",
      (tester) async {
        final slot = buildSlot(
          requiredVolunteers: 3,
          currentRegistrations: 1,
          registrations: [],
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: _futureDate(),
          contracts: [contract],
        );
        final org = buildOrg(deliveries: [delivery]);

        when(
          () => orgRepo.registerToSlot(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            slotKind: any(named: 'slotKind'),
            me: any(named: 'me'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(org);
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text("S'INSCRIRE"), findsOneWidget);

        await tester.tap(find.text("S'INSCRIRE"));
        await tester.pump();

        verify(
          () => orgRepo.registerToSlot(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: 'd-1',
            contractId: 'c-1',
            slotKind: SlotKind.standard,
            me: any(named: 'me'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'registered member sees "Ma prochaine participation" and SE DÉSINSCRIRE; tap calls unregisterFromSlot',
      (tester) async {
        final reg = buildRegistration(
          memberId: _kMemberId,
          status: RegistrationStatus.registered,
        );
        final slot = buildSlot(
          requiredVolunteers: 3,
          currentRegistrations: 1,
          registrations: [reg],
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: _futureDate(),
          contracts: [contract],
        );
        final org = buildOrg(deliveries: [delivery]);

        when(
          () => orgRepo.unregisterFromSlot(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            slotKind: any(named: 'slotKind'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(org);
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('🎯 Ma prochaine participation'), findsOneWidget);
        expect(find.text('SE DÉSINSCRIRE'), findsAtLeastNWidgets(1));

        // Tap the first SE DÉSINSCRIRE (in the "Ma prochaine participation" card).
        await tester.tap(find.text('SE DÉSINSCRIRE').first);
        await tester.pump();

        verify(
          () => orgRepo.unregisterFromSlot(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: 'd-1',
            contractId: any(named: 'contractId'),
            slotKind: any(named: 'slotKind'),
            memberId: _kMemberId,
          ),
        ).called(1);
      },
    );

    testWidgets(
      '"Ma prochaine participation" shows aggregate volunteer count across all slots',
      (tester) async {
        final reg = buildRegistration(
          memberId: _kMemberId,
          status: RegistrationStatus.registered,
        );
        final slot1 = buildSlot(
          requiredVolunteers: 6,
          currentRegistrations: 1,
          registrations: [reg],
        ).copyWith(slotKind: SlotKind.standard);
        final slot2 = buildSlot(
          requiredVolunteers: 7,
          currentRegistrations: 0,
        ).copyWith(slotKind: SlotKind.early);
        final contract = buildContract(
          contractId: 'c-1',
          slots: [slot1, slot2],
        );
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: _futureDate(),
          contracts: [contract],
        );
        final org = buildOrg(deliveries: [delivery]);

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(org);
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('🎯 Ma prochaine participation'), findsOneWidget);
        // Should show aggregate: 1/(6+7) = 1/13, not just 1/6
        expect(find.text('👥 1/13 bénévoles confirmés'), findsOneWidget);
      },
    );

    testWidgets(
      'EARLY + STANDARD capacity available shows two labeled register buttons',
      (tester) async {
        final standardSlot = buildSlot(
          requiredVolunteers: 3,
          currentRegistrations: 0,
          startTime: '2025-06-14T18:00:00',
          endTime: '2025-06-14T20:00:00',
        ).copyWith(slotKind: SlotKind.standard);
        final earlySlot = buildSlot(
          requiredVolunteers: 2,
          currentRegistrations: 0,
          startTime: '2025-06-14T17:00:00',
          endTime: '2025-06-14T18:00:00',
        ).copyWith(slotKind: SlotKind.early);
        final contract = buildContract(
          contractId: 'c-1',
          slots: [standardSlot, earlySlot],
        );
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: _futureDate(),
          contracts: [contract],
        ).copyWith(deliveryTemplateId: 'tpl-1');
        final org = buildOrg(deliveries: [delivery]);

        // EARLY capacity is template-driven (earlySlot.maxVolunteers): without a
        // template the early button is hidden.
        const template = DeliveryTemplate(
          deliveryTemplateId: 'tpl-1',
          organizationId: 'org-1',
          name: 'Standard',
          standardStartTime: '18:00',
          standardEndTime: '20:00',
          earlySlot: EarlySlot(
            arrivalTime: '17:00',
            explanation: 'Arrivée anticipée',
            maxVolunteers: 2,
          ),
        );
        when(
          () => templateRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(const [template]));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(org);
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Créneau standard'), findsOneWidget);
        // Two occurrences of "Créneau anticipé": the urgency badge and the
        // early-slot register button label.
        expect(find.textContaining('Créneau anticipé'), findsNWidgets(2));
      },
    );

    testWidgets(
      'full slot shows disabled COMPLET button and no S\'INSCRIRE button',
      (tester) async {
        final slot = buildSlot(
          requiredVolunteers: 2,
          currentRegistrations: 2,
          registrations: [],
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: _futureDate(),
          contracts: [contract],
        );
        final org = buildOrg(deliveries: [delivery]);

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(org);
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('✅ COMPLET'), findsOneWidget);
        expect(find.text("S'INSCRIRE"), findsNothing);
      },
    );

    testWidgets('shows footer navigation buttons', (tester) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('VOIR PLANNING COMPLET'), findsOneWidget);
      expect(find.text('MON HISTORIQUE'), findsOneWidget);
    });
  });

  group('Coordinators compact line', () {
    testWidgets(
      'shows abbreviated name "J. Morel" for a coordinator with firstName/lastName',
      (tester) async {
        final coordinator = _buildCoordinatorMember(
          memberId: 'coord-1',
          firstName: 'Jean',
          lastName: 'Morel',
        );
        when(
          () => memberRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([coordinator]));

        // Slot needed so upcomingActiveDeliveries includes this delivery.
        final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: ['coord-1'],
          deliveryDescription: 'Légumes',
          slots: [slot],
        );
        final delivery = buildDelivery(
          scheduledDate: _futureDate(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        // Allow the _allMembersSub Stream.value microtask to complete.
        await tester.pump(const Duration(milliseconds: 10));

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('J. Morel'), findsOneWidget);
      },
    );

    testWidgets('shows "—" when contract coordinators list is empty', (
      tester,
    ) async {
      // Slot needed so upcomingActiveDeliveries includes this delivery.
      final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
      final contract = buildContract(
        contractId: 'c-1',
        coordinators: const [],
        deliveryDescription: 'Légumes',
        slots: [slot],
      );
      final delivery = buildDelivery(
        scheduledDate: _futureDate(),
        contracts: [contract],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // When no coordinators, the compact line shows '—'.
      expect(find.textContaining('—'), findsOneWidget);
    });

    testWidgets('multiple contracts are separated by " · " in compact line', (
      tester,
    ) async {
      final coord1 = _buildCoordinatorMember(
        memberId: 'coord-1',
        firstName: 'Jean',
        lastName: 'Morel',
      );
      final coord2 = _buildCoordinatorMember(
        memberId: 'coord-2',
        firstName: 'Claire',
        lastName: 'Petit',
      );
      when(
        () => memberRepo.watch(any()),
      ).thenAnswer((_) => Stream.value([coord1, coord2]));

      // Slots needed so upcomingActiveDeliveries includes this delivery.
      final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
      final contract1 = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Légumes',
        slots: [slot],
      );
      final contract2 = buildContract(
        contractId: 'c-2',
        coordinators: ['coord-2'],
        deliveryDescription: 'Pain',
        slots: [slot],
      );
      final delivery = buildDelivery(
        scheduledDate: _futureDate(),
        contracts: [contract1, contract2],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      // Allow the _allMembersSub Stream.value microtask to complete.
      await tester.pump(const Duration(milliseconds: 10));

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Both abbreviations appear in the single compact text widget.
      expect(find.textContaining('J. Morel'), findsOneWidget);
      expect(find.textContaining('C. Petit'), findsOneWidget);
    });

    testWidgets(
      'exposes the coordinator phone as a tel: link on the compact line',
      (tester) async {
        final coordinator = _buildCoordinatorMember(
          memberId: 'coord-1',
          firstName: 'Jean',
          lastName: 'Morel',
          phone: '06 12 34 56 78',
        );
        when(
          () => memberRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([coordinator]));

        // Slot needed so upcomingActiveDeliveries includes this delivery.
        final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: ['coord-1'],
          deliveryDescription: 'Légumes',
          slots: [slot],
        );
        final delivery = buildDelivery(
          scheduledDate: _futureDate(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        // Allow the _allMembersSub Stream.value microtask to complete.
        await tester.pump(const Duration(milliseconds: 10));

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // The coordinator's phone now appears as a tappable tel: link on the
        // volunteer dashboard, consistent with the planning + tracking screens.
        expect(find.textContaining('06 12 34 56 78'), findsOneWidget);
      },
    );
  });
}

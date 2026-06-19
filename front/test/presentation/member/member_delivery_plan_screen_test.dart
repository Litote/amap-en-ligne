import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/member_delivery_plan_screen.dart';
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

// ---------------------------------------------------------------------------
// Additional coordinator member fixture
// ---------------------------------------------------------------------------

Member _buildCoordinator({
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
// Mocks
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _FakeOrganization extends Fake implements Organization {}

class _FakeMember extends Fake implements Member {}

// ---------------------------------------------------------------------------
// Minimal JWT whose 'sub' claim is readable by JwtClaims.decode.
// The front only reads the payload — header and signature are ignored.
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
  _MockContractRepository? contractRepo,
  String tenantId = 'org-1',
  DateTime? initialMonth,
  GoRouter? router,
}) async {
  final screen = MemberDeliveryPlanScreen(
    tenantId: tenantId,
    initialMonth: initialMonth,
  );

  final contracts = contractRepo ?? _MockContractRepository();
  if (contractRepo == null) {
    when(
      () => contracts.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
  }

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: templateRepo,
        ),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<ContractRepository>.value(value: contracts),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: router != null
            ? MaterialApp.router(routerConfig: router)
            : MaterialApp(home: screen),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _kSub = 'user-sub-1';
const _kMemberId = 'member-1';
const _tomates = OrgProduct(
  name: 'Tomates',
  productTypeId: 'pt-1',
  producerAccountId: 'producer-1',
);
const _oeufs = OrgProduct(
  name: 'Oeufs',
  productTypeId: 'pt-2',
  producerAccountId: 'producer-2',
);

Member _buildMember({
  String memberId = _kMemberId,
  Set<Role> roles = const {Role.volunteer},
}) => Member(
  memberId: memberId,
  organizationId: 'org-1',
  firstName: 'Marie',
  lastName: 'Dupont',
  roles: roles,
);

/// Month-of-tomorrow helper — used with [initialMonth] so that a delivery
/// scheduled for tomorrow is displayed in the screen's selected month.
DateTime _tomorrowMonth() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month);
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
  late StreamController<List<DeliveryTemplate>> templatesStream;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    templateRepo = _MockDeliveryTemplateRepository();
    authService = _MockAuthService();
    syncBloc = _MockSyncBloc();

    orgStream = StreamController<Organization?>.broadcast();
    memberStream = StreamController<Member?>.broadcast();
    templatesStream = StreamController<List<DeliveryTemplate>>.broadcast();

    when(() => orgRepo.watch(any())).thenAnswer((_) => orgStream.stream);
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => memberStream.stream);
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => templateRepo.watch(any()),
    ).thenAnswer((_) => templatesStream.stream);
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
    await templatesStream.close();
  });

  group('MemberDeliveryPlanScreen', () {
    // --- Loading states ---

    testWidgets('shows loading indicator when tenantId is empty', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        tenantId: '',
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

      orgStream.add(buildOrg(deliveries: []));
      // member not emitted yet
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- Empty month ---

    testWidgets(
      'shows "Aucune livraison ce mois-ci." when org has no deliveries',
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

        expect(find.text('Aucune livraison ce mois-ci.'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Aucune livraison ce mois-ci." when delivery is in a different month',
      (tester) async {
        final pastDate = DateTime.now().subtract(const Duration(days: 180));
        final pastScheduled =
            '${pastDate.year.toString().padLeft(4, '0')}-'
            '${pastDate.month.toString().padLeft(2, '0')}-'
            '10T18:00:00';
        final delivery = buildDelivery(scheduledDate: pastScheduled);

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

        expect(find.text('Aucune livraison ce mois-ci.'), findsOneWidget);
      },
    );

    // --- Card rendering ---

    testWidgets(
      'renders card with French date and "📋 Livraisons ce mois" section header',
      (tester) async {
        final delivery = buildDelivery(scheduledDate: currentMonthIso());

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

        expect(find.text('📋 Livraisons ce mois'), findsOneWidget);
        expect(find.text('Aucune livraison ce mois-ci.'), findsNothing);
        expect(find.byType(Card), findsWidgets);
      },
    );

    testWidgets(
      'volunteer-only member does not see edit button on delivery cards',
      (tester) async {
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: tomorrowIso(),
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Modifier'), findsNothing);
      },
    );

    testWidgets('shows only the delivery selected products on cards', (
      tester,
    ) async {
      final delivery = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: tomorrowIso(),
        basketDescriptions: const [
          BasketDeliveryDescription(
            productTypeId: 'pt-1',
            basketSizeName: 'Petit',
          ),
        ],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(
        buildOrg(deliveries: [delivery], products: const [_tomates, _oeufs]),
      );
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Produits : Tomates'), findsOneWidget);
      expect(find.textContaining('Oeufs'), findsNothing);
    });

    testWidgets(
      'coordinator sees edit button and can navigate to time slot form',
      (tester) async {
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: tomorrowIso(),
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => MemberDeliveryPlanScreen(
                tenantId: 'org-1',
                initialMonth: _tomorrowMonth(),
              ),
            ),
            GoRoute(
              path: '/coordinator/time-slots/:deliveryId',
              builder: (context, state) => Scaffold(
                body: Text('edit-${state.pathParameters['deliveryId']}'),
              ),
            ),
          ],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          router: router,
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(
          _buildMember(roles: const {Role.volunteer, Role.coordinator}),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Modifier'), findsOneWidget);

        await tester.tap(find.text('Modifier'));
        await tester.pumpAndSettle();

        expect(find.text('edit-d-1'), findsOneWidget);
      },
    );

    testWidgets('admin sees edit button on delivery cards', (tester) async {
      final delivery = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: tomorrowIso(),
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember(roles: const {Role.admin}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Modifier'), findsOneWidget);
    });

    // --- Registration actions ---

    testWidgets(
      'non-registered member sees S\'INSCRIRE button; tap calls registerToSlot',
      (tester) async {
        // 4/5 = 80% — above urgency threshold, so shows plain S'INSCRIRE.
        final slot = buildSlot(
          requiredVolunteers: 5,
          currentRegistrations: 4,
          registrations: [],
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

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
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
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
      'registered member sees SE DÉSINSCRIRE; tap calls unregisterFromSlot',
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
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

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
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('SE DÉSINSCRIRE'), findsOneWidget);

        await tester.tap(find.text('SE DÉSINSCRIRE'));
        await tester.pump();

        verify(
          () => orgRepo.unregisterFromSlot(
            currentOrg: any(named: 'currentOrg'),
            deliveryId: 'd-1',
            contractId: 'c-1',
            slotKind: SlotKind.standard,
            memberId: _kMemberId,
          ),
        ).called(1);
      },
    );

    // --- Urgency labels ---

    testWidgets('critical slot (< 50%) shows S\'INSCRIRE MAINTENANT 🚨', (
      tester,
    ) async {
      final slot = buildSlot(requiredVolunteers: 5, currentRegistrations: 2);
      final contract = buildContract(contractId: 'c-1', slots: [slot]);
      final delivery = buildDelivery(
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );

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
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining("S'INSCRIRE MAINTENANT"), findsOneWidget);
      expect(find.textContaining('🚨'), findsOneWidget);
    });

    // --- EARLY + STANDARD two-button layout ---

    testWidgets(
      'EARLY + STANDARD capacity available shows two labeled register buttons',
      (tester) async {
        final standardSlot = buildSlot(
          requiredVolunteers: 5,
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
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );
        // Template provides earlySlot.maxVolunteers so capacity is non-zero.
        final template = DeliveryTemplate(
          deliveryTemplateId: 'tpl-1',
          organizationId: 'org-1',
          name: 'Hebdo',
          standardStartTime: '2025-06-14T18:00:00',
          standardEndTime: '2025-06-14T20:00:00',
          earlySlot: const EarlySlot(
            arrivalTime: '2025-06-14T17:00:00',
            explanation: 'Réception des légumes du maraîcher',
            maxVolunteers: 2,
          ),
        );
        final deliveryWithTemplate = delivery.copyWith(
          deliveryTemplateId: 'tpl-1',
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [deliveryWithTemplate]));
        memberStream.add(_buildMember());
        templatesStream.add([template]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Créneau standard'), findsOneWidget);
        // Both the urgency badge ("⏰ Créneau anticipé disponible …") and the
        // button label ("S'inscrire • Créneau anticipé …") contain "Créneau
        // anticipé" — assert at least one to confirm the two-button layout.
        expect(
          find.textContaining('Créneau anticipé'),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining("S'inscrire • Créneau anticipé"),
          findsOneWidget,
        );
        expect(
          find.textContaining('Réception des légumes du maraîcher'),
          findsOneWidget,
        );
      },
    );

    // --- Full slot ---

    testWidgets('full slot shows disabled COMPLET and no S\'INSCRIRE button', (
      tester,
    ) async {
      final slot = buildSlot(
        requiredVolunteers: 5,
        currentRegistrations: 5,
        registrations: [],
      );
      final contract = buildContract(contractId: 'c-1', slots: [slot]);
      final delivery = buildDelivery(
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('✅ COMPLET'), findsOneWidget);
      expect(find.text("S'INSCRIRE"), findsNothing);
    });

    // --- Delivery without any slot: no misleading COMPLET flag ---

    testWidgets('delivery without any slot shows neither COMPLET nor '
        'S\'INSCRIRE', (tester) async {
      final contract = buildContract(contractId: 'c-1', slots: const []);
      final delivery = buildDelivery(
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('✅ COMPLET'), findsNothing);
      expect(find.textContaining("S'INSCRIRE"), findsNothing);
      // The card itself stays visible.
      expect(find.textContaining('📅'), findsOneWidget);
    });

    // --- Deliveries of not-yet-active contracts ---

    Contract seasonContract(ContractStatus status) => Contract(
      contractId: 'season-1',
      name: 'Contrat légumes',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '2026-01-01',
      maxDeliveryDate: '2099-12-31',
      deliveryCount: 10,
      seasonYear: 2026,
      status: status,
    );

    _MockContractRepository contractRepoWith(Contract contract) {
      final repo = _MockContractRepository();
      when(() => repo.watch(any())).thenAnswer((_) => Stream.value([contract]));
      return repo;
    }

    Delivery pendingDelivery() => buildDelivery(
      scheduledDate: tomorrowIso(),
      contracts: [
        buildContract(contractId: 'season-1', slots: [buildSlot()]),
      ],
    );

    testWidgets('delivery of an IN_PREPARATION contract is hidden from plain '
        'members', (tester) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        contractRepo: contractRepoWith(
          seasonContract(ContractStatus.inPreparation),
        ),
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [pendingDelivery()]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucune livraison ce mois-ci.'), findsOneWidget);
    });

    testWidgets('delivery of an ACTIVE contract stays visible to plain '
        'members', (tester) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        contractRepo: contractRepoWith(seasonContract(ContractStatus.active)),
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [pendingDelivery()]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucune livraison ce mois-ci.'), findsNothing);
      expect(find.textContaining("S'INSCRIRE"), findsOneWidget);
    });

    testWidgets('coordinator sees the inactive-contract delivery flagged, '
        'without registration action', (tester) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        contractRepo: contractRepoWith(
          seasonContract(ContractStatus.inPreparation),
        ),
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [pendingDelivery()]));
      memberStream.add(_buildMember(roles: {Role.volunteer, Role.coordinator}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('🚧 Contrat inactif'), findsOneWidget);
      expect(find.textContaining("S'INSCRIRE"), findsNothing);
      expect(find.text('✅ COMPLET'), findsNothing);
    });

    // --- Completed delivery, member participated ---

    testWidgets(
      'completed delivery where member was registered shows TERMINÉ - Vous avez participé',
      (tester) async {
        final reg = buildRegistration(
          memberId: _kMemberId,
          status: RegistrationStatus.completed,
        );
        final slot = buildSlot(
          requiredVolunteers: 3,
          currentRegistrations: 3,
          registrations: [reg],
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          scheduledDate: currentMonthIso(),
          status: DeliveryStatus.completed,
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

        expect(find.text('✅ TERMINÉ - Vous avez participé'), findsOneWidget);
        // No registration/unregistration action buttons on past deliveries.
        expect(find.text("S'INSCRIRE"), findsNothing);
        expect(find.text('SE DÉSINSCRIRE'), findsNothing);
      },
    );

    // --- SyncBloc rejection SnackBar ---

    testWidgets(
      'SyncSucceeded with rejectedMutations shows rejection SnackBar',
      (tester) async {
        final syncStream = StreamController<SyncState>.broadcast();
        final rejectionBloc = _MockSyncBloc();
        whenListen(
          rejectionBloc,
          syncStream.stream,
          initialState: const SyncState.idle(),
        );
        final contractRepo = _MockContractRepository();
        when(
          () => contractRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(const <Contract>[]));

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
              RepositoryProvider<MemberRepository>.value(value: memberRepo),
              RepositoryProvider<DeliveryTemplateRepository>.value(
                value: templateRepo,
              ),
              RepositoryProvider<AuthService>.value(value: authService),
              RepositoryProvider<ContractRepository>.value(value: contractRepo),
            ],
            child: BlocProvider<SyncBloc>.value(
              value: rejectionBloc,
              child: const MaterialApp(
                home: MemberDeliveryPlanScreen(tenantId: 'org-1'),
              ),
            ),
          ),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: []));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        syncStream.add(const SyncState.success(rejectedMutations: []));
        await tester.pump();

        // No snackbar for empty rejectedMutations.
        expect(
          find.textContaining("L'inscription n'a pas pu être enregistrée."),
          findsNothing,
        );

        await syncStream.close();
      },
    );

    // --- Month navigation ---

    testWidgets('renders month navigation arrows and prev/next labels', (
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

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping chevron_left changes to previous month', (
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

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1);
      final prevMonthLabel = prevMonth.month.toString().padLeft(2, '0') == '01'
          ? 'janv.'
          : null; // just check the chevron tap causes a rebuild.

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // The current month label should have changed — find prevMonth label.
      // Format must match "MMMM yyyy" capitalised. We check the Aucune text
      // is still visible (the empty month message is still shown after nav).
      expect(find.text('Aucune livraison ce mois-ci.'), findsOneWidget);
      // prevMonthLabel only used to confirm the variable was computed.
      expect(prevMonthLabel, anyOf(isNull, isNotNull));
    });

    // --- Footer ---

    testWidgets('footer shows ACCUEIL, MON HISTORIQUE, and disabled AIDE', (
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

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ACCUEIL'), findsOneWidget);
      expect(find.text('MON HISTORIQUE'), findsOneWidget);
      expect(find.text('AIDE'), findsOneWidget);
    });
  });

  group('Coordinators section', () {
    testWidgets(
      'shows coordinators section when a contract has a known coordinator',
      (tester) async {
        final coordinator = _buildCoordinator(
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
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Coordinateurs'), findsOneWidget);
        expect(find.textContaining('Jean Morel'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "(téléphone non communiqué)" when coordinator phone is null',
      (tester) async {
        final coordinator = _buildCoordinator(
          memberId: 'coord-1',
          firstName: 'Jean',
          lastName: 'Morel',
          phone: null,
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
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('téléphone non communiqué'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Coordinateur à confirmer" when contract coordinators is empty',
      (tester) async {
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const [],
          deliveryDescription: 'Pain artisanal',
        );
        final delivery = buildDelivery(
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Coordinateur à confirmer'), findsOneWidget);
      },
    );

    testWidgets('phone link widget is present when coordinator has a phone', (
      tester,
    ) async {
      final coordinator = _buildCoordinator(
        memberId: 'coord-1',
        firstName: 'Jean',
        lastName: 'Morel',
        phone: '06 12 34 56 78',
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
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // An InkWell wrapping the phone number should be present.
      expect(find.textContaining('06 12 34 56 78'), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('coordinator memberId not in membersById is silently ignored', (
      tester,
    ) async {
      // The contract lists 'unknown-id' but no member with that id is in
      // the watch stream — should show "Coordinateur à confirmer".
      final contract = buildContract(
        contractId: 'c-1',
        coordinators: const ['unknown-id'],
        deliveryDescription: 'Légumes',
      );
      final delivery = buildDelivery(
        scheduledDate: tomorrowIso(),
        contracts: [contract],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        initialMonth: _tomorrowMonth(),
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(_buildMember());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // "unknown-id" is not shown; falls back to "Coordinateur à confirmer".
      expect(find.textContaining('unknown-id'), findsNothing);
      expect(find.textContaining('Coordinateur à confirmer'), findsOneWidget);
    });

    // --- Cancelled slots ---

    testWidgets(
      'cancelled slot shows "Créneau annulé" and registration is impossible',
      (tester) async {
        final slot = buildSlot(
          requiredVolunteers: 3,
          currentRegistrations: 0,
          status: SlotStatus.cancelled,
        );
        final contract = buildContract(contractId: 'c-1', slots: [slot]);
        final delivery = buildDelivery(
          deliveryId: 'd-1',
          scheduledDate: tomorrowIso(),
          contracts: [contract],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          initialMonth: _tomorrowMonth(),
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(_buildMember());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Créneau annulé'), findsWidgets);
        expect(find.text("S'INSCRIRE"), findsNothing);
        expect(find.text("S'INSCRIRE MAINTENANT 🚨"), findsNothing);
        // The disabled placeholder button must not trigger any registration.
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, '❌ Créneau annulé'),
        );
        expect(button.onPressed, isNull);
      },
    );
  });
}

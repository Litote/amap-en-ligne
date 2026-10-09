import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockMemberRepository memberRepo,
  required _MockBasketExchangeRepository exchangeRepo,
  required _MockContractRepository contractRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
  String tenantId = 'org-1',
  bool showOverview = false,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<BasketExchangeRepository>.value(value: exchangeRepo),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: BasketExchangeScreen(
            tenantId: tenantId,
            showOverview: showOverview,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
    registerFallbackValue(
      const BasketExchange(
        basketExchangeId: 'fallback',
        organizationId: 'org-1',
        deliveryId: 'd-fallback',
        contractId: 'c-fallback',
        offeringMemberId: 'm-fallback',
        status: BasketExchangeStatus.open,
        createdAt: '2026-01-01T00:00:00Z',
      ),
    );
  });

  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockContractRepository contractRepo;
  late _MockAuthService authService;
  late _MockSyncBloc syncBloc;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    exchangeRepo = _MockBasketExchangeRepository();
    contractRepo = _MockContractRepository();
    authService = _MockAuthService();
    syncBloc = _MockSyncBloc();

    // Authenticated state with a fake JWT.
    when(() => authService.currentState).thenReturn(
      const Authenticated(
        accessToken:
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdWItMDAxIiwiZXhwIjo5OTk5OTk5OTk5fQ.fakesig',
        producerId: 'org-1',
      ),
    );

    // Streams that never emit — bloc stays in loading state.
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => const Stream<Organization?>.empty());
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => const Stream<Member?>.empty());
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<Member>>.empty());
    when(
      () => exchangeRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<BasketExchange>>.empty());
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<Contract>>.empty());

    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  group('BasketExchangeScreen smoke', () {
    testWidgets('shows title and loading spinner while streams are pending', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        exchangeRepo: exchangeRepo,
        contractRepo: contractRepo,
        authService: authService,
        syncBloc: syncBloc,
      );
      await tester.pump();

      // AppBar title from ConnectedScaffold.
      expect(find.text('Échanges de paniers'), findsOneWidget);
      // Loading state — bloc waits for org + exchange streams to emit.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows member-not-available message and ACTUALISER button when member is null',
      (tester) async {
        final orgController = StreamController<Organization?>.broadcast();
        final memberController = StreamController<Member?>.broadcast();
        final exchangeController =
            StreamController<List<BasketExchange>>.broadcast();

        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => orgController.stream);
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => memberController.stream);
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => exchangeController.stream);

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );

        // Emit org + empty exchanges + null member — bloc must enter
        // unauthorized state.
        orgController.add(
          const Organization(
            organizationId: 'org-1',
            name: 'Test AMAP',
            contactEmail: 'contact@test.com',
          ),
        );
        memberController.add(null);
        exchangeController.add([]);
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('profil de membre'), findsOneWidget);
        expect(find.text('ACTUALISER'), findsOneWidget);

        await orgController.close();
        await memberController.close();
        await exchangeController.close();
      },
    );

    for (final showOverview in [false, true]) {
      testWidgets(
        'VUE D\'ENSEMBLE is ${showOverview ? 'offered to coordinators' : 'hidden from plain members'}',
        (tester) async {
          // Tall window: the footer actions sit at the bottom of the list.
          tester.view.physicalSize = const Size(800, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          when(() => orgRepo.watch(any())).thenAnswer(
            (_) => Stream.value(
              const Organization(
                organizationId: 'org-1',
                name: 'Test AMAP',
                contactEmail: 'contact@test.com',
              ),
            ),
          );
          when(() => memberRepo.watchMyMember(any())).thenAnswer(
            (_) => Stream.value(
              const Member(memberId: 'member-1', organizationId: 'org-1'),
            ),
          );
          when(
            () => exchangeRepo.watch(any()),
          ).thenAnswer((_) => Stream.value(const []));

          await _pump(
            tester,
            orgRepo: orgRepo,
            memberRepo: memberRepo,
            exchangeRepo: exchangeRepo,
            contractRepo: contractRepo,
            authService: authService,
            syncBloc: syncBloc,
            showOverview: showOverview,
          );
          await tester.pump();
          await tester.pump();

          expect(find.text('ACTUALISER'), findsOneWidget);
          expect(
            find.text("VUE D'ENSEMBLE"),
            showOverview ? findsOneWidget : findsNothing,
          );
        },
      );
    }

    testWidgets(
      'does not reopen dialog when org stream re-emits while propose dialog is open',
      (tester) async {
        final orgController = StreamController<Organization?>.broadcast();
        final memberController = StreamController<Member?>.broadcast();
        final exchangeController =
            StreamController<List<BasketExchange>>.broadcast();

        const org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
        );
        const member = Member(
          memberId: 'member-1',
          organizationId: 'org-1',
          firstName: 'Alice',
          lastName: 'Dupont',
        );

        when(
          () => orgRepo.watch(any()),
        ).thenAnswer((_) => orgController.stream);
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => memberController.stream);
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => exchangeController.stream);

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );

        // Reach ready state.
        orgController.add(org);
        memberController.add(member);
        exchangeController.add([]);
        await tester.pump();
        await tester.pump();

        // Open the propose dialog.
        await tester.tap(find.text('PROPOSER UN ÉCHANGE'));
        await tester.pump();
        expect(find.byType(Dialog), findsOneWidget);

        // Simulate a background sync re-emitting the org (same data, new
        // instance). The listenWhen guard must prevent a second dialog from
        // being pushed.
        orgController.add(org);
        await tester.pump();
        await tester.pump();

        // Still exactly one dialog.
        expect(find.byType(Dialog), findsOneWidget);

        await orgController.close();
        await memberController.close();
        await exchangeController.close();
      },
    );

    testWidgets(
      'my open offer names the contract from the live catalog when the '
      'delivery link snapshot is blank (imported data)',
      (tester) async {
        final org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
          deliveries: [
            Delivery(
              deliveryId: 'd-21',
              organizationId: 'org-1',
              scheduledDate: '${DateTime.now().year + 1}-10-21T19:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 1,
              contracts: const [
                DeliveryContract(
                  contractId: 'c-veg',
                  basketQuantity: 10,
                  deliveryDescription: '',
                  status: DeliveryContractStatus.pending,
                ),
              ],
            ),
          ],
        );
        const me = Member(
          memberId: 'sub-001',
          organizationId: 'org-1',
          firstName: 'Bob',
        );
        const exchange = BasketExchange(
          basketExchangeId: 'bx-1',
          organizationId: 'org-1',
          deliveryId: 'd-21',
          contractId: 'c-veg',
          offeringMemberId: 'sub-001',
          status: BasketExchangeStatus.open,
          createdAt: '2026-10-01T12:00:00Z',
        );
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => Stream.value(me));
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([exchange]));
        when(() => contractRepo.watch(any())).thenAnswer(
          (_) => Stream.value(const [
            Contract(
              contractId: 'c-veg',
              name: 'Légumes 2026/2027',
              organizationId: 'org-1',
              producerAccountId: 'pa-1',
              minDeliveryDate: '2026-04-08',
              maxDeliveryDate: '2099-12-31',
              deliveryCount: 37,
              seasonYear: 2026,
            ),
          ]),
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Légumes 2026/2027'), findsOneWidget);
        expect(find.textContaining('c-veg'), findsNothing);
      },
    );

    testWidgets(
      'cancelling my offer asks for confirmation and only cancels once '
      'confirmed',
      (tester) async {
        const org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
        );
        const me = Member(
          memberId: 'sub-001',
          organizationId: 'org-1',
          firstName: 'Bob',
        );
        const exchange = BasketExchange(
          basketExchangeId: 'bx-1',
          organizationId: 'org-1',
          deliveryId: 'd-21',
          contractId: 'c-veg',
          offeringMemberId: 'sub-001',
          status: BasketExchangeStatus.open,
          createdAt: '2026-10-01T12:00:00Z',
        );
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => Stream.value(me));
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([exchange]));
        when(
          () => exchangeRepo.cancelOffer(
            basketExchange: any(named: 'basketExchange'),
            decidedAt: any(named: 'decidedAt'),
          ),
        ).thenAnswer((_) async {});

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pumpAndSettle();

        final cancelOffer = find.widgetWithText(OutlinedButton, 'ANNULER');
        await tester.tap(cancelOffer);
        await tester.pumpAndSettle();
        expect(find.text('Annuler cette proposition ?'), findsOneWidget);
        await tester.tap(find.text('NON'));
        await tester.pumpAndSettle();
        verifyNever(
          () => exchangeRepo.cancelOffer(
            basketExchange: any(named: 'basketExchange'),
            decidedAt: any(named: 'decidedAt'),
          ),
        );

        await tester.tap(cancelOffer);
        await tester.pumpAndSettle();
        await tester.tap(find.text('ANNULER LA PROPOSITION'));
        await tester.pumpAndSettle();
        verify(
          () => exchangeRepo.cancelOffer(
            basketExchange: any(named: 'basketExchange'),
            decidedAt: any(named: 'decidedAt'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'the history summary says a cancelled offer was cancelled, not just its '
      'date behind a pause icon',
      (tester) async {
        final org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
          deliveries: [
            Delivery(
              deliveryId: 'd-21',
              organizationId: 'org-1',
              scheduledDate: '${DateTime.now().year}-10-21T19:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 1,
            ),
          ],
        );
        const me = Member(
          memberId: 'sub-001',
          organizationId: 'org-1',
          firstName: 'Bob',
        );
        final exchange = BasketExchange(
          basketExchangeId: 'bx-1',
          organizationId: 'org-1',
          deliveryId: 'd-21',
          contractId: 'c-veg',
          offeringMemberId: 'sub-001',
          status: BasketExchangeStatus.cancelled,
          createdAt: '${DateTime.now().year}-01-02T12:00:00Z',
          decidedAt: '${DateTime.now().year}-01-03T12:00:00Z',
        );
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => Stream.value(me));
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([exchange]));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('— Annulé par moi'), findsOneWidget);
      },
    );

    testWidgets(
      'an accepted exchange whose baskets are still to come is counted as '
      'concluded, not as successful',
      (tester) async {
        const org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
        );
        const me = Member(
          memberId: 'sub-001',
          organizationId: 'org-1',
          firstName: 'Bob',
        );
        final exchange = BasketExchange(
          basketExchangeId: 'bx-1',
          organizationId: 'org-1',
          deliveryId: 'd-15',
          contractId: 'c-1',
          offeringMemberId: 'sub-001',
          status: BasketExchangeStatus.accepted,
          createdAt: '${DateTime.now().year}-01-02T12:00:00Z',
          decidedAt: '${DateTime.now().year}-01-03T12:00:00Z',
        );
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => Stream.value(me));
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => Stream.value([exchange]));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Échanges conclus cette année : 1'),
          findsOneWidget,
        );
        expect(find.textContaining('réussis'), findsNothing);
      },
    );

    testWidgets(
      'the request dialog recaps the date of the offered basket, not only '
      'the contract',
      (tester) async {
        const offeredDelivery = Delivery(
          deliveryId: 'd-15',
          organizationId: 'org-1',
          scheduledDate: '2026-10-15T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 1,
          contracts: [
            DeliveryContract(
              contractId: 'c-1',
              basketQuantity: 2,
              deliveryDescription: 'Oeufs automne',
              status: DeliveryContractStatus.pending,
            ),
          ],
        );
        const org = Organization(
          organizationId: 'org-1',
          name: 'Test AMAP',
          contactEmail: 'contact@test.com',
          deliveries: [offeredDelivery],
        );
        const me = Member(
          memberId: 'sub-001',
          organizationId: 'org-1',
          firstName: 'Bob',
        );
        const offer = BasketExchange(
          basketExchangeId: 'bx-1',
          organizationId: 'org-1',
          deliveryId: 'd-15',
          contractId: 'c-1',
          offeringMemberId: 'm-other',
          status: BasketExchangeStatus.open,
          createdAt: '2026-09-27T12:00:00Z',
        );
        when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(org));
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => Stream.value(me));
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => Stream.value(const [offer]));

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          exchangeRepo: exchangeRepo,
          contractRepo: contractRepo,
          authService: authService,
          syncBloc: syncBloc,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('DEMANDER ÉCHANGE'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text('📅 Jeudi 15 oct. • Oeufs automne'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}

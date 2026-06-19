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
        child: MaterialApp(home: BasketExchangeScreen(tenantId: tenantId)),
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
        final member = Member(
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
  });
}

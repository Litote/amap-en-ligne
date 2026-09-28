import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/member_dashboard_screen.dart';
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

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _FakeOrganization extends Fake implements Organization {}

class _FakeMember extends Fake implements Member {}

String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
}

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockMemberRepository memberRepo,
  required _MockDeliveryTemplateRepository templateRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
  required String tenantId,
}) async {
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
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(home: MemberDashboardScreen(tenantId: tenantId)),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockDeliveryTemplateRepository templateRepo;
  late _MockAuthService authService;
  late _MockSyncBloc syncBloc;
  late StreamController<Organization?> orgStream;
  late StreamController<Member?> memberStream;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(_FakeOrganization());
    registerFallbackValue(_FakeMember());
  });

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
        accessToken: _fakeToken('user-sub-1'),
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

  group('MemberDashboardScreen', () {
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

    testWidgets('shows "Synchronisation en cours..." when org stream is null', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        templateRepo: templateRepo,
        authService: authService,
        syncBloc: syncBloc,
        tenantId: 'org-1',
      );
      await tester.pump();

      // Emit null to simulate no row in DB; org has loaded (loading=false) but
      // is null → "Synchronisation en cours...".
      orgStream.add(null);
      await tester.pump();

      expect(find.text('Synchronisation en cours...'), findsOneWidget);
    });

    testWidgets(
      'shows "📋 Prochaines livraisons" section when org and member are loaded',
      (tester) async {
        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          tenantId: 'org-1',
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: []));
        memberStream.add(
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('📋 Prochaines livraisons'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Aucune livraison à venir." when no upcoming deliveries',
      (tester) async {
        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          tenantId: 'org-1',
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: []));
        memberStream.add(
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Aucune livraison à venir.'), findsOneWidget);
      },
    );

    testWidgets(
      'shows delivery date card when org has a future active delivery',
      (tester) async {
        final delivery = buildDelivery(
          scheduledDate: tomorrowIso(),
          status: DeliveryStatus.inProgress,
          contracts: [
            buildContract(slots: [buildSlot()]),
          ],
        );

        await _pump(
          tester,
          orgRepo: orgRepo,
          memberRepo: memberRepo,
          templateRepo: templateRepo,
          authService: authService,
          syncBloc: syncBloc,
          tenantId: 'org-1',
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('📋 Prochaines livraisons'), findsOneWidget);
        expect(find.text('Aucune livraison à venir.'), findsNothing);
      },
    );
  });
}

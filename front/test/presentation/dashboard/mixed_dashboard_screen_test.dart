import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/dashboard/mixed_dashboard_screen.dart';
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
import '../../support/organization_fixtures.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
}

Future<void> _pump(
  WidgetTester tester, {
  required MockAuthBloc authBloc,
  required MemberRepository memberRepo,
  required OrganizationRepository orgRepo,
  required DeliveryTemplateRepository templateRepo,
}) async {
  final authService = _MockAuthService();
  when(() => authService.currentState).thenReturn(
    AuthState.authenticated(
      producerId: 'prod-1',
      accessToken: _fakeToken('user-sub-1'),
      roles: ['VOLUNTEER'],
    ),
  );

  final syncBloc = _MockSyncBloc();
  whenListen(
    syncBloc,
    const Stream<SyncState>.empty(),
    initialState: const SyncState.idle(),
  );

  final basketExchangeRepo = _MockBasketExchangeRepository();
  when(
    () => basketExchangeRepo.watch(any()),
  ).thenAnswer((_) => Stream.value(const <BasketExchange>[]));

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: templateRepo,
        ),
        RepositoryProvider<BasketExchangeRepository>.value(
          value: basketExchangeRepo,
        ),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<SyncBloc>.value(value: syncBloc),
        ],
        child: const MaterialApp(home: MixedDashboardScreen(tenantId: 'org-1')),
      ),
    ),
  );
  await tester.pump();
}

void _stubAuth(MockAuthBloc bloc, Set<Role> roles) {
  when(() => bloc.state).thenReturn(AuthViewState(memberRoles: roles));
}

void main() {
  late MockAuthBloc authBloc;
  late StreamController<AuthViewState> authStream;
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;
  late _MockDeliveryTemplateRepository templateRepo;

  setUpAll(() async {
    registerAuthFallbackValues();
    await initializeDateFormatting('fr');
  });

  setUp(() {
    authStream = StreamController<AuthViewState>.broadcast();
    authBloc = MockAuthBloc();
    when(() => authBloc.stream).thenAnswer((_) => authStream.stream);
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    templateRepo = _MockDeliveryTemplateRepository();
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(buildOrg()));
    when(
      () => templateRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <DeliveryTemplate>[]));
  });

  tearDown(() async {
    await authStream.close();
  });

  group('MixedDashboardScreen', () {
    testWidgets('uses the generic "Tableau de bord" AppBar title', (
      tester,
    ) async {
      _stubAuth(authBloc, {Role.admin});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );

      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Admin · Tableau de bord'), findsNothing);
    });

    testWidgets('volunteer-only: no section headers, member sections present', (
      tester,
    ) async {
      // Provide a member so the volunteer section renders its content.
      when(() => memberRepo.watchMyMember(any())).thenAnswer(
        (_) => Stream.value(
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        ),
      );
      _stubAuth(authBloc, {Role.volunteer});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );
      // Allow the StatefulWidget streams to settle.
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('— Bénévole —'), findsNothing);
      expect(find.text('— Coordinateur —'), findsNothing);
      expect(find.text('— Admin —'), findsNothing);
      expect(find.text('📋 Prochaines livraisons'), findsOneWidget);
    });

    testWidgets(
      'coordinator-only: no section headers, NOUVEAU CRÉNEAU present',
      (tester) async {
        _stubAuth(authBloc, {Role.coordinator});
        await _pump(
          tester,
          authBloc: authBloc,
          memberRepo: memberRepo,
          orgRepo: orgRepo,
          templateRepo: templateRepo,
        );

        expect(find.text('— Coordinateur —'), findsNothing);
        expect(find.text('➕ NOUVEAU CRÉNEAU'), findsOneWidget);
      },
    );

    testWidgets('admin-only: no section headers, admin tiles present', (
      tester,
    ) async {
      _stubAuth(authBloc, {Role.admin});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );

      expect(find.text('— Admin —'), findsNothing);
      expect(find.text('Accès rapides'), findsOneWidget);
      expect(find.text('Utilisateurs'), findsOneWidget);
      expect(find.text('Synthèse'), findsOneWidget);
    });

    testWidgets(
      'coordinator + admin: both section headers and content stacked in order',
      (tester) async {
        _stubAuth(authBloc, {Role.coordinator, Role.admin});
        await _pump(
          tester,
          authBloc: authBloc,
          memberRepo: memberRepo,
          orgRepo: orgRepo,
          templateRepo: templateRepo,
        );

        expect(find.text('— Bénévole —'), findsNothing);
        expect(find.text('— Coordinateur —'), findsOneWidget);
        expect(find.text('— Admin —'), findsOneWidget);

        // Content from both sections is rendered.
        expect(find.text('➕ NOUVEAU CRÉNEAU'), findsOneWidget);
        expect(find.text('Accès rapides'), findsOneWidget);

        // Coordinator header appears above the admin header (privilege order).
        final coordinatorY = tester
            .getTopLeft(find.text('— Coordinateur —'))
            .dy;
        final adminY = tester.getTopLeft(find.text('— Admin —')).dy;
        expect(coordinatorY, lessThan(adminY));
      },
    );

    testWidgets('all three roles: three section headers in ascending order', (
      tester,
    ) async {
      // Provide a member so the volunteer section renders rather than showing a
      // loading spinner, which would push the section headers off-screen.
      when(() => memberRepo.watchMyMember(any())).thenAnswer(
        (_) => Stream.value(
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        ),
      );
      _stubAuth(authBloc, {Role.volunteer, Role.coordinator, Role.admin});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('— Bénévole —'), findsOneWidget);
      expect(find.text('— Coordinateur —'), findsOneWidget);
      expect(find.text('— Admin —'), findsOneWidget);

      final volunteerY = tester.getTopLeft(find.text('— Bénévole —')).dy;
      final coordinatorY = tester.getTopLeft(find.text('— Coordinateur —')).dy;
      final adminY = tester.getTopLeft(find.text('— Admin —')).dy;
      expect(volunteerY, lessThan(coordinatorY));
      expect(coordinatorY, lessThan(adminY));
    });

    testWidgets('empty roles: shell renders but no section content', (
      tester,
    ) async {
      _stubAuth(authBloc, const {});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );

      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Accès rapides'), findsNothing);
      expect(find.text('➕ NOUVEAU CRÉNEAU'), findsNothing);
      expect(find.text('Mon historique'), findsNothing);
    });

    testWidgets('aggregates stats from the watched member stream (admin)', (
      tester,
    ) async {
      when(() => memberRepo.watch('org-1')).thenAnswer(
        (_) => Stream.value([
          Member(
            memberId: 'm-1',
            organizationId: 'org-1',
            roles: const {Role.coordinator},
            activeStatus: true,
          ),
          Member(
            memberId: 'm-2',
            organizationId: 'org-1',
            roles: const {Role.volunteer},
            activeStatus: true,
          ),
        ]),
      );
      _stubAuth(authBloc, {Role.admin});
      await _pump(
        tester,
        authBloc: authBloc,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        templateRepo: templateRepo,
      );

      // Coordinator count line is rendered in the Synthèse card.
      expect(find.text('Coordinateurs'), findsOneWidget);
    });
  });
}

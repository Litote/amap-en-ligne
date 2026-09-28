import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/admin_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberJoinRequestRepository extends Mock
    implements MemberJoinRequestRepository {}

AdminMemberJoinRequest _joinRequest({
  String id = 'r-1',
  MemberJoinRequestStatus status = MemberJoinRequestStatus.pending,
}) => AdminMemberJoinRequest(
  requestId: id,
  organizationId: 'org-1',
  email: '$id@test.fr',
  firstName: 'Claude',
  lastName: 'Six',
  status: status,
  submittedAt: '2026-09-27T10:00:00Z',
);

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

Member _member({
  String id = 'm-1',
  Set<Role> roles = const {Role.volunteer},
  MemberAccountStatus accountStatus = MemberAccountStatus.active,
}) => Member(
  memberId: id,
  organizationId: 'org-1',
  roles: roles,
  accountStatus: accountStatus,
);

OrganizationProducer _producer({
  String id = 'p-1',
  OrganizationProducerStatus status = OrganizationProducerStatus.active,
}) => OrganizationProducer(
  producerAccountId: id,
  associationInstant: '2025-01-01T00:00:00Z',
  status: status,
);

Organization _org({List<OrganizationProducer> producers = const []}) =>
    Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      activeStatus: true,
      producers: producers,
    );

Future<void> _pump(
  WidgetTester tester, {
  required _MockMemberRepository memberRepo,
  required _MockOrganizationRepository orgRepo,
  _MockMemberJoinRequestRepository? joinRequestRepo,
  GoRouter? router,
}) async {
  final joinRequests = joinRequestRepo ?? _MockMemberJoinRequestRepository();
  if (joinRequestRepo == null) {
    when(
      () => joinRequests.watch(any()),
    ).thenAnswer((_) => Stream.value(const <AdminMemberJoinRequest>[]));
  }
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberJoinRequestRepository>.value(
          value: joinRequests,
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: router == null
            ? const MaterialApp(
                home: AdminDashboardScreen(organizationId: 'org-1'),
              )
            : MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;

  setUp(() {
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    when(
      () => memberRepo.watch('org-1'),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(() => orgRepo.watch('org-1')).thenAnswer((_) => Stream.value(null));
  });

  group('AdminDashboardScreen', () {
    testWidgets('renders all navigation tiles', (tester) async {
      await _pump(tester, memberRepo: memberRepo, orgRepo: orgRepo);

      expect(find.text('Utilisateurs'), findsOneWidget);
      expect(find.text('Producteurs'), findsOneWidget);
      expect(find.text('Modèles de livraison'), findsOneWidget);
      expect(find.text('Préférences'), findsOneWidget);
      expect(find.text("Demandes d'adhésion"), findsOneWidget);
    });

    testWidgets('renders the admin dashboard app bar title', (tester) async {
      await _pump(tester, memberRepo: memberRepo, orgRepo: orgRepo);

      expect(find.text('Admin · Tableau de bord'), findsOneWidget);
    });

    testWidgets('renders Alertes and Synthèse sections', (tester) async {
      await _pump(tester, memberRepo: memberRepo, orgRepo: orgRepo);

      expect(find.text('Alertes'), findsOneWidget);
      expect(find.text('Synthèse'), findsOneWidget);
    });

    testWidgets('shows "aucune alerte" when no suspended producers', (
      tester,
    ) async {
      when(
        () => orgRepo.watch('org-1'),
      ).thenAnswer((_) => Stream.value(_org()));
      await _pump(tester, memberRepo: memberRepo, orgRepo: orgRepo);

      expect(find.text('Aucune alerte en cours.'), findsOneWidget);
    });

    testWidgets('counts active members, coordinators and active producers', (
      tester,
    ) async {
      when(() => memberRepo.watch('org-1')).thenAnswer(
        (_) => Stream.value([
          _member(id: 'm-1', roles: {Role.volunteer}),
          _member(id: 'm-2', roles: {Role.coordinator}),
          _member(id: 'm-3', roles: {Role.coordinator, Role.volunteer}),
          _member(
            id: 'm-4',
            roles: {Role.volunteer},
            accountStatus: MemberAccountStatus.suspended,
          ),
        ]),
      );
      when(() => orgRepo.watch('org-1')).thenAnswer(
        (_) => Stream.value(
          _org(
            producers: [
              _producer(id: 'p-1'),
              _producer(id: 'p-2'),
              _producer(
                id: 'p-3',
                status: OrganizationProducerStatus.suspended,
              ),
              _producer(
                id: 'p-4',
                status: OrganizationProducerStatus.terminated,
              ),
            ],
          ),
        ),
      );

      await _pump(tester, memberRepo: memberRepo, orgRepo: orgRepo);

      // 3 active members (m-4 is inactive), 2 coordinators, 2 active
      // producers, 1 suspended producer.
      expect(
        find.descendant(of: find.byType(Row), matching: find.text('3')),
        findsOneWidget,
      );
      expect(find.text('1 producteur suspendu'), findsOneWidget);
    });

    testWidgets('alerts on pending member join requests', (tester) async {
      final joinRequestRepo = _MockMemberJoinRequestRepository();
      when(() => joinRequestRepo.watch('org-1')).thenAnswer(
        (_) => Stream.value([
          _joinRequest(id: 'r-1'),
          _joinRequest(id: 'r-2', status: MemberJoinRequestStatus.approved),
        ]),
      );

      await _pump(
        tester,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        joinRequestRepo: joinRequestRepo,
      );
      await tester.pump();

      expect(find.text("1 demande d'adhésion en attente"), findsOneWidget);
      expect(find.text('Aucune alerte en cours.'), findsNothing);
    });

    testWidgets('tapping the pending join requests alert opens them', (
      tester,
    ) async {
      final joinRequestRepo = _MockMemberJoinRequestRepository();
      when(
        () => joinRequestRepo.watch('org-1'),
      ).thenAnswer((_) => Stream.value([_joinRequest(id: 'r-1')]));
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) =>
                const AdminDashboardScreen(organizationId: 'org-1'),
          ),
          GoRoute(
            path: '/admin/membership-requests',
            builder: (_, _) => const Text('membership-requests'),
          ),
        ],
      );

      await _pump(
        tester,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        joinRequestRepo: joinRequestRepo,
        router: router,
      );
      await tester.pump();

      await tester.tap(find.text("1 demande d'adhésion en attente"));
      await tester.pumpAndSettle();

      expect(find.text('membership-requests'), findsOneWidget);
    });
  });
}

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
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
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

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
  bool active = true,
}) => Member(
  memberId: id,
  organizationId: 'org-1',
  roles: roles,
  activeStatus: active,
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
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: const MaterialApp(
          home: AdminDashboardScreen(organizationId: 'org-1'),
        ),
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
      expect(find.text('Templates de livraison'), findsOneWidget);
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
          _member(id: 'm-4', roles: {Role.volunteer}, active: false),
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
  });
}

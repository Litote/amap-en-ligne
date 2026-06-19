import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_auth_bloc.dart';

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Owner _owner({
  String id = 'o-1',
  String first = 'Alice',
  String last = 'Martin',
}) => Owner(
  ownerId: id,
  firstName: first,
  lastName: last,
  email: 'alice@exemple.fr',
  accountStatus: AccountStatus.active,
  registeredAt: '2025-01-01T00:00:00Z',
  updatedAt: '2025-01-01T00:00:00Z',
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  Set<Role> roles = const {Role.admin},
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  MemberAccountStatus? accountStatus,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: roles,
  firstName: firstName,
  lastName: lastName,
  email: email,
  phone: phone,
  accountStatus: accountStatus,
);

Organization _org({String id = 'org-1', String name = 'AMAP des Pins'}) =>
    Organization(
      organizationId: id,
      name: name,
      contactEmail: 'contact@org.fr',
    );

Future<void> _pump(
  WidgetTester tester, {
  required _MockOwnerRepository ownerRepo,
  required _MockMemberRepository memberRepo,
  required _MockOrganizationRepository orgRepo,
  required _MockProducerAccountRepository producerRepo,
  _MockSyncRepository? syncRepo,
  String? callerProducerAccountId,
  bool isAdmin = false,
}) async {
  final authBloc = MockAuthBloc();
  when(() => authBloc.state).thenReturn(
    AuthViewState(producerId: callerProducerAccountId, isAdmin: isAdmin),
  );
  when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());

  final effectiveSyncRepo = syncRepo ?? _MockSyncRepository();

  final widget = MultiRepositoryProvider(
    providers: [
      RepositoryProvider<OwnerRepository>.value(value: ownerRepo),
      RepositoryProvider<MemberRepository>.value(value: memberRepo),
      RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
      RepositoryProvider<ProducerAccountRepository>.value(value: producerRepo),
      RepositoryProvider<SyncRepository>.value(value: effectiveSyncRepo),
    ],
    child: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: const MaterialApp(home: UserListScreen()),
      ),
    ),
  );
  await tester.pumpWidget(widget);
  await tester.pump();
}

void main() {
  late _MockOwnerRepository ownerRepo;
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;
  late _MockProducerAccountRepository producerRepo;

  setUp(() {
    ownerRepo = _MockOwnerRepository();
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    producerRepo = _MockProducerAccountRepository();
    when(() => ownerRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => memberRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => orgRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => producerRepo.watchAll()).thenAnswer((_) => Stream.value([]));
  });

  group('UserListScreen — wireframe', () {
    testWidgets('renders title in app bar', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('Utilisateurs'), findsOneWidget);
    });

    testWidgets('renders header with total count', (tester) async {
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner()]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.textContaining("Utilisateurs de l'instance"), findsOneWidget);
      expect(find.text('1 utilisateur au total'), findsOneWidget);
    });

    testWidgets('renders Rechercher field', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('Rechercher'), findsOneWidget);
    });

    testWidgets('renders AMAP + Producteur dropdown filters', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('AMAP :'), findsOneWidget);
      expect(find.text('Producteur :'), findsOneWidget);
      expect(find.byKey(const Key('amap_filter_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('producer_filter_dropdown')), findsOneWidget);
    });

    testWidgets('renders Rôle filter chips', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('Rôle :'), findsOneWidget);
      // FilterChip labels for roles.
      expect(find.widgetWithText(FilterChip, 'Owner'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Admin'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Coordinateur'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Amapien'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Producteur'), findsOneWidget);
    });

    testWidgets('renders Statut filter chips', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('Statut :'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Actif'), findsOneWidget);
      expect(
        find.widgetWithText(FilterChip, 'Invitation en attente'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilterChip, 'Suspendu'), findsOneWidget);
    });

    testWidgets('renders EXPORTER LA LISTE button', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('EXPORTER LA LISTE'), findsOneWidget);
    });

    testWidgets('no longer renders the invite-owner button', (tester) async {
      // Invitation moved to dedicated screen at /owner/invite-administrator,
      // reached from the dashboard menu entry "Nouvel Administrateur".
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.text('+ INVITER UN OWNER'), findsNothing);
      expect(find.byKey(const Key('invite_owner_button')), findsNothing);
    });

    testWidgets('renders empty state when no users match', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(
        find.text('Aucun utilisateur ne correspond aux critères.'),
        findsOneWidget,
      );
    });

    testWidgets('renders member as ListTile with name, email, badges', (
      tester,
    ) async {
      when(() => ownerRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => memberRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _member(
            firstName: 'Alice',
            lastName: 'Martin',
            email: 'alice@exemple.fr',
            phone: '06 01 02 03 04',
            accountStatus: MemberAccountStatus.active,
          ),
        ]),
      );
      when(() => orgRepo.watchAll()).thenAnswer((_) => Stream.value([_org()]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      // Multiple pumps to let all 4 sub-streams emit and the bloc process them.
      await tester.pump();
      await tester.pump();

      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('alice@exemple.fr'), findsAtLeastNWidgets(1));
      // Status chip in ListTile subtitle.
      expect(find.text('Invitation en attente'), findsAtLeastNWidgets(1));
      expect(find.text('Admin'), findsAtLeastNWidgets(1));
    });

    testWidgets('list uses ListTile not Card', (tester) async {
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner()]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('list has chevron_right trailing icon', (tester) async {
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner()]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
    });
  });

  group('UserListScreen — disabled buttons', () {
    testWidgets('EXPORTER LA LISTE is disabled', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('export_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('EXPORTER LA LISTE has tooltip (Phase 8)', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('export_button')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'Phase 8');
    });
  });

  group('UserListScreen — tap opens dialog', () {
    testWidgets('tapping a user tile opens the detail dialog', (tester) async {
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner(id: 'o-1')]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      // Multiple pumps to let all sub-streams emit and the bloc process them.
      await tester.pump();
      await tester.pump();

      final tile = find.byKey(const Key('user_row_tile_o-1'));
      expect(tile, findsOneWidget);

      await tester.tap(tile);
      await tester.pump(); // start dialog build
      await tester.pump(); // settle bloc streams

      // Dialog is open — it shows a Dialog widget.
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('no navigation to /owner/users/:userId occurs', (tester) async {
      // The list screen should NOT push any route on tap — it opens a dialog.
      // We verify that no GoRouter route change happens by ensuring that the
      // screen stays at the same level (Dialog widget appears, no new page).
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner(id: 'o-1')]));

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      // Multiple pumps to let all sub-streams emit and the bloc process them.
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('user_row_tile_o-1')));
      await tester.pump();
      await tester.pump();

      // Still on the same screen — no MaterialPageRoute transition.
      expect(find.text('Utilisateurs'), findsOneWidget);
    });
  });

  group('UserListScreen — pagination footer', () {
    testWidgets('renders pagination footer with page info', (tester) async {
      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      expect(find.textContaining('Page'), findsOneWidget);
      expect(find.text('Précédent'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });
  });

  group('UserListScreen — filtered count', () {
    testWidgets('search updates the count label to the filtered result set', (
      tester,
    ) async {
      when(() => ownerRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _owner(first: 'Alice'),
          _owner(id: 'o-2', first: 'Bernard'),
        ]),
      );

      await _pump(
        tester,
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('user_search_field')),
        'Bernard',
      );
      await tester.pumpAndSettle();

      expect(find.text('1 utilisateur correspond aux filtres'), findsOneWidget);
    });
  });
}

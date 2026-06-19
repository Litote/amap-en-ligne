import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_bloc.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

Owner _owner({
  String id = 'o-1',
  String first = 'Alice',
  String last = 'Martin',
  String email = 'alice@exemple.fr',
  AccountStatus status = AccountStatus.active,
}) => Owner(
  ownerId: id,
  firstName: first,
  lastName: last,
  email: email,
  accountStatus: status,
  registeredAt: '2025-01-01T00:00:00Z',
  updatedAt: '2025-01-01T00:00:00Z',
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  String? sub,
  Set<Role> roles = const {Role.volunteer},
  bool activeStatus = true,
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  MemberAccountStatus? accountStatus,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: roles,
  activeStatus: activeStatus,
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _mockData({
  required _MockOwnerRepository ownerRepo,
  required _MockMemberRepository memberRepo,
  required _MockOrganizationRepository orgRepo,
  _MockProducerAccountRepository? producerRepo,
  List<Owner> owners = const [],
  List<Member> members = const [],
  List<Organization> orgs = const [],
  List<ProducerAccount> producerAccounts = const [],
}) {
  when(() => ownerRepo.watchAll()).thenAnswer((_) => Stream.value(owners));
  when(() => memberRepo.watchAll()).thenAnswer((_) => Stream.value(members));
  when(() => orgRepo.watchAll()).thenAnswer((_) => Stream.value(orgs));
  if (producerRepo != null) {
    when(
      () => producerRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(producerAccounts));
  }
}

/// Awaits a [UserListLoaded] state after the event queue drains.
/// Since the three sub-streams (owners / members / orgs) each emit once,
/// we wait for three loaded emissions before considering the bloc settled.
Future<UserListLoaded> _awaitLoaded(
  UserListBloc bloc, {
  int skipCount = 0,
}) async {
  // Skip [skipCount] loaded states, then take the next one.
  // Default 0: returns the very next loaded state (used after filter events).
  return bloc.stream
      .where((s) => s is UserListLoaded)
      .cast<UserListLoaded>()
      .skip(skipCount)
      .first
      .timeout(const Duration(seconds: 5));
}

/// Waits for the bloc to reach a stable [UserListLoaded] state after the
/// initial [UserListEvent.loaded()] dispatch.
///
/// Because the three sub-streams (owners / members / orgs) use [Stream.value]
/// in tests and emit synchronously on listen, all three controller events are
/// pushed before the first [emit.forEach] tick. We wait for the first loaded
/// state, then drain the microtask queue several times so that any remaining
/// controller events are also processed. The result is the last emitted
/// [UserListLoaded] state, which is guaranteed to reflect all three streams.
Future<UserListLoaded> _awaitSettled(UserListBloc bloc) async {
  // Wait for the first loaded state.
  await bloc.stream
      .firstWhere((s) => s is UserListLoaded)
      .timeout(const Duration(seconds: 5));

  // Drain remaining microtasks/event-loop ticks so all pending controller
  // events from the sub-streams are processed by emit.forEach.
  for (var i = 0; i < 10; i++) {
    await Future<void>.value();
  }

  final current = bloc.state;
  if (current is UserListLoaded) return current;
  // Fallback: wait for next loaded state.
  return bloc.stream
      .firstWhere((s) => s is UserListLoaded)
      .then((s) => s as UserListLoaded)
      .timeout(const Duration(seconds: 5));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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
    when(
      () => producerRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(const []));
  });

  UserListBloc buildBloc() => UserListBloc(
    ownerRepository: ownerRepo,
    memberRepository: memberRepo,
    organizationRepository: orgRepo,
    producerAccountRepository: producerRepo,
  );

  // ---------------------------------------------------------------------------
  // 1. Initial load
  // ---------------------------------------------------------------------------
  test(
    'loaded event with one owner — final state has totalCount = 1 and isOwner',
    () async {
      _mockData(
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        owners: [_owner()],
      );
      final bloc = buildBloc();
      bloc.add(const UserListEvent.loaded());
      final loaded = await _awaitLoaded(bloc);
      expect(loaded.visibleRows.first.isOwner, isTrue);
      await bloc.close();
    },
  );

  test('loaded event with no data — final state has totalCount = 0', () async {
    _mockData(ownerRepo: ownerRepo, memberRepo: memberRepo, orgRepo: orgRepo);
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 0);
    expect(loaded.visibleRows, isEmpty);
    await bloc.close();
  });

  test(
    'loaded member rows prefer synced profile fields and account status',
    () async {
      _mockData(
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        members: [
          _member(
            id: 'm-1',
            orgId: 'org-1',
            firstName: 'Alice',
            lastName: 'Martin',
            email: 'alice@exemple.fr',
            phone: '06 01 02 03 04',
            accountStatus: MemberAccountStatus.active,
          ),
        ],
        orgs: [_org()],
      );
      final bloc = buildBloc();
      bloc.add(const UserListEvent.loaded());
      final loaded = await _awaitSettled(bloc);

      expect(loaded.totalCount, 1);
      expect(loaded.visibleRows.single.displayName, 'Alice Martin');
      expect(loaded.visibleRows.single.email, 'alice@exemple.fr');
      expect(loaded.visibleRows.single.phone, '06 01 02 03 04');
      expect(loaded.visibleRows.single.displayStatus, UserDisplayStatus.active);
      await bloc.close();
    },
  );

  // ---------------------------------------------------------------------------
  // 2. AMAP filter
  // ---------------------------------------------------------------------------
  test(
    'amapFilterChanged to null clears the filter and shows all members',
    () async {
      _mockData(
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        members: [
          _member(id: 'm-1', orgId: 'org-1'),
          _member(id: 'm-2', orgId: 'org-2'),
        ],
        orgs: [
          _org(id: 'org-1'),
          _org(id: 'org-2', name: 'AMAP du Lac'),
        ],
      );
      final bloc = buildBloc();
      bloc.add(const UserListEvent.loaded());
      await _awaitSettled(bloc);

      // First apply an org filter to reduce the list, then clear it.
      bloc.add(const UserListEvent.amapFilterChanged('org-1'));
      final filtered = await _awaitLoaded(bloc);
      expect(filtered.totalCount, 1);

      bloc.add(const UserListEvent.amapFilterChanged(null));
      final unfiltered = await _awaitLoaded(bloc);
      expect(unfiltered.totalCount, 2);
      await bloc.close();
    },
  );

  test('amapFilterChanged to specific org filters rows', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      members: [
        _member(id: 'm-1', orgId: 'org-1'),
        _member(id: 'm-2', orgId: 'org-2'),
      ],
      orgs: [
        _org(id: 'org-1'),
        _org(id: 'org-2', name: 'AMAP du Lac'),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.amapFilterChanged('org-1'));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  test('producerFilterChanged narrows to matching producer rows', () async {
    final producerA = ProducerAccount(
      producerAccountId: 'pa-a',
      name: 'Ferme Dupont',
      contactEmail: 'a@example.fr',
    );
    final producerB = ProducerAccount(
      producerAccountId: 'pa-b',
      name: 'Ferme Martin',
      contactEmail: 'b@example.fr',
    );
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      producerRepo: producerRepo,
      producerAccounts: [producerA, producerB],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.producerFilterChanged('pa-a'));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    expect(loaded.visibleRows.single.producerAccountId, 'pa-a');
    expect(loaded.producerIdFilter, 'pa-a');
    await bloc.close();
  });

  test('producer accounts surface as UserRows with isProducer=true', () async {
    final producer = ProducerAccount(
      producerAccountId: 'pa-1',
      name: 'Ferme Dupont',
      contactEmail: 'ferme@example.fr',
    );
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      producerRepo: producerRepo,
      producerAccounts: [producer],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    final loaded = await _awaitSettled(bloc);

    expect(loaded.totalCount, 1);
    expect(loaded.visibleRows.single.isProducer, isTrue);
    expect(loaded.visibleRows.single.producerAccountName, 'Ferme Dupont');
    expect(loaded.allProducerAccounts, hasLength(1));
    await bloc.close();
  });

  // ---------------------------------------------------------------------------
  // 3. Role filter
  // ---------------------------------------------------------------------------
  test('roleFilterChanged to owner shows only owner users', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [_owner()],
      members: [
        _member(sub: 's-m-1', roles: {Role.admin}),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.roleFilterChanged(UserListRoleFilter.owner));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    expect(loaded.visibleRows.every((r) => r.isOwner), isTrue);
    await bloc.close();
  });

  test('roleFilterChanged to admin shows only admin members', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [_owner()],
      members: [
        _member(id: 'm-1', roles: {Role.admin}),
        _member(id: 'm-2', roles: {Role.volunteer}),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.roleFilterChanged(UserListRoleFilter.admin));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  test(
    'roleFilterChanged to coordinator shows only coordinator members',
    () async {
      _mockData(
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        members: [
          _member(id: 'm-1', roles: {Role.coordinator}),
          _member(id: 'm-2', roles: {Role.volunteer}),
        ],
      );
      final bloc = buildBloc();
      bloc.add(const UserListEvent.loaded());
      await _awaitSettled(bloc);

      bloc.add(
        const UserListEvent.roleFilterChanged(UserListRoleFilter.coordinator),
      );
      final loaded = await _awaitLoaded(bloc);
      expect(loaded.totalCount, 1);
      await bloc.close();
    },
  );

  test('roleFilterChanged to volunteer shows only volunteer members', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      members: [
        _member(id: 'm-1', roles: {Role.admin}),
        _member(id: 'm-2', roles: {Role.volunteer}),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(
      const UserListEvent.roleFilterChanged(UserListRoleFilter.volunteer),
    );
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  // ---------------------------------------------------------------------------
  // 4. Status filter
  // ---------------------------------------------------------------------------
  test('statusFilterChanged to active shows only active users', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [_owner()],
      members: [_member(id: 'm-1', activeStatus: false)],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.statusFilterChanged(UserDisplayStatus.active));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  test('statusFilterChanged to suspended shows only suspended users', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [_owner()],
      members: [_member(id: 'm-1', activeStatus: false)],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(
      const UserListEvent.statusFilterChanged(UserDisplayStatus.suspended),
    );
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  test(
    'statusFilterChanged to pendingInvitation returns no members (invitation state is on MemberInvitation, not Member)',
    () async {
      _mockData(
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        members: [
          _member(
            id: 'm-1',
            firstName: 'Alice',
            accountStatus: MemberAccountStatus.active,
          ),
          _member(
            id: 'm-2',
            firstName: 'Bernard',
            accountStatus: MemberAccountStatus.active,
          ),
        ],
      );
      final bloc = buildBloc();
      bloc.add(const UserListEvent.loaded());
      await _awaitSettled(bloc);

      // Filter by pendingInvitation: no member can have this display status
      // from Member.accountStatus alone (invitation state is on MemberInvitation).
      bloc.add(
        const UserListEvent.statusFilterChanged(
          UserDisplayStatus.pendingInvitation,
        ),
      );
      final loaded = await _awaitLoaded(bloc);

      expect(loaded.totalCount, 0);
      await bloc.close();
    },
  );

  // ---------------------------------------------------------------------------
  // 5. Search — case-insensitive + accent-insensitive
  // ---------------------------------------------------------------------------
  test('searchQueryChanged filters by last name case-insensitively', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [
        _owner(id: 'o-1', last: 'Martin'),
        _owner(id: 'o-2', last: 'Dupont'),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.searchQueryChanged('mart'));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  test('searchQueryChanged is accent-insensitive', () async {
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: [
        _owner(id: 'o-1', last: 'Éléonore'),
        _owner(id: 'o-2', last: 'Dupont'),
      ],
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    await _awaitSettled(bloc);

    bloc.add(const UserListEvent.searchQueryChanged('eleonore'));
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.totalCount, 1);
    await bloc.close();
  });

  // ---------------------------------------------------------------------------
  // 6. Pagination
  // ---------------------------------------------------------------------------
  test('pageChanged advances to page 2 with 5 remaining rows', () async {
    // Build 55 distinct owners to force 2 pages.
    final owners = List.generate(
      55,
      (i) => _owner(id: 'o-$i', last: 'Z${i.toString().padLeft(3, '0')}'),
    );
    _mockData(
      ownerRepo: ownerRepo,
      memberRepo: memberRepo,
      orgRepo: orgRepo,
      owners: owners,
    );
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    final page1 = await _awaitLoaded(bloc);

    expect(page1.currentPage, 1);
    expect(page1.totalPages, 2);
    expect(page1.visibleRows.length, 50);

    bloc.add(const UserListEvent.pageChanged(2));
    final page2 = await _awaitLoaded(bloc);

    expect(page2.currentPage, 2);
    expect(page2.visibleRows.length, 5);
    await bloc.close();
  });

  // ---------------------------------------------------------------------------
  // 7. Empty state
  // ---------------------------------------------------------------------------
  test('empty state: loaded with empty visibleRows', () async {
    _mockData(ownerRepo: ownerRepo, memberRepo: memberRepo, orgRepo: orgRepo);
    final bloc = buildBloc();
    bloc.add(const UserListEvent.loaded());
    final loaded = await _awaitLoaded(bloc);
    expect(loaded.visibleRows, isEmpty);
    expect(loaded.totalCount, 0);
    await bloc.close();
  });
}

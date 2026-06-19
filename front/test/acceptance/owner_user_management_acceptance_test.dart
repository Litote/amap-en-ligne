@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_bloc.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Scripted SyncApi — follows the same pattern as sync_acceptance_test.dart.
// Extends SyncApi (concrete class) and overrides sync() so the repository
// gets a pre-scripted response without a real HTTP call.
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(this._responses) : super(Dio());

  final List<SyncResponse> _responses;
  int _idx = 0;

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    if (_idx >= _responses.length) {
      throw StateError('Unexpected sync call #$_idx');
    }
    return _responses[_idx++];
  }

  void assertDrained() {
    expect(
      _idx,
      _responses.length,
      reason: 'Expected exactly ${_responses.length} sync calls, got $_idx',
    );
  }
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

Owner _owner({
  required String id,
  required String first,
  required String last,
  String email = 'owner@exemple.fr',
}) => Owner(
  ownerId: id,
  firstName: first,
  lastName: last,
  email: email,
  accountStatus: AccountStatus.active,
  registeredAt: '2025-01-01T00:00:00Z',
  updatedAt: '2025-01-01T00:00:00Z',
);

Organization _org({required String id, required String name}) => Organization(
  organizationId: id,
  name: name,
  contactEmail: 'contact@$id.fr',
);

Member _member({
  required String id,
  required String orgId,
  Set<Role> roles = const {Role.volunteer},
}) => Member(memberId: id, organizationId: orgId, roles: roles);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late SyncRepository syncRepo;
  late OwnerRepository ownerRepo;
  late MemberRepository memberRepo;
  late OrganizationRepository orgRepo;
  late ProducerAccountRepository producerRepo;

  // Three owners + five members across two AMAPs.
  final bootstrapOwners = [
    _owner(id: 'o-1', first: 'Alice', last: 'Martin'),
    _owner(id: 'o-2', first: 'Bernard', last: 'Leroy'),
    _owner(id: 'o-3', first: 'Camille', last: 'Dupont'),
  ];

  final bootstrapOrgs = [
    _org(id: 'org-1', name: 'AMAP des Pins'),
    _org(id: 'org-2', name: 'AMAP du Lac'),
  ];

  final bootstrapMembers = [
    _member(id: 'm-1', orgId: 'org-1', roles: {Role.admin}),
    _member(id: 'm-2', orgId: 'org-1'),
    _member(id: 'm-3', orgId: 'org-2'),
    // m-4 is also in org-1 with admin + coordinator roles.
    _member(id: 'm-4', orgId: 'org-1', roles: {Role.admin, Role.coordinator}),
    _member(id: 'm-5', orgId: 'org-2'),
  ];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ownerRepo = OwnerRepository(db: db);
    memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
    orgRepo = OrganizationRepository(db: db, idGenerator: IdGenerator());
    producerRepo = ProducerAccountRepository(db: db);
    final api = _ScriptedSyncApi([
      SyncResponse(
        authorizedScopes: const [
          'instance-owner',
          'organization:org-1',
          'organization:org-2',
        ],
        results: {
          'instance-owner': BootstrapScopeSyncResult(
            items: bootstrapOwners.map((o) => OwnerPayload(owner: o)).toList(),
            nextCursor: 'c-owner-1',
          ),
          'organization:org-1': BootstrapScopeSyncResult(
            items: <EntityPayload>[
              OrganizationPayload(organization: bootstrapOrgs[0]),
              ...bootstrapMembers
                  .where((member) => member.organizationId == 'org-1')
                  .map((member) => MemberPayload(member: member)),
            ],
            nextCursor: 'c-org-1',
          ),
          'organization:org-2': BootstrapScopeSyncResult(
            items: bootstrapOrgs
                .where((org) => org.organizationId == 'org-2')
                .map<EntityPayload>(
                  (org) => OrganizationPayload(organization: org),
                )
                .followedBy(
                  bootstrapMembers
                      .where((member) => member.organizationId == 'org-2')
                      .map<EntityPayload>(
                        (member) => MemberPayload(member: member),
                      ),
                )
                .toList(),
            nextCursor: 'c-org-2',
          ),
        },
      ),
    ]);
    syncRepo = SyncRepository(db: db, api: api);
  });

  tearDown(() async {
    await db.close();
  });

  test('GIVEN OWNER connected with 3 owners + 5 members across 2 AMAPs, '
      'WHEN bootstrap sync runs, '
      'THEN user list shows all 8 users (owners + members-by-sub)', () async {
    await syncRepo.sync(tenantId: 'owner-tenant');

    // All three owners must be in the owners table.
    final owners = await ownerRepo.watchAll().first;
    expect(owners, hasLength(3));

    // Build the list bloc and trigger load.
    final bloc = UserListBloc(
      ownerRepository: ownerRepo,
      memberRepository: memberRepo,
      organizationRepository: orgRepo,
      producerAccountRepository: producerRepo,
    );
    bloc.add(const UserListEvent.loaded());

    // Wait for the first loaded state, then drain the event loop so that
    // all three sub-streams (owners / members / orgs) have been processed.
    await bloc.stream
        .where((s) => s is UserListLoaded)
        .first
        .timeout(const Duration(seconds: 5));

    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }

    final loadedState = bloc.state as UserListLoaded;

    // 3 owners (distinct subs) + 5 distinct member subs = 8 total.
    expect(loadedState.totalCount, 8);
    expect(
      loadedState.allOrganizations,
      hasLength(2),
      reason: 'two organisations should be loaded',
    );

    await bloc.close();
  });

  test(
    'WHEN filtering by role ADMIN, '
    'THEN only the two admin members are shown (m-1 sub and m-4 sub)',
    () async {
      await syncRepo.sync(tenantId: 'owner-tenant');

      final bloc = UserListBloc(
        ownerRepository: ownerRepo,
        memberRepository: memberRepo,
        organizationRepository: orgRepo,
        producerAccountRepository: producerRepo,
      );
      bloc.add(const UserListEvent.loaded());

      // Wait for initial loaded state with all rows.
      await bloc.stream
          .where((s) => s is UserListLoaded)
          .first
          .timeout(const Duration(seconds: 5));

      // Drain event loop so all three sub-streams have been processed.
      for (var i = 0; i < 10; i++) {
        await Future<void>.value();
      }

      // Apply role filter.
      bloc.add(const UserListEvent.roleFilterChanged(UserListRoleFilter.admin));

      final filteredState =
          await bloc.stream
                  .where((s) => s is UserListLoaded)
                  .first
                  .timeout(const Duration(seconds: 5))
              as UserListLoaded;

      expect(filteredState.totalCount, 2);
      expect(
        filteredState.visibleRows.every(
          (r) => r.memberships.any((m) => m.roles.contains(Role.admin)),
        ),
        isTrue,
      );

      await bloc.close();
    },
  );

  test(
    'WHEN tapping Voir → on a member, '
    'THEN the ownerId in the row matches the memberId used for navigation',
    () async {
      await syncRepo.sync(tenantId: 'owner-tenant');

      final bloc = UserListBloc(
        ownerRepository: ownerRepo,
        memberRepository: memberRepo,
        organizationRepository: orgRepo,
        producerAccountRepository: producerRepo,
      );
      bloc.add(const UserListEvent.loaded());

      // Wait for the first loaded state then drain so all sub-streams settle.
      await bloc.stream
          .where((s) => s is UserListLoaded)
          .first
          .timeout(const Duration(seconds: 5));

      for (var i = 0; i < 10; i++) {
        await Future<void>.value();
      }

      final loadedState = bloc.state as UserListLoaded;

      // Find a member-only row (not isOwner) and verify ownerId matches a memberId.
      final memberRow = loadedState.visibleRows.firstWhere((r) => !r.isOwner);
      final memberIds = bootstrapMembers.map((m) => m.memberId).toList();
      expect(memberIds, contains(memberRow.ownerId));

      await bloc.close();
    },
  );
}

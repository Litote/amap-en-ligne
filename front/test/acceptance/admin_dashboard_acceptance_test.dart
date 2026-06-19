@Tags(['acceptance'])
library;

// Acceptance test for the Bug #2 fix: admin users have no custom:producer_account_id
// (or app_metadata.producer_account_id) in their JWT — only custom:organization_id
// (or app_metadata.organization_id).  Before the fix the auth service fell back to
// `sub`, so `producerAccountId` became the raw Cognito/GoTrue UUID.  The sync used
// that UUID as its tenant key, meaning memberRepository.watch(UUID) always returned
// an empty list even though the AMAP had members.
//
// After the fix: auth service reads organization_id as the intermediate fallback so
// producerAccountId = 'amap-dev'.  Sync runs with tenantId = 'amap-dev', stores
// members under 'organization:amap-dev', and memberRepository.watch('amap-dev')
// returns all members — the dashboard can then show the correct active-member count.

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Scripted SyncApi — same pattern as other acceptance tests.
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(this._response) : super(Dio());

  final SyncResponse _response;
  bool _called = false;

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    _called = true;
    return _response;
  }

  void assertCalled() {
    expect(_called, isTrue, reason: 'Expected one sync call but none occurred');
  }
}

// ---------------------------------------------------------------------------
// Dev-seed fixtures — mirrors what back/deploy/jvm/dev-init.sh seeds:
// 4 members in org 'amap-dev' all with active_status = true.
// ---------------------------------------------------------------------------

const _orgId = 'amap-dev';

final _seededMembers = [
  Member(
    memberId: 'member-admin-dev',
    organizationId: _orgId,
    roles: {Role.admin},
    activeStatus: true,
  ),
  Member(
    memberId: 'member-coordinator-dev',
    organizationId: _orgId,
    roles: {Role.coordinator},
    activeStatus: true,
  ),
  Member(
    memberId: 'member-volunteer-dev',
    organizationId: _orgId,
    roles: {Role.volunteer},
    activeStatus: true,
  ),
  Member(
    memberId: 'member-producer-dev',
    organizationId: _orgId,
    roles: {Role.producer},
    activeStatus: true,
  ),
];

final _seededOrg = Organization(
  organizationId: _orgId,
  name: 'AMAP Dev',
  contactEmail: 'contact@amap-dev.fr',
);

SyncResponse _bootstrapResponse() => SyncResponse(
  authorizedScopes: const ['organization:$_orgId'],
  results: {
    'organization:$_orgId': BootstrapScopeSyncResult(
      items: [
        OrganizationPayload(organization: _seededOrg),
        ..._seededMembers.map((m) => MemberPayload(member: m)),
      ],
      nextCursor: 'c-amap-dev-1',
    ),
  },
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late MemberRepository memberRepo;
  late OrganizationRepository orgRepo;
  late SyncRepository syncRepo;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
    orgRepo = OrganizationRepository(db: db, idGenerator: IdGenerator());
    api = _ScriptedSyncApi(_bootstrapResponse());
    syncRepo = SyncRepository(db: db, api: api);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'GIVEN admin user with organization_id = amap-dev (no producer_account_id), '
    'WHEN bootstrap sync runs with tenantId = amap-dev, '
    'THEN memberRepository.watch(amap-dev) returns the 4 seeded members',
    () async {
      // tenantId is what CognitoAuthService/GoTrueAuthService puts in
      // AuthState.authenticated.producerId.  After the Bug #2 fix,
      // an admin user (no producer_account_id in JWT) gets their organization_id
      // ('amap-dev') instead of their sub UUID.
      final outcome = await syncRepo.sync(tenantId: _orgId);

      api.assertCalled();
      expect(outcome, isA<SyncSuccess>());

      final members = await memberRepo.watch(_orgId).first;
      expect(
        members,
        hasLength(4),
        reason:
            'all 4 dev-seeded members must be visible via watch(amap-dev); '
            'if producerAccountId were the sub UUID instead, this would return 0',
      );
    },
  );

  test('GIVEN admin user with organization_id = amap-dev, '
      'WHEN bootstrap sync runs, '
      'THEN all seeded members have activeStatus = true '
      '(dashboard should show 4 membres actifs, not 0)', () async {
    await syncRepo.sync(tenantId: _orgId);

    final members = await memberRepo.watch(_orgId).first;

    expect(
      members.every((m) => m.activeStatus),
      isTrue,
      reason:
          'dev-seeded members all have active_status = true; '
          'dashboard _DashboardStats.from counts via m.activeStatus',
    );
    expect(
      members.length,
      4,
      reason: 'dashboard Synthèse card should show "4 membres actifs"',
    );
  });

  test('GIVEN admin user whose JWT sub is a UUID (not the orgId), '
      'WHEN sync is done and the organization:amap-dev cursor is stored, '
      'THEN watch(subUuid) returns members via cursor fallback', () async {
    await syncRepo.sync(tenantId: _orgId);

    // In production, AuthState.producerAccountId = sub (JWT), not the org id.
    // watchMembersForTenant resolves the real org id from the stored
    // organization:* cursor, so watch(sub) returns the same members as
    // watch(orgId).
    const subUuid = 'some-random-sub-uuid-from-cognito';
    final membersViaSub = await memberRepo.watch(subUuid).first;
    expect(
      membersViaSub,
      hasLength(4),
      reason:
          'cursor fallback resolves organization:amap-dev regardless of '
          'the tenantId passed; this is the fix for the empty-dashboard bug',
    );
  });

  test(
    'GIVEN admin user after sync, '
    'WHEN organizationRepository.watch(amap-dev) is called, '
    'THEN the organization is found (not "Organisation introuvable.")',
    () async {
      await syncRepo.sync(tenantId: _orgId);

      final org = await orgRepo.watch(_orgId).first;
      expect(
        org,
        isNotNull,
        reason:
            'before Bug #2 fix, organizationRepository.watch(subUUID) returned null '
            'causing the "Organisation introuvable." error on admin pages',
      );
      expect(org!.organizationId, _orgId);
    },
  );
}

@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tenant = 'org-1';
  const memberId = 'm-1';

  final roleChangeStory = _loadStory('member-role-change');
  final lastAdminStory = _loadStory('member-role-last-admin-rejected');

  late AppDatabase db;
  late SyncRepository syncRepo;
  late _ScriptedSyncApi api;

  Member member({Set<Role> roles = const {Role.coordinator}}) =>
      Member(memberId: memberId, organizationId: tenant, roles: roles);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  test(
    'member with roles is received during bootstrap and stored in drift',
    () async {
      api = _ScriptedSyncApi([
        _ExpectedSyncCall.response(
          label: 'bootstrap-member-roles',
          request: const SyncRequest(),
          response: SyncResponse(
            authorizedScopes: const ['organization:org-1'],
            results: {
              'organization:org-1': BootstrapScopeSyncResult(
                items: [
                  MemberPayload(
                    member: member(roles: {Role.coordinator, Role.admin}),
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        ),
      ]);
      syncRepo = SyncRepository(db: db, api: api);

      final outcome = await syncRepo.sync(tenantId: tenant);

      expect(outcome, isA<SyncSuccess>());
      final members = await db.watchMembers(tenant).first;
      expect(members, hasLength(1));
      expect(members.single.roles, containsAll([Role.coordinator, Role.admin]));
      expect(await db.readPendingMutations(), isEmpty);
    },
  );

  test('${roleChangeStory.title} [${roleChangeStory.id}]', () async {
    final memberRepo = MemberRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['op-1']),
    );
    syncRepo = SyncRepository(db: db, api: api = _ScriptedSyncApi([]));

    // Pre-populate drift with the initial member state and a known cursor.
    final initialMember = member(roles: {Role.coordinator});
    await db.upsertMember(tenant, initialMember);
    await db.writeCursor('organization:org-1', 'c1');

    // Apply an optimistic role update, enqueuing the mutation.
    await memberRepo.setRoles(tenant, initialMember, {
      Role.coordinator,
      Role.admin,
    });
    final pending = await db.readPendingMutations();

    api.enqueue(
      _ExpectedSyncCall.response(
        label: roleChangeStory.id,
        request: SyncRequest(
          cursors: const {'organization:org-1': 'c1'},
          mutations: pending,
        ),
        response: const SyncResponse(
          authorizedScopes: ['organization:org-1'],
          mutations: [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.applied,
              serverEntityId: memberId,
            ),
          ],
        ),
      ),
    );

    final outcome = await syncRepo.sync(tenantId: tenant);

    expect(outcome, isA<SyncSuccess>());
    final members = await db.watchMembers(tenant).first;
    expect(members, hasLength(1));
    expect(members.single.roles, containsAll([Role.coordinator, Role.admin]));
    expect(await db.readPendingMutations(), isEmpty);
  });

  test('${lastAdminStory.title} [${lastAdminStory.id}]', () async {
    final memberRepo = MemberRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['op-1']),
    );
    syncRepo = SyncRepository(db: db, api: api = _ScriptedSyncApi([]));

    // Pre-populate drift with the initial member state and a known cursor.
    final initialMember = member(roles: {Role.admin});
    await db.upsertMember(tenant, initialMember);
    await db.writeCursor('organization:org-1', 'c1');

    // Optimistically remove the admin role (leaving only coordinator).
    await memberRepo.setRoles(tenant, initialMember, {Role.coordinator});
    final pending = await db.readPendingMutations();

    api.enqueue(
      _ExpectedSyncCall.response(
        label: lastAdminStory.id,
        request: SyncRequest(
          cursors: const {'organization:org-1': 'c1'},
          mutations: pending,
        ),
        response: const SyncResponse(
          authorizedScopes: ['organization:org-1'],
          mutations: [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.rejected,
            ),
          ],
        ),
      ),
    );

    final outcome = await syncRepo.sync(tenantId: tenant);

    expect(outcome, isA<SyncSuccess>());
    final rejected = (outcome as SyncSuccess).rejectedMutations;
    expect(rejected.map((m) => m.clientOpId), contains('op-1'));
    expect(await db.readPendingMutations(), isEmpty);
  });
}

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(Iterable<_ExpectedSyncCall> calls)
    : _calls = Queue.of(calls),
      super(Dio());

  final Queue<_ExpectedSyncCall> _calls;

  void enqueue(_ExpectedSyncCall call) => _calls.add(call);

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls remain.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    expect(_calls, isNotEmpty, reason: 'Unexpected sync request: $request');
    final call = _calls.removeFirst();
    expect(
      request,
      call.request,
      reason: 'Unexpected sync request for ${call.label}',
    );
    if (call.error != null) throw call.error!;
    return call.response!;
  }
}

class _ExpectedSyncCall {
  _ExpectedSyncCall.response({
    required this.label,
    required this.request,
    required this.response,
  }) : error = null;

  final String label;
  final SyncRequest request;
  final SyncResponse? response;
  final Object? error;
}

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(Iterable<String> ids) : _ids = Queue.of(ids);

  final Queue<String> _ids;

  @override
  String next() {
    if (_ids.isEmpty) {
      throw StateError('No ids left in _SequenceIdGenerator.');
    }
    return _ids.removeFirst();
  }
}

class _AcceptanceStory {
  const _AcceptanceStory({required this.id, required this.title});

  final String id;
  final String title;
}

_AcceptanceStory _loadStory(String id) {
  final uri = Directory.current.uri.resolve('../acceptance/scenarios/$id.json');
  final content = File.fromUri(uri).readAsStringSync();
  final json = jsonDecode(content) as Map<String, Object?>;
  return _AcceptanceStory(
    id: json['id']! as String,
    title: json['title']! as String,
  );
}

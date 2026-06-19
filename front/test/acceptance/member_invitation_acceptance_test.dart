@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const orgId = 'org-1';
  const orgScope = 'organization:org-1';
  const realInvitationId = 'inv-real-1';

  final story = _loadStory('admin-invite-member-no-double-sync');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Regression: inviting a member must trigger exactly one HTTP sync even when
  // UserManagementBloc and SyncBloc both call sync() concurrently.
  // Without the fix in SyncRepository, the scripted API would receive a second
  // unexpected call and the test would fail here (proving the bug).
  // ---------------------------------------------------------------------------
  test('${story.title} [${story.id}]', () async {
    // next() → 'op-invite' (clientOpId); nextTmpId() → 'tmp_inv' (invitationId).
    final idGen = _SequenceIdGenerator(['op-invite', 'inv']);
    final invitationRepo = MemberInvitationRepository(
      db: db,
      idGenerator: idGen,
    );

    await db.writeCursor(orgScope, 'c0');

    // Enqueue the invitation mutation (mirrors what UserManagementBloc does
    // before triggering sync).
    final clientOpId = await invitationRepo.create(
      organizationId: orgId,
      email: 'alice@example.org',
      firstName: 'Alice',
      lastName: 'Martin',
      roles: const {Role.volunteer},
    );
    expect(clientOpId, 'op-invite');

    // The invitation must be in the local cache before sync.
    final localInvitations = await db.getMemberInvitationsForOrganization(
      orgId,
    );
    expect(localInvitations, hasLength(1));
    expect(localInvitations.first.email, 'alice@example.org');

    // A single pending mutation must be enqueued.
    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    // Scripted API: only ONE sync call expected.
    // If SyncRepository does not deduplicate, the second concurrent call would
    // dequeue from an empty queue and trigger a test failure — proving the bug.
    api = _ScriptedSyncApi([
      _ExpectedSyncCall(
        label: story.id,
        request: SyncRequest(
          cursors: const {orgScope: 'c0'},
          mutations: pending,
        ),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(
              changes: const [],
              nextCursor: 'c1',
            ),
          },
          mutations: [
            MutationOutcome(
              clientOpId: clientOpId,
              status: MutationStatus.applied,
              serverEntityId: realInvitationId,
            ),
          ],
        ),
      ),
    ]);

    final syncRepo = SyncRepository(db: db, api: api);

    // Simulate the race: UserManagementBloc and SyncBloc both call sync()
    // concurrently (as happens in production after MemberInvitationRepository.create).
    final results = await Future.wait([
      syncRepo.sync(tenantId: orgId),
      syncRepo.sync(tenantId: orgId),
    ]);

    // Both callers must receive a successful outcome.
    expect(results[0], isA<SyncSuccess>());
    expect(results[1], isA<SyncSuccess>());

    // The mutation must be drained (processed exactly once).
    expect(await db.readPendingMutations(), isEmpty);

    // The tmp id must have been remapped to the server-allocated id.
    final syncedInvitations = await db.getMemberInvitationsForOrganization(
      orgId,
    );
    expect(syncedInvitations, hasLength(1));
    expect(syncedInvitations.first.invitationId, realInvitationId);

    // Cursor must be advanced.
    expect(await db.readCursor(orgScope), 'c1');
  });
}

// ---------------------------------------------------------------------------
// Scenario story loader
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Scripted SyncApi — fails fast if an unexpected (second) call arrives
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(Iterable<_ExpectedSyncCall> calls)
    : _calls = Queue.of(calls),
      super(Dio());

  final Queue<_ExpectedSyncCall> _calls;

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls remain.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    expect(
      _calls,
      isNotEmpty,
      reason: 'Unexpected (duplicate) sync request: $request',
    );
    final call = _calls.removeFirst();
    expect(
      request,
      call.request,
      reason: 'Unexpected sync request for ${call.label}',
    );
    return call.response;
  }
}

class _ExpectedSyncCall {
  const _ExpectedSyncCall({
    required this.label,
    required this.request,
    required this.response,
  });

  final String label;
  final SyncRequest request;
  final SyncResponse response;
}

// ---------------------------------------------------------------------------
// Deterministic ID generator
// ---------------------------------------------------------------------------

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(Iterable<String> ids) : _ids = Queue.of(ids);

  final Queue<String> _ids;

  @override
  String next() {
    if (_ids.isEmpty) throw StateError('No ids left in _SequenceIdGenerator.');
    return _ids.removeFirst();
  }
}

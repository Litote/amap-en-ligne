import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AdminMemberJoinRequest _buildRequest({
  String requestId = 'req-1',
  String organizationId = 'org-1',
  MemberJoinRequestStatus status = MemberJoinRequestStatus.pending,
}) => AdminMemberJoinRequest(
  requestId: requestId,
  organizationId: organizationId,
  email: 'alice@example.org',
  firstName: 'Alice',
  lastName: 'Martin',
  status: status,
  submittedAt: '2026-05-07T10:00:00Z',
);

void main() {
  late AppDatabase db;
  late MemberJoinRequestRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemberJoinRequestRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('watch() emits from Drift stream', () async {
    final pending = _buildRequest();
    await db.upsertMemberJoinRequest(pending);

    final rows = await repo.watch('org-1').first;
    expect(rows.single.requestId, 'req-1');
  });

  test(
    'approve() enqueues Upsert mutation without changing the local cache',
    () async {
      final pending = _buildRequest();
      await db.upsertMemberJoinRequest(pending);

      await repo.approve(pending);

      final rows = await db.watchMemberJoinRequests('org-1').first;
      expect(rows.single.status, MemberJoinRequestStatus.pending);

      final mutations = await db.readPendingMutations();
      final upsert = mutations.single.op as Upsert;
      final request =
          (upsert.payload as MemberJoinRequestPayload).memberJoinRequest;
      expect(request.status, MemberJoinRequestStatus.approved);
      expect(request.reviewedAt, isNotNull);

      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey('org-1'));
    },
  );

  test('reject() enqueues review comment in Upsert mutation', () async {
    final pending = _buildRequest();
    await db.upsertMemberJoinRequest(pending);

    await repo.reject(pending, reviewComment: 'Dossier incomplet');

    final mutations = await db.readPendingMutations();
    final upsert = mutations.single.op as Upsert;
    final request =
        (upsert.payload as MemberJoinRequestPayload).memberJoinRequest;
    expect(request.status, MemberJoinRequestStatus.rejected);
    expect(request.reviewComment, 'Dossier incomplet');
  });

  test('approve() rejects non-pending transitions locally', () {
    expect(
      () =>
          repo.approve(_buildRequest(status: MemberJoinRequestStatus.approved)),
      throwsA(isA<StateError>()),
    );
  });
}

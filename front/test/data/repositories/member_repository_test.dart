import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _orgId = 'org-1';

final _baseMember = Member(
  memberId: 'member-1',
  organizationId: _orgId,
  roles: const {Role.volunteer},
);

void main() {
  late AppDatabase db;
  late MemberRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemberRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'setRoles updates the row optimistically and enqueues an Upsert mutation',
    () async {
      await db.upsertMember(_orgId, _baseMember);

      await repo.setRoles(_orgId, _baseMember, {
        Role.volunteer,
        Role.coordinator,
      });

      final rows = await db.watchMembers(_orgId).first;
      expect(
        rows.single.roles,
        containsAll([Role.volunteer, Role.coordinator]),
      );

      final pending = await db.readPendingMutations();
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as MemberPayload;
      expect(
        payload.member.roles,
        containsAll([Role.volunteer, Role.coordinator]),
      );
    },
  );

  test('watch returns an empty list when no members exist', () async {
    final members = await repo.watch(_orgId).first;
    expect(members, isEmpty);
  });

  test('watch is reactive to upserts', () async {
    // Seed the sync cursor to simulate post-first-sync state: in production the
    // tenantId is the user's sub (not the org id), so the cursor fallback is
    // required to resolve the real org id.
    await db.writeCursor('organization:$_orgId', 'cursor-0');

    final stream = repo.watch(_orgId);
    final emitted = <List<Member>>[];
    final sub = stream.listen(emitted.add);

    await db.upsertMember(_orgId, _baseMember);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(emitted.last.length, 1);
  });
}

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MemberRepository repo;

  Member buildMember({
    String memberId = 'm-1',
    String orgId = 'org-1',
    String sub = 'sub-m-1',
    Set<Role> roles = const {Role.volunteer},
    List<MemberContract> contracts = const [],
    Map<String, dynamic>? memberSettings,
  }) => Member(
    memberId: memberId,
    organizationId: orgId,
    roles: roles,
    activeStatus: true,
    contracts: contracts,
    memberSettings: memberSettings,
  );

  MemberPreferences buildMemberPreferences({
    bool deliveryRemindersEnabled = true,
    String lastUpdatedInstant = '2024-01-01T00:00:00Z',
  }) => MemberPreferences(
    deliveryRemindersEnabled: deliveryRemindersEnabled,
    lastUpdatedInstant: lastUpdatedInstant,
  );

  UserPreferences buildUserPreferences({
    bool emailNotificationsEnabled = true,
    String lastUpdatedInstant = '2024-01-01T00:00:00Z',
  }) => UserPreferences(
    emailNotificationsEnabled: emailNotificationsEnabled,
    lastUpdatedInstant: lastUpdatedInstant,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemberRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  group('MemberRepository.removeMembership', () {
    test('deletes local row and enqueues Delete mutation', () async {
      await db.upsertMember(
        'org-1',
        buildMember(memberId: 'm-1', orgId: 'org-1'),
      );

      await repo.removeMembership(memberId: 'm-1', organizationId: 'org-1');

      // Optimistic: local row removed.
      final members = await db.watchMembers('org-1').first;
      expect(members, isEmpty);

      // Delete mutation enqueued.
      final pending = await db.readPendingMutations();
      expect(pending, hasLength(1));
      expect(pending.single.op, isA<Delete>());
      final del = pending.single.op as Delete;
      expect(del.entityType, EntityType.member);
      expect(del.entityId, 'm-1');
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey('org-1'));
    });

    test('is idempotent when row is already absent', () async {
      // No member inserted — should not throw.
      await repo.removeMembership(
        memberId: 'nonexistent',
        organizationId: 'org-1',
      );

      final pending = await db.readPendingMutations();
      // Delete is still enqueued even if row was absent.
      expect(pending, hasLength(1));
    });
  });

  group('MemberRepository.setRoles', () {
    test('optimistically updates roles and enqueues Upsert', () async {
      final member = buildMember(memberId: 'm-1', roles: {Role.volunteer});
      await db.upsertMember('org-1', member);

      await repo.setRoles('org-1', member, {Role.admin});

      final updated = (await db.watchMembers('org-1').first).single;
      expect(updated.roles, {Role.admin});

      final pending = await db.readPendingMutations();
      expect(pending, hasLength(1));
      expect(pending.single.op, isA<Upsert>());
    });
  });

  group('MemberRepository.updatePreferences', () {
    test(
      'optimistic local write and Upsert enqueued with correct scope',
      () async {
        final member = buildMember(memberId: 'm-1', orgId: 'org-1');
        await db.upsertMember('org-1', member);

        final newMemberPrefs = buildMemberPreferences(
          deliveryRemindersEnabled: false,
          lastUpdatedInstant: '2025-01-01T10:00:00Z',
        );
        final newUserPrefs = buildUserPreferences(
          emailNotificationsEnabled: false,
          lastUpdatedInstant: '2025-01-01T10:00:00Z',
        );

        await repo.updatePreferences(
          memberId: 'm-1',
          organizationId: 'org-1',
          memberPreferences: newMemberPrefs,
          userPreferences: newUserPrefs,
        );

        // Optimistic: local row has new preferences.
        final updated = (await db.watchMembers('org-1').first).single;
        expect(updated.memberPreferences, newMemberPrefs);
        expect(updated.userPreferences, newUserPrefs);

        // Pending mutation enqueued with correct scope key.
        final entries = await db.readPendingMutationEntries();
        expect(entries, hasLength(1));
        expect(entries.single.scopeKey, organizationScopeKey('org-1'));

        // Payload round-trips to Upsert(MemberPayload(updatedMember)).
        final mutations = await db.readPendingMutations();
        expect(mutations.single.op, isA<Upsert>());
        final upsert = mutations.single.op as Upsert;
        expect(upsert.payload, isA<MemberPayload>());
        final payload = upsert.payload as MemberPayload;
        expect(payload.member.memberPreferences, newMemberPrefs);
        expect(payload.member.userPreferences, newUserPrefs);
      },
    );

    test('preserves other fields (roles, contracts, memberSettings)', () async {
      final member = buildMember(
        memberId: 'm-2',
        orgId: 'org-1',
        roles: {Role.coordinator},
        memberSettings: {'key': 'value'},
      );
      await db.upsertMember('org-1', member);

      await repo.updatePreferences(
        memberId: 'm-2',
        organizationId: 'org-1',
        memberPreferences: buildMemberPreferences(),
        userPreferences: buildUserPreferences(),
      );

      final updated = (await db.watchMembers('org-1').first).single;
      expect(updated.roles, {Role.coordinator});
      expect(updated.memberSettings, {'key': 'value'});
      expect(updated.memberId, 'm-2');
      expect(updated.organizationId, 'org-1');
    });

    test('throws StateError when member is absent', () async {
      await expectLater(
        repo.updatePreferences(
          memberId: 'unknown',
          organizationId: 'org-1',
          memberPreferences: buildMemberPreferences(),
          userPreferences: buildUserPreferences(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('MemberRepository.watchMyMember', () {
    test('emits null when no member with that sub exists', () async {
      final result = await repo.watchMyMember('sub-nobody').first;
      expect(result, isNull);
    });

    test('emits the matching member when one is seeded', () async {
      // After sub/id unification: memberId == sub, so pass the sub value as
      // memberId.  The `sub` field is kept on the domain model for backward
      // compatibility but is no longer used for identity resolution.
      final member = buildMember(memberId: 'sub-alice');
      await db.upsertMember('org-1', member);

      final result = await repo.watchMyMember('sub-alice').first;
      expect(result, isNotNull);
      expect(result!.memberId, 'sub-alice');
    });

    test('re-emits on update', () async {
      final member = buildMember(memberId: 'sub-bob');
      await db.upsertMember('org-1', member);

      final stream = repo.watchMyMember('sub-bob');
      final emissions = <Member?>[];
      final subscription = stream.listen(emissions.add);

      // Wait for first emission.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(1));
      expect(emissions.first!.roles, {Role.volunteer});

      // Update the row directly via drift (simulates a sync applying a change).
      final updated = member.copyWith(roles: {Role.admin});
      await db.upsertMember('org-1', updated);

      // Wait for second emission.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(2));
      expect(emissions[1]!.roles, {Role.admin});

      await subscription.cancel();
    });
  });

  group('MemberRepository.suspend', () {
    test('flips accountStatus to SUSPENDED and enqueues Upsert', () async {
      await db.upsertMember('org-1', buildMember(memberId: 'm-1'));

      await repo.suspend(memberId: 'm-1', organizationId: 'org-1');

      final members = await db.watchMembers('org-1').first;
      expect(members.single.accountStatus, MemberAccountStatus.suspended);
      expect(members.single.activeStatus, isFalse);

      final pending = await db.readPendingMutations();
      expect(pending, hasLength(1));
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as MemberPayload;
      expect(payload.member.accountStatus, MemberAccountStatus.suspended);
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey('org-1'));
    });

    test('throws StateError when member is absent', () async {
      await expectLater(
        repo.suspend(memberId: 'missing', organizationId: 'org-1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('MemberRepository.reactivate', () {
    test('flips accountStatus to ACTIVE and enqueues Upsert', () async {
      final seeded = buildMember(memberId: 'm-1').copyWith(
        accountStatus: MemberAccountStatus.suspended,
        activeStatus: false,
      );
      await db.upsertMember('org-1', seeded);

      await repo.reactivate(memberId: 'm-1', organizationId: 'org-1');

      final members = await db.watchMembers('org-1').first;
      expect(members.single.accountStatus, MemberAccountStatus.active);
      expect(members.single.activeStatus, isTrue);

      final pending = await db.readPendingMutations();
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as MemberPayload;
      expect(payload.member.accountStatus, MemberAccountStatus.active);
    });
  });

  group('MemberRepository.delete', () {
    test('removes local row and enqueues Delete mutation', () async {
      await db.upsertMember('org-1', buildMember(memberId: 'm-1'));

      await repo.delete(memberId: 'm-1', organizationId: 'org-1');

      final members = await db.watchMembers('org-1').first;
      expect(members, isEmpty);

      final pending = await db.readPendingMutations();
      expect(pending, hasLength(1));
      final del = pending.single.op as Delete;
      expect(del.entityType, EntityType.member);
      expect(del.entityId, 'm-1');
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey('org-1'));
    });
  });

  group('MemberRepository.updateProfile', () {
    test('patches PII fields and enqueues Upsert', () async {
      await db.upsertMember('org-1', buildMember(memberId: 'm-1'));

      await repo.updateProfile(
        memberId: 'm-1',
        organizationId: 'org-1',
        firstName: 'Alice',
        lastName: 'Martin',
        email: 'alice@example.org',
        phone: '0612345678',
      );

      final members = await db.watchMembers('org-1').first;
      expect(members.single.firstName, 'Alice');
      expect(members.single.lastName, 'Martin');
      expect(members.single.email, 'alice@example.org');
      expect(members.single.phone, '0612345678');

      final pending = await db.readPendingMutations();
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as MemberPayload;
      expect(payload.member.firstName, 'Alice');
      expect(payload.member.phone, '0612345678');
    });

    test('throws StateError when member is absent', () async {
      await expectLater(
        repo.updateProfile(
          memberId: 'missing',
          organizationId: 'org-1',
          firstName: 'x',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

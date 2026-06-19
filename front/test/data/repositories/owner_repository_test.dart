import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late OwnerRepository repo;

  Owner buildOwner({
    String ownerId = 'o-1',
    AccountStatus accountStatus = AccountStatus.active,
  }) => Owner(
    ownerId: ownerId,
    firstName: 'Alice',
    lastName: 'Martin',
    email: 'alice@example.com',
    accountStatus: accountStatus,
    registeredAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OwnerRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OwnerRepository', () {
    group('watchAll', () {
      test('emits empty list when no owners are cached', () async {
        final owners = await repo.watchAll().first;
        expect(owners, isEmpty);
      });

      test('emits all cached owners', () async {
        await db.upsertOwner(buildOwner(ownerId: 'o-1'));
        await db.upsertOwner(buildOwner(ownerId: 'o-2'));

        final owners = await repo.watchAll().first;
        expect(owners.length, 2);
        expect(owners.map((o) => o.ownerId), containsAll(['o-1', 'o-2']));
      });

      test('reacts to subsequent upserts', () async {
        final emitted = <List<Owner>>[];
        final sub = repo.watchAll().listen(emitted.add);

        await db.upsertOwner(buildOwner(ownerId: 'o-1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await db.upsertOwner(buildOwner(ownerId: 'o-2'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await sub.cancel();

        // First emission: empty; then 1 row; then 2 rows.
        expect(emitted.last.length, 2);
      });
    });

    group('updateProfile', () {
      test('enqueues an Upsert mutation on the instance-owner scope', () async {
        await db.upsertOwner(buildOwner(ownerId: 'o-1'));

        await repo.updateProfile(
          ownerId: 'o-1',
          firstName: 'Bob',
          lastName: 'Martin',
          email: 'bob@example.com',
          phone: '0601020304',
        );

        final entries = await db.readPendingMutationEntries();
        expect(entries.length, 1);
        expect(entries.first.scopeKey, instanceOwnerScopeKey);
        final op = entries.first.mutation.op;
        expect(op, isA<Upsert>());
        final upsert = op as Upsert;
        expect(upsert.payload.entityType, EntityType.owner);
        final payload = upsert.payload as OwnerPayload;
        expect(payload.owner.firstName, 'Bob');
        expect(payload.owner.lastName, 'Martin');
        expect(payload.owner.email, 'bob@example.com');
        expect(payload.owner.phone, '0601020304');
      });

      test('also updates the local drift cache', () async {
        await db.upsertOwner(buildOwner(ownerId: 'o-1'));

        await repo.updateProfile(
          ownerId: 'o-1',
          firstName: 'Bob',
          lastName: 'Martin',
          email: 'bob@example.com',
        );

        final updated = await repo.findById('o-1');
        expect(updated?.firstName, 'Bob');
        expect(updated?.lastName, 'Martin');
        expect(updated?.email, 'bob@example.com');
      });
    });

    group('findById', () {
      test('returns null when owner is not in the cache', () async {
        expect(await repo.findById('o-missing'), isNull);
      });

      test('returns the correct owner by id', () async {
        await db.upsertOwner(buildOwner(ownerId: 'o-1'));
        await db.upsertOwner(buildOwner(ownerId: 'o-2'));

        final found = await repo.findById('o-1');
        expect(found?.ownerId, 'o-1');
      });

      test('reflects the latest state after an upsert', () async {
        await db.upsertOwner(buildOwner(ownerId: 'o-1'));
        await db.upsertOwner(
          buildOwner(ownerId: 'o-1', accountStatus: AccountStatus.suspended),
        );

        final found = await repo.findById('o-1');
        expect(found?.accountStatus, AccountStatus.suspended);
      });
    });
  });
}

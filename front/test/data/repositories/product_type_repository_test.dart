import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/product_type_fixtures.dart';

void main() {
  late AppDatabase db;
  late ProductTypeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProductTypeRepository(
      db: db,
      // Seed Random for deterministic ids.
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes a tmp_ row optimistically and enqueues an Upsert mutation',
    () async {
      final pt = await repo.create(
        tenantId: testTenantId,
        name: 'Vegetables',
        supportedBasketSizes: const [smallBasketSize],
      );

      expect(pt.productTypeId.startsWith(ClientMutation.tmpIdPrefix), isTrue);

      final rows = await db.watchProductTypes(testTenantId).first;
      expect(rows.single.name, 'Vegetables');

      final pending = await db.readPendingMutations();
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect((upsert.payload as ProductTypePayload).productType, pt);
      final pendingEntries = await db.readPendingMutationEntries();
      expect(
        pendingEntries.single.scopeKey,
        producerAccountScopeKey(testTenantId),
      );
    },
  );

  test('update upserts the row and enqueues an Upsert mutation', () async {
    final pt = buildProductType(name: 'Old');
    await db.upsertProductType(pt);

    await repo.update(pt.copyWith(name: 'New'));

    final rows = await db.watchProductTypes(testTenantId).first;
    expect(rows.single.name, 'New');
    final pending = await db.readPendingMutations();
    expect(pending.single.op, isA<Upsert>());
  });

  test('delete removes the row and enqueues a Delete mutation', () async {
    await db.upsertProductType(buildProductType(name: 'X'));

    await repo.delete(tenantId: testTenantId, productTypeId: 'pt-1');

    expect(await db.watchProductTypes(testTenantId).first, isEmpty);
    final pending = await db.readPendingMutations();
    final delete = pending.single.op as Delete;
    expect(delete.entityType, EntityType.productType);
    expect(delete.entityId, 'pt-1');
  });

  test('watch is reactive to upserts', () async {
    final stream = repo.watch(testTenantId);
    final emitted = <List<ProductType>>[];
    final sub = stream.listen(emitted.add);

    await repo.create(tenantId: testTenantId, name: 'A');
    await repo.create(tenantId: testTenantId, name: 'B');

    // Wait for stream to settle.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(emitted.last.length, 2);
  });
}

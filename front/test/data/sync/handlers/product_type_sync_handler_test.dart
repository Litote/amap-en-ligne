import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/handlers/product_type_sync_handler.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/product_type_fixtures.dart';

void main() {
  late AppDatabase db;
  const handler = ProductTypeSyncHandler();

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a tombstone on the producer scope deletes the producer type', () async {
    await db.upsertProductType(buildProductType(productTypeId: 'pt-1'));

    await handler.deleteEntity(
      db,
      entityId: 'pt-1',
      scopeKey: 'producer-account:$testTenantId',
    );

    expect(await db.watchProductTypes(testTenantId).first, isEmpty);
  });

  test('a tombstone on an organization scope (read-only catalog of a linked '
      'producer) deletes the type by id', () async {
    await db.upsertProductType(
      buildProductType(productTypeId: 'pt-9', producerAccountId: 'pa-9'),
    );

    await handler.deleteEntity(
      db,
      entityId: 'pt-9',
      scopeKey: 'organization:org-1',
    );

    expect(await db.watchProductTypes('pa-9').first, isEmpty);
  });
}

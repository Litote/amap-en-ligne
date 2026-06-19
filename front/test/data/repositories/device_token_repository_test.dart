import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/device_token_repository.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scope = 'member:m-1';
  late AppDatabase db;
  late DeviceTokenRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DeviceTokenRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'register writes a tmp_ row optimistically and enqueues an Upsert',
    () async {
      final token = await repo.register(
        recipientScope: scope,
        token: 'fcm-1',
        platform: DevicePlatform.android,
        nowIso: '2026-05-29T10:00:00Z',
      );

      expect(
        token.deviceTokenId.startsWith(ClientMutation.tmpIdPrefix),
        isTrue,
      );

      final rows = await db.watchDeviceTokens(scope).first;
      expect(rows.single.token, 'fcm-1');

      final pending = await db.readPendingMutations();
      final upsert = pending.single.op as Upsert;
      expect((upsert.payload as DeviceTokenPayload).deviceToken.token, 'fcm-1');
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, scope);
    },
  );

  test(
    'register is a no-op for an already-registered token (no second enqueue)',
    () async {
      final first = await repo.register(
        recipientScope: scope,
        token: 'fcm-1',
        platform: DevicePlatform.android,
        nowIso: '2026-05-29T10:00:00Z',
      );
      final second = await repo.register(
        recipientScope: scope,
        token: 'fcm-1',
        platform: DevicePlatform.android,
        nowIso: '2026-05-29T12:00:00Z',
      );

      // Same row reused, no duplicate row, and only the first register enqueued.
      expect(second.deviceTokenId, first.deviceTokenId);
      expect((await db.watchDeviceTokens(scope).first).length, 1);
      expect((await db.readPendingMutations()).length, 1);
    },
  );

  test('removeByToken deletes the row and enqueues a Delete', () async {
    final token = await repo.register(
      recipientScope: scope,
      token: 'fcm-1',
      platform: DevicePlatform.ios,
      nowIso: '2026-05-29T10:00:00Z',
    );
    // Drop the registration Upsert so only the Delete remains for assertion.
    await db.dropPendingMutationsForScopes([scope]);

    await repo.removeByToken(recipientScope: scope, token: 'fcm-1');

    expect(await db.watchDeviceTokens(scope).first, isEmpty);
    final pending = await db.readPendingMutations();
    final delete = pending.single.op as Delete;
    expect(delete.entityType, EntityType.deviceToken);
    expect(delete.entityId, token.deviceTokenId);
  });

  test('removeByToken is a no-op when the token is absent', () async {
    await repo.removeByToken(recipientScope: scope, token: 'unknown');
    expect(await db.readPendingMutations(), isEmpty);
  });
}

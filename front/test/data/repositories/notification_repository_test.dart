import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _memberId = 'm-1';

AppNotification _notification({String id = 'notif-1', String? readAt}) =>
    AppNotification(
      notificationId: id,
      recipientScope: memberScopeKey(_memberId),
      type: NotificationType.info,
      category: NotificationCategory.basketExchangeAccepted,
      title: 'Title',
      body: 'Body',
      createdAt: '2026-05-29T10:00:00Z',
      readAt: readAt,
    );

void main() {
  late AppDatabase db;
  late NotificationRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NotificationRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test('watch streams notifications on the member scope', () async {
    await db.upsertNotification(_notification());
    final rows = await repo.watch(_memberId).first;
    expect(rows.single.notificationId, 'notif-1');
  });

  test('markRead sets read_at optimistically and enqueues an Upsert', () async {
    await db.upsertNotification(_notification());

    await repo.markRead(_notification(), readAtIso: '2026-05-29T11:00:00Z');

    final stored = await db.getNotification(
      memberScopeKey(_memberId),
      'notif-1',
    );
    expect(stored?.readAt, '2026-05-29T11:00:00Z');

    final pending = await db.readPendingMutations();
    final upsert = pending.single.op as Upsert;
    final payload = upsert.payload as NotificationPayload;
    expect(payload.notification.readAt, '2026-05-29T11:00:00Z');

    final entries = await db.readPendingMutationEntries();
    expect(entries.single.scopeKey, memberScopeKey(_memberId));
  });

  test('markRead is a no-op when already read', () async {
    final already = _notification(readAt: '2026-05-29T11:00:00Z');
    await db.upsertNotification(already);

    await repo.markRead(already, readAtIso: '2026-05-29T12:00:00Z');

    expect(await db.readPendingMutations(), isEmpty);
  });

  test('archive deletes the row and enqueues a Delete', () async {
    await db.upsertNotification(_notification());

    await repo.archive(_notification());

    expect(await repo.watch(_memberId).first, isEmpty);
    final pending = await db.readPendingMutations();
    final delete = pending.single.op as Delete;
    expect(delete.entityType, EntityType.notification);
    expect(delete.entityId, 'notif-1');
  });
}

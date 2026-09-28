import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write API for the member's private notification feed (ADR-005).
///
/// Notifications are created server-side; the client only marks them read
/// ([markRead]) or archives them ([archive]). Both apply optimistically to the
/// local cache and enqueue a `ClientMutation` flushed on the next sync.
class NotificationRepository {
  NotificationRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Watches the notifications addressed to [memberId]'s private scope.
  Stream<List<AppNotification>> watch(String memberId) =>
      _db.watchNotifications(memberScopeKey(memberId));

  /// Marks [notification] as read at [readAtIso] (ISO-8601), optimistically.
  /// No-op if it is already read.
  Future<void> markRead(
    AppNotification notification, {
    required String readAtIso,
  }) {
    if (notification.readAt != null) {
      return Future.value();
    }
    final read = notification.copyWith(readAt: readAtIso);
    return _db.transaction(() async {
      await _db.upsertNotification(read);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: NotificationPayload(notification: read)),
        ),
        scopeKey: read.recipientScope,
      );
    });
  }

  /// Archives (deletes) [notification] from the feed, optimistically.
  Future<void> archive(AppNotification notification) =>
      _db.transaction(() async {
        await _db.deleteNotification(
          notification.recipientScope,
          notification.notificationId,
        );
        await _db.enqueuePendingMutation(
          ClientMutation(
            clientOpId: _idGen.next(),
            op: Delete(
              entityType: EntityType.notification,
              entityId: notification.notificationId,
            ),
          ),
          scopeKey: notification.recipientScope,
        );
      });
}

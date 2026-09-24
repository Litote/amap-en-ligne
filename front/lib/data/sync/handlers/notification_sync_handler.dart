import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';

/// Sync handler for `AppNotification` on the recipient's private scope
/// (`member:{id}` today — see ADR-005). Notifications are server-authoritative:
/// the client only flips `read_at` or archives, so there is no tmp_* id remap.
final class NotificationSyncHandler implements EntitySyncHandler {
  const NotificationSyncHandler();

  @override
  EntityType get entityType => EntityType.notification;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! NotificationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertNotification(payload.notification);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteNotification(scopeKey, entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // Notifications are created server-side; clients never allocate tmp_* ids.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

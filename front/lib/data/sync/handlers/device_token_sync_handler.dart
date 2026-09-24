import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

/// Sync handler for `DeviceToken` on the recipient's private scope (ADR-005).
/// Client-authored: the app upserts a `tmp_*` id when it registers a push token,
/// and the server allocates the real id — so this handler remaps it like other
/// client-created entities.
final class DeviceTokenSyncHandler implements EntitySyncHandler {
  const DeviceTokenSyncHandler();

  @override
  EntityType get entityType => EntityType.deviceToken;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final deviceTokenPayload = _require(payload);
    return db.upsertDeviceToken(deviceTokenPayload.deviceToken);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteDeviceToken(scopeKey, entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final deviceToken = _require(payload).deviceToken;
    final localId = deviceToken.deviceTokenId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapDeviceTokenId(
      recipientScope: deviceToken.recipientScope,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! DeviceTokenPayload) return mutation;
      final deviceToken = payload.deviceToken;
      if (deviceToken.deviceTokenId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: DeviceTokenPayload(
            deviceToken: deviceToken.copyWith(deviceTokenId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.deviceToken,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.deviceToken, entityId: newId),
      );
    }
    return mutation;
  }

  DeviceTokenPayload _require(EntityPayload payload) {
    if (payload is DeviceTokenPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

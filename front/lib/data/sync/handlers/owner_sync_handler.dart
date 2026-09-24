import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

final class OwnerSyncHandler implements EntitySyncHandler {
  const OwnerSyncHandler();

  @override
  EntityType get entityType => EntityType.owner;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OwnerPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOwner(payload.owner);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // The back always returns FORBIDDEN for Owner DELETE mutations, but we
      // mirror the delete locally in case a tombstone arrives (e.g. after a
      // future protocol revision or manual cleanup).
      db.deleteOwner(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! OwnerPayload) {
      return Future.value();
    }
    final owner = payload.owner;
    final localId = owner.ownerId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    // Remap: delete + re-insert with the server-allocated id.
    return db.transaction(() async {
      await db.deleteOwner(localId);
      await db.upsertOwner(owner.copyWith(ownerId: serverEntityId));
    });
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! OwnerPayload) return mutation;
      final owner = payload.owner;
      if (owner.ownerId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: OwnerPayload(owner: owner.copyWith(ownerId: newId)),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.owner,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.owner, entityId: newId),
      );
    }
    return mutation;
  }
}

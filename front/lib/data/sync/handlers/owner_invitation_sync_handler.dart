import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

final class OwnerInvitationSyncHandler implements EntitySyncHandler {
  const OwnerInvitationSyncHandler();

  @override
  EntityType get entityType => EntityType.ownerInvitation;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OwnerInvitationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOwnerInvitation(payload.ownerInvitation);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteOwnerInvitation(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! OwnerInvitationPayload) {
      return Future.value();
    }
    final invitation = payload.ownerInvitation;
    final localId = invitation.invitationId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapOwnerInvitationId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! OwnerInvitationPayload) return mutation;
      final invitation = payload.ownerInvitation;
      if (invitation.invitationId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: OwnerInvitationPayload(
            ownerInvitation: invitation.copyWith(invitationId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.ownerInvitation,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.ownerInvitation, entityId: newId),
      );
    }
    return mutation;
  }
}

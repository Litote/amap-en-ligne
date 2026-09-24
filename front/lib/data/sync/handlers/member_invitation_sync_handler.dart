import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class MemberInvitationSyncHandler implements EntitySyncHandler {
  const MemberInvitationSyncHandler();

  @override
  EntityType get entityType => EntityType.memberInvitation;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberInvitationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final invitation = payload.memberInvitation;
    return db.upsertMemberInvitation(invitation.organizationId, invitation);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMemberInvitation(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! MemberInvitationPayload) {
      return Future.value();
    }
    final invitation = payload.memberInvitation;
    final localId = invitation.invitationId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapMemberInvitationId(
      organizationId: invitation.organizationId,
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
      if (payload is! MemberInvitationPayload) return mutation;
      final invitation = payload.memberInvitation;
      if (invitation.invitationId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: MemberInvitationPayload(
            memberInvitation: invitation.copyWith(invitationId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.memberInvitation,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.memberInvitation, entityId: newId),
      );
    }
    return mutation;
  }
}

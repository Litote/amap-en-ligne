import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class MemberSyncHandler implements EntitySyncHandler {
  const MemberSyncHandler();

  @override
  EntityType get entityType => EntityType.member;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final m = payload.member;
    return db.upsertMember(m.organizationId, m);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMember(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! MemberPayload) {
      return Future.value();
    }
    final member = payload.member;
    final localId = member.memberId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapMemberId(
      organizationId: member.organizationId,
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
      if (payload is! MemberPayload) return mutation;
      final member = payload.member;
      if (member.memberId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: MemberPayload(member: member.copyWith(memberId: newId)),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.member,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.member, entityId: newId),
      );
    }
    return mutation;
  }
}

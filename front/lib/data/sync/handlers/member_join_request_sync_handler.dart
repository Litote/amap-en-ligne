import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class MemberJoinRequestSyncHandler implements EntitySyncHandler {
  const MemberJoinRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.memberJoinRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberJoinRequestPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertMemberJoinRequest(payload.memberJoinRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMemberJoinRequest(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) => Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

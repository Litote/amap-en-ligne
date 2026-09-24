import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';

final class OrganizationRequestSyncHandler implements EntitySyncHandler {
  const OrganizationRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.organizationRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OrganizationRequestPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOrganizationRequest(payload.organizationRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteOrganizationRequest(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // OrganizationRequest ids are server-allocated, never tmp_*.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

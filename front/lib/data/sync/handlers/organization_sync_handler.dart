import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';

final class OrganizationSyncHandler implements EntitySyncHandler {
  const OrganizationSyncHandler();

  @override
  EntityType get entityType => EntityType.organization;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OrganizationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOrganization(payload.organization);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // Organization id = entityId; clear it.
      db.clearOrganizationsForTenant(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // Organization ids are server-allocated at activation, never tmp_*.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

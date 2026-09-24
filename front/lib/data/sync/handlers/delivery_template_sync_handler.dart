import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class DeliveryTemplateSyncHandler implements EntitySyncHandler {
  const DeliveryTemplateSyncHandler();

  @override
  EntityType get entityType => EntityType.deliveryTemplate;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! DeliveryTemplatePayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final t = payload.deliveryTemplate;
    return db.upsertDeliveryTemplate(t.organizationId, t);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteDeliveryTemplate(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! DeliveryTemplatePayload) {
      return Future.value();
    }
    final t = payload.deliveryTemplate;
    final localId = t.deliveryTemplateId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapDeliveryTemplateId(
      organizationId: t.organizationId,
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
      if (payload is! DeliveryTemplatePayload) return mutation;
      final template = payload.deliveryTemplate;
      if (template.deliveryTemplateId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: DeliveryTemplatePayload(
            deliveryTemplate: template.copyWith(deliveryTemplateId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.deliveryTemplate,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.deliveryTemplate, entityId: newId),
      );
    }
    return mutation;
  }
}

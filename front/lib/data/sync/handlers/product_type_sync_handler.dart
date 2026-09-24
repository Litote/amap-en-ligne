import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class ProductTypeSyncHandler implements EntitySyncHandler {
  const ProductTypeSyncHandler();

  @override
  EntityType get entityType => EntityType.productType;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final productTypePayload = _requireProductTypePayload(payload);
    return db.upsertProductType(productTypePayload.productType);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteProductType(
    producerAccountId: (SyncScope.fromKey(scopeKey) as ProducerAccountSyncScope)
        .producerAccountId,
    productTypeId: entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final productTypePayload = _requireProductTypePayload(payload);
    final productType = productTypePayload.productType;
    final localId = productType.productTypeId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapProductTypeId(
      producerAccountId: productType.producerAccountId,
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
      if (payload is! ProductTypePayload) return mutation;
      final productType = payload.productType;
      if (productType.productTypeId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: ProductTypePayload(
            productType: productType.copyWith(productTypeId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.productType,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.productType, entityId: newId),
      );
    }
    return mutation;
  }

  ProductTypePayload _requireProductTypePayload(EntityPayload payload) {
    if (payload is ProductTypePayload) {
      return payload;
    }
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

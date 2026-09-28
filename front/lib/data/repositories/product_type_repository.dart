import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write API for `ProductType` entities.
///
/// Writes apply optimistically to the local cache and enqueue a
/// `ClientMutation` in the pending queue. The actual flush to the server
/// happens on the next `SyncRepository.sync()` call (typically triggered by
/// the presentation layer after each write, on app start, on connectivity
/// regained, …).
class ProductTypeRepository {
  ProductTypeRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<ProductType>> watch(String tenantId) =>
      _db.watchProductTypes(tenantId);

  /// Creates a new product type with a `tmp_*` id; the server will allocate
  /// the real id on the next sync and `SyncRepository` will remap the row.
  Future<ProductType> create({
    required String tenantId,
    required String name,
    String? description,
    List<BasketSize> supportedBasketSizes = const [],
  }) async {
    final pt = ProductType(
      productTypeId: _idGen.nextTmpId(),
      producerAccountId: tenantId,
      name: name,
      description: description,
      supportedBasketSizes: supportedBasketSizes,
    );
    await _db.transaction(() async {
      await _db.upsertProductType(pt);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: ProductTypePayload(productType: pt)),
        ),
        scopeKey: producerAccountScopeKey(tenantId),
      );
    });
    return pt;
  }

  Future<void> update(ProductType pt) => _db.transaction(() async {
    await _db.upsertProductType(pt);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(payload: ProductTypePayload(productType: pt)),
      ),
      scopeKey: producerAccountScopeKey(pt.producerAccountId),
    );
  });

  /// Updates the [ItemType] list of [pt] and enqueues the mutation.
  Future<void> updateItemTypes(ProductType pt, List<ItemType> itemTypes) =>
      update(pt.copyWith(itemTypes: itemTypes));

  Future<void> delete({
    required String tenantId,
    required String productTypeId,
  }) => _db.transaction(() async {
    await _db.deleteProductType(
      producerAccountId: tenantId,
      productTypeId: productTypeId,
    );
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Delete(entityType: EntityType.productType, entityId: productTypeId),
      ),
      scopeKey: producerAccountScopeKey(tenantId),
    );
  });
}

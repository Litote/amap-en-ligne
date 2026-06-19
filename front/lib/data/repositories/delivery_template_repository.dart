import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write repository for [DeliveryTemplate] entities.
///
/// Writes apply optimistically to the local cache and enqueue a
/// [ClientMutation] in the pending queue. The actual flush to the server
/// happens on the next `SyncRepository.sync()` call.
class DeliveryTemplateRepository {
  DeliveryTemplateRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<DeliveryTemplate>> watch(String organizationId) =>
      _db.watchDeliveryTemplates(organizationId);

  /// Creates a new delivery template optimistically and enqueues an Upsert.
  Future<DeliveryTemplate> create(DeliveryTemplate template) async {
    final withTmpId = template.copyWith(deliveryTemplateId: _idGen.nextTmpId());
    await _submitMutation(withTmpId);
    return withTmpId;
  }

  /// Updates an existing delivery template optimistically and enqueues an
  /// Upsert.
  Future<void> update(DeliveryTemplate template) => _submitMutation(template);

  /// Deletes a delivery template optimistically and enqueues a Delete mutation.
  Future<void> delete(String deliveryTemplateId, String organizationId) async {
    await _db.deleteDeliveryTemplate(organizationId, deliveryTemplateId);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Delete(
          entityType: EntityType.deliveryTemplate,
          entityId: deliveryTemplateId,
        ),
      ),
      scopeKey: organizationScopeKey(organizationId),
    );
  }

  Future<void> _submitMutation(DeliveryTemplate template) async {
    await _db.upsertDeliveryTemplate(template.organizationId, template);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(
          payload: DeliveryTemplatePayload(deliveryTemplate: template),
        ),
      ),
      scopeKey: organizationScopeKey(template.organizationId),
    );
  }
}

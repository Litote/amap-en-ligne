import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Sync handler for the read-only [ProducerSchedule] projection served on the
/// producer's `producer-account:{id}` feed. The client never creates nor
/// mutates schedules, so there is no `tmp_*` id to remap and no queued
/// mutation to rewrite.
final class ProducerScheduleSyncHandler implements EntitySyncHandler {
  const ProducerScheduleSyncHandler();

  @override
  EntityType get entityType => EntityType.producerSchedule;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ProducerSchedulePayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertProducerSchedule(payload.producerSchedule);
  }

  /// Tombstones carry the organization id; the producer is the scope's owner.
  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => switch (SyncScope.fromKey(scopeKey)) {
    ProducerAccountSyncScope(:final producerAccountId) =>
      db.deleteProducerSchedule(
        producerAccountId: producerAccountId,
        organizationId: entityId,
      ),
    _ => Future.value(),
  };

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

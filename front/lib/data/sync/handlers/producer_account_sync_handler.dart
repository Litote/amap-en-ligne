import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class ProducerAccountSyncHandler implements EntitySyncHandler {
  const ProducerAccountSyncHandler();

  @override
  EntityType get entityType => EntityType.producerAccount;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ProducerAccountPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final pa = payload.producerAccount;
    // The organizationId is the tenant id (producer_account_id of the AMAP admin).
    // For the sync protocol the tenantId == producerAccountId here (1:1 scoping).
    return db.upsertProducerAccount(pa.producerAccountId, pa);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) {
    final scope = SyncScope.fromKey(scopeKey);
    // Producer-scope tombstones key by the producer-account-id-as-tenant.
    // Instance-owner (or organization) tombstones: applyPayload stored the
    // row with tenantId == entityId (producer is its own tenant in the
    // local cache — see applyPayload above), so we delete with the same key.
    final tenantId = scope is ProducerAccountSyncScope
        ? scope.producerAccountId
        : entityId;
    return db.deleteProducerAccount(tenantId, entityId);
  }

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! ProducerAccountPayload) {
      return Future.value();
    }
    final producerAccount = payload.producerAccount;
    final localId = producerAccount.producerAccountId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapProducerAccountId(oldId: localId, newId: serverEntityId);
  }

  ClientMutation _rewriteProducerAccountPayload(
    ClientMutation mutation,
    ProducerAccountPayload payload,
    String oldId,
    String newId,
  ) {
    final producer = payload.producerAccount;
    if (producer.producerAccountId != oldId) {
      return mutation;
    }
    return mutation.copyWith(
      op: Upsert(
        payload: ProducerAccountPayload(
          producerAccount: producer.copyWith(producerAccountId: newId),
        ),
      ),
    );
  }

  ClientMutation _rewriteOrganizationPayload(
    ClientMutation mutation,
    OrganizationPayload payload,
    String oldId,
    String newId,
  ) {
    final organization = payload.organization;
    final hasProducerReference = organization.producers.any(
      (producer) => producer.producerAccountId == oldId,
    );
    if (!hasProducerReference) {
      return mutation;
    }
    return mutation.copyWith(
      op: Upsert(
        payload: OrganizationPayload(
          organization: organization.copyWith(
            producers: organization.producers
                .map(
                  (producer) => producer.producerAccountId == oldId
                      ? producer.copyWith(producerAccountId: newId)
                      : producer,
                )
                .toList(),
          ),
        ),
      ),
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
      if (payload is ProducerAccountPayload) {
        return _rewriteProducerAccountPayload(mutation, payload, oldId, newId);
      }
      if (payload is OrganizationPayload) {
        return _rewriteOrganizationPayload(mutation, payload, oldId, newId);
      }
    }
    if (op case Delete(
      entityType: EntityType.producerAccount,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.producerAccount, entityId: newId),
      );
    }
    return mutation;
  }
}

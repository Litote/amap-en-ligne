import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

final class ContractSyncHandler implements EntitySyncHandler {
  const ContractSyncHandler();

  @override
  EntityType get entityType => EntityType.contract;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ContractPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final c = payload.contract;
    return db.upsertContract(c.organizationId, c);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteContract(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! ContractPayload) {
      return Future.value();
    }
    final contract = payload.contract;
    final localId = contract.contractId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapContractId(
      organizationId: contract.organizationId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  ClientMutation _rewriteContractPayload(
    ClientMutation mutation,
    ContractPayload payload,
    String oldId,
    String newId,
  ) {
    final contract = payload.contract;
    if (contract.contractId != oldId) return mutation;
    return mutation.copyWith(
      op: Upsert(
        payload: ContractPayload(
          contract: contract.copyWith(contractId: newId),
        ),
      ),
    );
  }

  ClientMutation _rewriteOrganizationPayloadForContract(
    ClientMutation mutation,
    OrganizationPayload payload,
    String oldId,
    String newId,
  ) {
    final organization = payload.organization;
    final hasContractReference = organization.deliveries.any(
      (d) => d.contracts.any((dc) => dc.contractId == oldId),
    );
    if (!hasContractReference) return mutation;
    return mutation.copyWith(
      op: Upsert(
        payload: OrganizationPayload(
          organization: organization.copyWith(
            deliveries: organization.deliveries.map((d) {
              final hasRef = d.contracts.any((dc) => dc.contractId == oldId);
              if (!hasRef) return d;
              return d.copyWith(
                contracts: d.contracts
                    .map(
                      (dc) => dc.contractId == oldId
                          ? dc.copyWith(contractId: newId)
                          : dc,
                    )
                    .toList(),
              );
            }).toList(),
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
      if (payload is ContractPayload) {
        return _rewriteContractPayload(mutation, payload, oldId, newId);
      }
      if (payload is OrganizationPayload) {
        return _rewriteOrganizationPayloadForContract(
          mutation,
          payload,
          oldId,
          newId,
        );
      }
      return mutation;
    }
    if (op case Delete(
      entityType: EntityType.contract,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.contract, entityId: newId),
      );
    }
    return mutation;
  }
}

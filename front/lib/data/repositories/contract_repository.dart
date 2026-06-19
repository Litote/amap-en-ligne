import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write repository for [Contract] entities.
///
/// Writes apply optimistically to the local cache and enqueue a pending
/// [ClientMutation] for the next sync flush.
class ContractRepository {
  ContractRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<Contract>> watch(String organizationId) =>
      _db.watchContracts(organizationId);

  /// Creates a new contract with a temporary id and enqueues an Upsert.
  Future<Contract> create(Contract contract) async {
    final withTmpId = contract.copyWith(contractId: _idGen.nextTmpId());
    await _submitMutation(withTmpId);
    return withTmpId;
  }

  /// Updates an existing contract optimistically and enqueues an Upsert.
  Future<void> update(Contract contract) => _submitMutation(contract);

  /// Deletes a contract optimistically and enqueues a Delete mutation.
  Future<void> delete(String contractId, String organizationId) async {
    await _db.transaction(() async {
      await _db.deleteContract(organizationId, contractId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Delete(entityType: EntityType.contract, entityId: contractId),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
  }

  Future<void> _submitMutation(Contract contract) async {
    await _db.transaction(() async {
      await _db.upsertContract(contract.organizationId, contract);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: ContractPayload(contract: contract)),
        ),
        scopeKey: organizationScopeKey(contract.organizationId),
      );
    });
  }
}

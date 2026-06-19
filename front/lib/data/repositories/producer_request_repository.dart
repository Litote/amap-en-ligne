import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

class ProducerRequestRepository {
  ProducerRequestRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<AdminProducerRequest>> watch() => _db.watchProducerRequests();

  Future<void> approve(AdminProducerRequest request) => _applyStatusChange(
    request.copyWith(
      status: ProducerRequestStatus.approved,
      reviewedAt: DateTime.now().toUtc().toIso8601String(),
    ),
  );

  /// Resends the activation email for an approved [request] by bumping
  /// [AdminProducerRequest.resendRequestedAt] to the current UTC timestamp,
  /// writing optimistically, and enqueueing an Upsert.
  Future<void> resend(AdminProducerRequest request) => _applyStatusChange(
    request.copyWith(
      resendRequestedAt: DateTime.now().toUtc().toIso8601String(),
    ),
  );

  Future<void> reject(AdminProducerRequest request, {String? reviewComment}) =>
      _applyStatusChange(
        request.copyWith(
          status: ProducerRequestStatus.rejected,
          reviewedAt: DateTime.now().toUtc().toIso8601String(),
          reviewComment: reviewComment,
        ),
      );

  Future<void> _applyStatusChange(AdminProducerRequest updated) async {
    await _db.upsertProducerRequest(updated);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(payload: ProducerRequestPayload(producerRequest: updated)),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
  }
}

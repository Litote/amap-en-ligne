import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write repository for [AdminOrganizationRequest] entities.
///
/// Reads come from the local Drift cache (populated by the sync protocol).
/// Status-change writes apply optimistically to the local cache and enqueue a
/// [ClientMutation] for the next sync round-trip.
class OrganizationRequestRepository {
  OrganizationRequestRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of all organization requests from the local cache.
  Stream<List<AdminOrganizationRequest>> watch() =>
      _db.watchOrganizationRequests();

  /// Approves [request]: sets status to [OrganizationRequestStatus.approved]
  /// with the current timestamp, writes optimistically, and enqueues an Upsert.
  Future<void> approve(AdminOrganizationRequest request) => _applyStatusChange(
    request.copyWith(
      status: OrganizationRequestStatus.approved,
      reviewedAt: DateTime.now().toUtc().toIso8601String(),
    ),
  );

  /// Resends the activation email for an approved [request] by bumping
  /// [AdminOrganizationRequest.resendRequestedAt] to the current UTC timestamp,
  /// writing optimistically, and enqueueing an Upsert.
  Future<void> resend(AdminOrganizationRequest request) => _applyStatusChange(
    request.copyWith(
      resendRequestedAt: DateTime.now().toUtc().toIso8601String(),
    ),
  );

  /// Rejects [request]: sets status to [OrganizationRequestStatus.rejected]
  /// with the current timestamp and optional [reviewComment], writes
  /// optimistically, and enqueues an Upsert.
  Future<void> reject(
    AdminOrganizationRequest request, {
    String? reviewComment,
  }) => _applyStatusChange(
    request.copyWith(
      status: OrganizationRequestStatus.rejected,
      reviewedAt: DateTime.now().toUtc().toIso8601String(),
      reviewComment: reviewComment,
    ),
  );

  Future<void> _applyStatusChange(AdminOrganizationRequest updated) async {
    await _db.upsertOrganizationRequest(updated);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(
          payload: OrganizationRequestPayload(organizationRequest: updated),
        ),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
  }
}

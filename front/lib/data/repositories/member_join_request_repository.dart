import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write repository for [AdminMemberJoinRequest] entities.
///
/// Reads come from the local Drift cache. Review actions enqueue sync
/// mutations and rely on the authoritative sync response to update the cache.
class MemberJoinRequestRepository {
  MemberJoinRequestRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<AdminMemberJoinRequest>> watch(String organizationId) =>
      _db.watchMemberJoinRequests(organizationId);

  Future<String> approve(AdminMemberJoinRequest request) {
    _requirePending(request);
    return _enqueueStatusChange(
      request.copyWith(
        status: MemberJoinRequestStatus.approved,
        reviewedAt: DateTime.now().toUtc().toIso8601String(),
        reviewComment: null,
      ),
    );
  }

  Future<String> reject(
    AdminMemberJoinRequest request, {
    String? reviewComment,
  }) {
    _requirePending(request);
    return _enqueueStatusChange(
      request.copyWith(
        status: MemberJoinRequestStatus.rejected,
        reviewedAt: DateTime.now().toUtc().toIso8601String(),
        reviewComment: reviewComment,
      ),
    );
  }

  Future<String> _enqueueStatusChange(AdminMemberJoinRequest updated) async {
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(
          payload: MemberJoinRequestPayload(memberJoinRequest: updated),
        ),
      ),
      scopeKey: organizationScopeKey(updated.organizationId),
    );
    return clientOpId;
  }

  void _requirePending(AdminMemberJoinRequest request) {
    if (request.status == MemberJoinRequestStatus.pending) return;
    throw StateError('MemberJoinRequest ${request.requestId} is not pending.');
  }
}

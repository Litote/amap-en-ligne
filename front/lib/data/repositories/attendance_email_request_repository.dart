import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/attendance_email_request.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write API for [AttendanceEmailRequest] entities on the
/// `organization:{id}` scope.
///
/// Creating a request writes a `tmp_*` entity locally and enqueues an
/// [Upsert] in the pending mutations queue. The server allocates a real id,
/// sends the email, and returns the entity with [AttendanceEmailRequest.sentAt]
/// populated on the next sync flush.
class AttendanceEmailRequestRepository {
  AttendanceEmailRequestRepository({
    required AppDatabase db,
    IdGenerator? idGenerator,
  }) : _db = db,
       _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of all [AttendanceEmailRequest] rows for [organizationId].
  Stream<List<AttendanceEmailRequest>> watch(String organizationId) =>
      _db.watchAttendanceEmailRequestsByOrg(organizationId);

  /// Creates a new [AttendanceEmailRequest] optimistically and enqueues an
  /// [Upsert] mutation on the `organization:{organizationId}` scope.
  ///
  /// Returns the [clientOpId] of the enqueued mutation so callers can correlate
  /// with [MutationOutcome] when needed.
  Future<String> create({
    required String organizationId,
    required String deliveryId,
    required String recipientEmail,
  }) async {
    final clientOpId = _idGen.next();
    final tmpId = _idGen.nextTmpId();
    final request = AttendanceEmailRequest(
      attendanceEmailRequestId: tmpId,
      organizationId: organizationId,
      deliveryId: deliveryId,
      recipientEmail: recipientEmail,
      requestedAt: DateTime.now().toUtc().toIso8601String(),
      sentAt: null,
    );
    await _db.insertAttendanceEmailRequest(request);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(
          payload: AttendanceEmailRequestPayload(
            attendanceEmailRequest: request,
          ),
        ),
      ),
      scopeKey: organizationScopeKey(organizationId),
    );
    return clientOpId;
  }
}

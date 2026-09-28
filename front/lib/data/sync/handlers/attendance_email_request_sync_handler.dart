import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/attendance_email_request.dart'
    show AttendanceEmailRequest;
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

/// Sync handler for [AttendanceEmailRequest] entities on the `organization:{id}` scope.
///
/// The client creates rows with `tmp_*` ids and enqueues an Upsert; the server
/// allocates the real id, sends the email, and returns the entity with [sentAt]
/// populated. This handler remaps the `tmp_*` id once the server outcome arrives.
final class AttendanceEmailRequestSyncHandler implements EntitySyncHandler {
  const AttendanceEmailRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.attendanceEmailRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final p = _require(payload);
    return db.upsertAttendanceEmailRequest(p.attendanceEmailRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteAttendanceEmailRequest(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final p = _require(payload);
    final localId = p.attendanceEmailRequest.attendanceEmailRequestId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapAttendanceEmailRequestId(
      oldId: localId,
      newId: serverEntityId,
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
      if (payload is! AttendanceEmailRequestPayload) return mutation;
      final request = payload.attendanceEmailRequest;
      if (request.attendanceEmailRequestId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: AttendanceEmailRequestPayload(
            attendanceEmailRequest: request.copyWith(
              attendanceEmailRequestId: newId,
            ),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.attendanceEmailRequest,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(
          entityType: EntityType.attendanceEmailRequest,
          entityId: newId,
        ),
      );
    }
    return mutation;
  }

  AttendanceEmailRequestPayload _require(EntityPayload payload) {
    if (payload is AttendanceEmailRequestPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

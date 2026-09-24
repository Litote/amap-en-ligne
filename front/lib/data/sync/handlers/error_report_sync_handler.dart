import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

/// Sync handler for [ErrorReport] entities.
///
/// The client creates rows with `tmp_*` ids and enqueues an [Upsert]; the
/// server allocates the real id. This handler remaps the `tmp_*` id once the
/// server outcome arrives.
final class ErrorReportSyncHandler implements EntitySyncHandler {
  const ErrorReportSyncHandler();

  @override
  EntityType get entityType => EntityType.errorReport;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final p = _require(payload);
    return db.upsertErrorReport(p.errorReport);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteErrorReport(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final p = _require(payload);
    final localId = p.errorReport.errorReportId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapErrorReportId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! ErrorReportPayload) return mutation;
      final report = payload.errorReport;
      if (report.errorReportId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: ErrorReportPayload(
            errorReport: report.copyWith(errorReportId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.errorReport,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.errorReport, entityId: newId),
      );
    }
    return mutation;
  }

  ErrorReportPayload _require(EntityPayload payload) {
    if (payload is ErrorReportPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

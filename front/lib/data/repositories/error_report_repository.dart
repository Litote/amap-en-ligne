import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

/// Write-only API for user-submitted [ErrorReport] entities.
///
/// Creating a report writes a `tmp_*` entity locally and enqueues an [Upsert]
/// in the pending mutations queue on the first available authenticated scope.
/// The server allocates a real id on apply.
class ErrorReportRepository {
  ErrorReportRepository({required AppDatabase db, IdGenerator? idGenerator})
    : _db = db,
      _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Creates a new [ErrorReport] locally and enqueues an [Upsert] mutation.
  ///
  /// The [scopeKey] must be provided by the caller — typically the first
  /// available authenticated scope from the persisted sync cursors. This avoids
  /// coupling the repository to global state while keeping the enqueue logic
  /// testable.
  Future<void> create({
    required String errorMessage,
    required String scopeKey,
  }) async {
    final tmpId = _idGen.nextTmpId();
    final clientOpId = _idGen.next();
    final report = ErrorReport(
      errorReportId: tmpId,
      errorMessage: errorMessage,
      reportedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.upsertErrorReport(report);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: ErrorReportPayload(errorReport: report)),
      ),
      scopeKey: scopeKey,
    );
  }
}

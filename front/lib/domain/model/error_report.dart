import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_report.freezed.dart';
part 'error_report.g.dart';

/// A user-reported sync error, submitted via the [SyncStatusBanner].
///
/// Synced as a client-initiated [Upsert] on the user's primary authenticated
/// scope. The client creates the entity with a `tmp_*` [errorReportId]; the
/// server allocates a real id on apply.
@freezed
abstract class ErrorReport with _$ErrorReport {
  const factory ErrorReport({
    @JsonKey(name: 'error_report_id') required String errorReportId,
    @JsonKey(name: 'error_message') required String errorMessage,
    // ISO-8601 instant string, e.g. "2026-06-09T12:00:00Z".
    @JsonKey(name: 'reported_at') required String reportedAt,
  }) = _ErrorReport;

  factory ErrorReport.fromJson(Map<String, Object?> json) =>
      _$ErrorReportFromJson(json);
}

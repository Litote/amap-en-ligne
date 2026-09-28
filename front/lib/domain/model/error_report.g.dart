// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorReport _$ErrorReportFromJson(Map<String, dynamic> json) => _ErrorReport(
  errorReportId: json['error_report_id'] as String,
  errorMessage: json['error_message'] as String,
  reportedAt: json['reported_at'] as String,
);

Map<String, dynamic> _$ErrorReportToJson(_ErrorReport instance) =>
    <String, dynamic>{
      'error_report_id': instance.errorReportId,
      'error_message': instance.errorMessage,
      'reported_at': instance.reportedAt,
    };

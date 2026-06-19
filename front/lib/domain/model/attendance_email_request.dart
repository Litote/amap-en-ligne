import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_email_request.freezed.dart';
part 'attendance_email_request.g.dart';

/// A client-initiated request to send the attendance sheet by email.
///
/// Synced on the `organization:{id}` scope. The client creates the entity with
/// a `tmp_*` [attendanceEmailRequestId]; the server allocates a real id on
/// apply, sends the email, and returns the entity with [sentAt] populated in
/// the next sync response.
@freezed
abstract class AttendanceEmailRequest with _$AttendanceEmailRequest {
  const factory AttendanceEmailRequest({
    @JsonKey(name: 'attendance_email_request_id')
    required String attendanceEmailRequestId,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'delivery_id') required String deliveryId,
    @JsonKey(name: 'recipient_email') required String recipientEmail,
    // ISO-8601 instant string, e.g. "2026-06-04T10:00:00Z".
    @JsonKey(name: 'requested_at') required String requestedAt,
    // ISO-8601 instant string; null/absent until the email has been sent.
    @JsonKey(name: 'sent_at') String? sentAt,
  }) = _AttendanceEmailRequest;

  factory AttendanceEmailRequest.fromJson(Map<String, Object?> json) =>
      _$AttendanceEmailRequestFromJson(json);
}

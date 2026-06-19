// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_email_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceEmailRequest _$AttendanceEmailRequestFromJson(
  Map<String, dynamic> json,
) => _AttendanceEmailRequest(
  attendanceEmailRequestId: json['attendance_email_request_id'] as String,
  organizationId: json['organization_id'] as String,
  deliveryId: json['delivery_id'] as String,
  recipientEmail: json['recipient_email'] as String,
  requestedAt: json['requested_at'] as String,
  sentAt: json['sent_at'] as String?,
);

Map<String, dynamic> _$AttendanceEmailRequestToJson(
  _AttendanceEmailRequest instance,
) => <String, dynamic>{
  'attendance_email_request_id': instance.attendanceEmailRequestId,
  'organization_id': instance.organizationId,
  'delivery_id': instance.deliveryId,
  'recipient_email': instance.recipientEmail,
  'requested_at': instance.requestedAt,
  'sent_at': ?instance.sentAt,
};

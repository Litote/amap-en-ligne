// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_producer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminProducerRequest _$AdminProducerRequestFromJson(
  Map<String, dynamic> json,
) => _AdminProducerRequest(
  requestId: json['request_id'] as String,
  producerName: json['producer_name'] as String,
  adminFirstName: json['admin_first_name'] as String,
  adminLastName: json['admin_last_name'] as String,
  adminEmail: json['admin_email'] as String,
  status: $enumDecode(_$ProducerRequestStatusEnumMap, json['status']),
  submittedAt: json['submitted_at'] as String,
  reviewedAt: json['reviewed_at'] as String?,
  reviewComment: json['review_comment'] as String?,
  submitterComment: json['submitter_comment'] as String?,
  resendRequestedAt: json['resend_requested_at'] as String?,
);

Map<String, dynamic> _$AdminProducerRequestToJson(
  _AdminProducerRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'producer_name': instance.producerName,
  'admin_first_name': instance.adminFirstName,
  'admin_last_name': instance.adminLastName,
  'admin_email': instance.adminEmail,
  'status': _$ProducerRequestStatusEnumMap[instance.status]!,
  'submitted_at': instance.submittedAt,
  'reviewed_at': ?instance.reviewedAt,
  'review_comment': ?instance.reviewComment,
  'submitter_comment': ?instance.submitterComment,
  'resend_requested_at': ?instance.resendRequestedAt,
};

const _$ProducerRequestStatusEnumMap = {
  ProducerRequestStatus.pendingValidation: 'PENDING_VALIDATION',
  ProducerRequestStatus.approved: 'APPROVED',
  ProducerRequestStatus.rejected: 'REJECTED',
};

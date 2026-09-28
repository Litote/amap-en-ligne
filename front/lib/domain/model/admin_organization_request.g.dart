// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_organization_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminOrganizationRequest _$AdminOrganizationRequestFromJson(
  Map<String, dynamic> json,
) => _AdminOrganizationRequest(
  requestId: json['request_id'] as String,
  organizationName: json['organization_name'] as String,
  organizationType:
      $enumDecodeNullable(
        _$OrganizationTypeEnumMap,
        json['organization_type'],
      ) ??
      OrganizationType.amap,
  timezone: json['timezone'] as String,
  defaultLanguage: json['default_language'] as String,
  adminFirstName: json['admin_first_name'] as String,
  adminLastName: json['admin_last_name'] as String,
  adminEmail: json['admin_email'] as String,
  status: $enumDecode(_$OrganizationRequestStatusEnumMap, json['status']),
  submittedAt: json['submitted_at'] as String,
  reviewedAt: json['reviewed_at'] as String?,
  reviewComment: json['review_comment'] as String?,
  submitterComment: json['submitter_comment'] as String?,
  resendRequestedAt: json['resend_requested_at'] as String?,
);

Map<String, dynamic> _$AdminOrganizationRequestToJson(
  _AdminOrganizationRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'organization_name': instance.organizationName,
  'organization_type': _$OrganizationTypeEnumMap[instance.organizationType]!,
  'timezone': instance.timezone,
  'default_language': instance.defaultLanguage,
  'admin_first_name': instance.adminFirstName,
  'admin_last_name': instance.adminLastName,
  'admin_email': instance.adminEmail,
  'status': _$OrganizationRequestStatusEnumMap[instance.status]!,
  'submitted_at': instance.submittedAt,
  'reviewed_at': ?instance.reviewedAt,
  'review_comment': ?instance.reviewComment,
  'submitter_comment': ?instance.submitterComment,
  'resend_requested_at': ?instance.resendRequestedAt,
};

const _$OrganizationTypeEnumMap = {
  OrganizationType.amap: 'AMAP',
  OrganizationType.producer: 'PRODUCER',
};

const _$OrganizationRequestStatusEnumMap = {
  OrganizationRequestStatus.pendingValidation: 'PENDING_VALIDATION',
  OrganizationRequestStatus.approved: 'APPROVED',
  OrganizationRequestStatus.rejected: 'REJECTED',
};

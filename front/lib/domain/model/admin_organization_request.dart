import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_organization_request.freezed.dart';
part 'admin_organization_request.g.dart';

enum OrganizationRequestStatus {
  @JsonValue('PENDING_VALIDATION')
  pendingValidation,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@freezed
abstract class AdminOrganizationRequest with _$AdminOrganizationRequest {
  const factory AdminOrganizationRequest({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'organization_name') required String organizationName,
    @JsonKey(name: 'organization_type')
    @Default(OrganizationType.amap)
    OrganizationType organizationType,
    required String timezone,
    @JsonKey(name: 'default_language') required String defaultLanguage,
    @JsonKey(name: 'admin_first_name') required String adminFirstName,
    @JsonKey(name: 'admin_last_name') required String adminLastName,
    @JsonKey(name: 'admin_email') required String adminEmail,
    required OrganizationRequestStatus status,
    @JsonKey(name: 'submitted_at') required String submittedAt,
    @JsonKey(name: 'reviewed_at') String? reviewedAt,
    @JsonKey(name: 'review_comment') String? reviewComment,
    @JsonKey(name: 'submitter_comment') String? submitterComment,
    @JsonKey(name: 'resend_requested_at') String? resendRequestedAt,
  }) = _AdminOrganizationRequest;

  factory AdminOrganizationRequest.fromJson(Map<String, Object?> json) =>
      _$AdminOrganizationRequestFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_request_response.freezed.dart';
part 'organization_request_response.g.dart';

@freezed
abstract class OrganizationRequestResponse with _$OrganizationRequestResponse {
  const factory OrganizationRequestResponse({
    @JsonKey(name: 'request_id') required String requestId,
    required String status,
  }) = _OrganizationRequestResponse;

  factory OrganizationRequestResponse.fromJson(Map<String, Object?> json) =>
      _$OrganizationRequestResponseFromJson(json);
}

/// Conflict field returned by `POST /v1/organization-requests` on 409.
enum OrganizationConflictField { organizationName, adminEmail, unknown }

import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_creation_request.freezed.dart';
part 'organization_creation_request.g.dart';

enum OrganizationType {
  @JsonValue('AMAP')
  amap,
  @JsonValue('PRODUCER')
  producer,
}

@freezed
abstract class OrganizationCreationRequest with _$OrganizationCreationRequest {
  const factory OrganizationCreationRequest({
    @JsonKey(name: 'organization_name') required String organizationName,
    required String timezone,
    @JsonKey(name: 'default_language') required String defaultLanguage,
    @JsonKey(name: 'admin_first_name') required String adminFirstName,
    @JsonKey(name: 'admin_last_name') required String adminLastName,
    @JsonKey(name: 'admin_email') required String adminEmail,
    @JsonKey(name: 'organization_type')
    required OrganizationType organizationType,
    @JsonKey(name: 'submitter_comment') String? submitterComment,
  }) = _OrganizationCreationRequest;

  factory OrganizationCreationRequest.fromJson(Map<String, Object?> json) =>
      _$OrganizationCreationRequestFromJson(json);
}

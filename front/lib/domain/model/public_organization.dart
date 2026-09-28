import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_organization.freezed.dart';
part 'public_organization.g.dart';

/// Organization entry returned by the unauthenticated
/// `GET /v1/public/organizations` — no contact email (world-readable endpoint).
@freezed
abstract class PublicOrganization with _$PublicOrganization {
  const factory PublicOrganization({
    @JsonKey(name: 'organization_id') required String organizationId,
    required String name,
    @JsonKey(name: 'active_status') @Default(true) bool activeStatus,
  }) = _PublicOrganization;

  factory PublicOrganization.fromJson(Map<String, Object?> json) =>
      _$PublicOrganizationFromJson(json);
}

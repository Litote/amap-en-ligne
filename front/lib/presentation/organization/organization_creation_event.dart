import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_creation_event.freezed.dart';

@freezed
sealed class OrganizationCreationEvent with _$OrganizationCreationEvent {
  const factory OrganizationCreationEvent.submitted({
    required String organizationName,
    required String timezone,
    required String defaultLanguage,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required OrganizationType organizationType,
    String? submitterComment,
  }) = OrganizationCreationSubmitted;
}

import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_creation_state.freezed.dart';

@freezed
sealed class OrganizationCreationState with _$OrganizationCreationState {
  const factory OrganizationCreationState.initial() =
      OrganizationCreationInitial;
  const factory OrganizationCreationState.submitting() =
      OrganizationCreationSubmitting;
  const factory OrganizationCreationState.success({
    required OrganizationRequestResponse response,
  }) = OrganizationCreationSuccess;
  const factory OrganizationCreationState.error({
    required String message,
    OrganizationConflictField? conflictField,
  }) = OrganizationCreationError;
}

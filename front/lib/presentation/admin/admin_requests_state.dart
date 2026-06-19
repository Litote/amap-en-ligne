import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_requests_state.freezed.dart';

@freezed
sealed class AdminRequestsState with _$AdminRequestsState {
  const factory AdminRequestsState.initial() = AdminRequestsInitial;
  const factory AdminRequestsState.loading() = AdminRequestsLoading;
  const factory AdminRequestsState.loaded({
    required List<AdminOrganizationRequest> requests,
    OrganizationRequestStatus? statusFilter,
    @Default(OrganizationType.amap) OrganizationType organizationTypeFilter,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = AdminRequestsLoaded;
  const factory AdminRequestsState.error(String message) = AdminRequestsError;
}

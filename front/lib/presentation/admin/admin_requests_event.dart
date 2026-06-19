import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_requests_event.freezed.dart';

@freezed
sealed class AdminRequestsEvent with _$AdminRequestsEvent {
  const factory AdminRequestsEvent.loadRequested({
    OrganizationRequestStatus? statusFilter,
  }) = AdminRequestsLoadRequested;

  const factory AdminRequestsEvent.organizationTypeFilterChanged(
    OrganizationType organizationType,
  ) = AdminRequestsOrganizationTypeFilterChanged;

  const factory AdminRequestsEvent.approveRequested(
    AdminOrganizationRequest request,
  ) = AdminRequestsApproveRequested;

  const factory AdminRequestsEvent.rejectRequested({
    required AdminOrganizationRequest request,
    String? reviewComment,
  }) = AdminRequestsRejectRequested;

  const factory AdminRequestsEvent.resendRequested(
    AdminOrganizationRequest request,
  ) = AdminRequestsResendRequested;
}

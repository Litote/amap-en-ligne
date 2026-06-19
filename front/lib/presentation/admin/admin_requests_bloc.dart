import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_state.dart';
import 'package:bloc/bloc.dart';

class AdminRequestsBloc extends Bloc<AdminRequestsEvent, AdminRequestsState> {
  AdminRequestsBloc({
    required OrganizationRequestRepository organizationRequestRepository,
  }) : _repo = organizationRequestRepository,
       super(const AdminRequestsState.initial()) {
    on<AdminRequestsLoadRequested>(_onLoadRequested);
    on<AdminRequestsOrganizationTypeFilterChanged>(
      _onOrganizationTypeFilterChanged,
    );
    on<AdminRequestsApproveRequested>(_onApproveRequested);
    on<AdminRequestsRejectRequested>(_onRejectRequested);
    on<AdminRequestsResendRequested>(_onResendRequested);
  }

  final OrganizationRequestRepository _repo;

  Future<void> _onLoadRequested(
    AdminRequestsLoadRequested event,
    Emitter<AdminRequestsState> emit,
  ) async {
    // Capture the current org-type tab before emitting loading — state will
    // change to AdminRequestsLoading and the value would be lost otherwise.
    final current = state;
    final orgTypeFilter = current is AdminRequestsLoaded
        ? current.organizationTypeFilter
        : OrganizationType.amap;
    emit(const AdminRequestsState.loading());
    await emit.forEach<List<AdminOrganizationRequest>>(
      _repo.watch(),
      onData: (requests) => AdminRequestsState.loaded(
        requests: requests,
        statusFilter: event.statusFilter,
        organizationTypeFilter: orgTypeFilter,
      ),
      onError: (error, stackTrace) =>
          const AdminRequestsState.error('Unable to load requests.'),
    );
  }

  void _onOrganizationTypeFilterChanged(
    AdminRequestsOrganizationTypeFilterChanged event,
    Emitter<AdminRequestsState> emit,
  ) {
    final current = state;
    if (current is! AdminRequestsLoaded) return;
    emit(current.copyWith(organizationTypeFilter: event.organizationType));
  }

  Future<void> _onApproveRequested(
    AdminRequestsApproveRequested event,
    Emitter<AdminRequestsState> emit,
  ) async {
    final current = state;
    if (current is! AdminRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.approve(event.request);
      // The Drift stream will automatically emit the updated list;
      // just clear the in-progress flag.
      if (state is AdminRequestsLoaded) {
        emit((state as AdminRequestsLoaded).copyWith(actionInProgress: false));
      }
    } catch (_) {
      if (state is AdminRequestsLoaded) {
        emit(
          (state as AdminRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to approve request.',
          ),
        );
      }
    }
  }

  Future<void> _onRejectRequested(
    AdminRequestsRejectRequested event,
    Emitter<AdminRequestsState> emit,
  ) async {
    final current = state;
    if (current is! AdminRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.reject(event.request, reviewComment: event.reviewComment);
      // The Drift stream will automatically emit the updated list;
      // just clear the in-progress flag.
      if (state is AdminRequestsLoaded) {
        emit((state as AdminRequestsLoaded).copyWith(actionInProgress: false));
      }
    } catch (_) {
      if (state is AdminRequestsLoaded) {
        emit(
          (state as AdminRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to reject request.',
          ),
        );
      }
    }
  }

  Future<void> _onResendRequested(
    AdminRequestsResendRequested event,
    Emitter<AdminRequestsState> emit,
  ) async {
    final current = state;
    if (current is! AdminRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.resend(event.request);
      if (state is AdminRequestsLoaded) {
        emit((state as AdminRequestsLoaded).copyWith(actionInProgress: false));
      }
    } catch (_) {
      if (state is AdminRequestsLoaded) {
        emit(
          (state as AdminRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to resend invitation.',
          ),
        );
      }
    }
  }
}

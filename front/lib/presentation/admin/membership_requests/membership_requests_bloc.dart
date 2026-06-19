import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:bloc/bloc.dart';

class MembershipRequestsBloc
    extends Bloc<MembershipRequestsEvent, MembershipRequestsState> {
  MembershipRequestsBloc({
    required String organizationId,
    required MemberJoinRequestRepository memberJoinRequestRepository,
    required SyncRepository syncRepository,
  }) : _organizationId = organizationId,
       _repo = memberJoinRequestRepository,
       _syncRepository = syncRepository,
       super(const MembershipRequestsState.initial()) {
    on<MembershipRequestsLoadRequested>(_onLoadRequested);
    on<MembershipRequestsApproveRequested>(_onApproveRequested);
    on<MembershipRequestsRejectRequested>(_onRejectRequested);
  }

  final String _organizationId;
  final MemberJoinRequestRepository _repo;
  final SyncRepository _syncRepository;

  Future<void> _onLoadRequested(
    MembershipRequestsLoadRequested event,
    Emitter<MembershipRequestsState> emit,
  ) async {
    emit(const MembershipRequestsState.loading());
    await emit.forEach(
      _repo.watch(_organizationId),
      onData: (requests) => MembershipRequestsState.loaded(
        requests: requests,
        statusFilter: event.statusFilter,
      ),
      onError: (error, stackTrace) =>
          const MembershipRequestsState.error('Unable to load requests.'),
    );
  }

  Future<void> _onApproveRequested(
    MembershipRequestsApproveRequested event,
    Emitter<MembershipRequestsState> emit,
  ) async {
    final current = state;
    if (current is! MembershipRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      final clientOpId = await _repo.approve(event.request);
      await _completeAction(
        emit,
        clientOpId: clientOpId,
        failureMessage:
            "La synchronisation a échoué. La demande reste en attente de synchronisation.",
        rejectedFallback: "La demande n'a pas pu être approuvée.",
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionInProgress: false,
          actionError: _localActionError(
            error,
            fallback: "La demande n'a pas pu être approuvée.",
          ),
        ),
      );
    }
  }

  Future<void> _onRejectRequested(
    MembershipRequestsRejectRequested event,
    Emitter<MembershipRequestsState> emit,
  ) async {
    final current = state;
    if (current is! MembershipRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      final clientOpId = await _repo.reject(
        event.request,
        reviewComment: event.reviewComment,
      );
      await _completeAction(
        emit,
        clientOpId: clientOpId,
        failureMessage:
            "La synchronisation a échoué. La demande reste en attente de synchronisation.",
        rejectedFallback: "La demande n'a pas pu être rejetée.",
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionInProgress: false,
          actionError: _localActionError(
            error,
            fallback: "La demande n'a pas pu être rejetée.",
          ),
        ),
      );
    }
  }

  Future<void> _completeAction(
    Emitter<MembershipRequestsState> emit, {
    required String clientOpId,
    required String failureMessage,
    required String rejectedFallback,
  }) async {
    final outcome = await _syncRepository.sync(tenantId: _organizationId);
    final current = state;
    if (current is! MembershipRequestsLoaded) return;
    switch (outcome) {
      case SyncFailure():
        emit(
          current.copyWith(
            actionInProgress: false,
            actionError: failureMessage,
          ),
        );
      case SyncNetworkFailure():
        // The decision is queued locally and will be applied by the next
        // sync once connectivity returns.
        emit(
          current.copyWith(
            actionInProgress: false,
            actionError: syncServerUnreachableMessage,
          ),
        );
      case SyncSuccess():
        final rejected = outcome.rejectedMutations
            .where((mutation) => mutation.clientOpId == clientOpId)
            .firstOrNull;
        if (rejected == null) {
          emit(current.copyWith(actionInProgress: false, actionError: null));
          return;
        }
        emit(
          current.copyWith(
            actionInProgress: false,
            actionError: _mutationErrorMessage(
              rejected.error,
              fallback: rejectedFallback,
            ),
          ),
        );
    }
  }

  String _mutationErrorMessage(
    MutationError? error, {
    required String fallback,
  }) {
    if (error == null) return fallback;
    return switch (error.code) {
      MutationErrorCode.conflict || MutationErrorCode.notFound =>
        'Cette demande a déjà été traitée ou n’est plus disponible.',
      _ => error.message,
    };
  }

  String _localActionError(Object error, {required String fallback}) {
    if (error is StateError) {
      return 'Cette demande a déjà été traitée.';
    }
    return fallback;
  }
}

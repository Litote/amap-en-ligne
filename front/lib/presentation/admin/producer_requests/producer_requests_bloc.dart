import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_state.dart';
import 'package:bloc/bloc.dart';

class ProducerRequestsBloc
    extends Bloc<ProducerRequestsEvent, ProducerRequestsState> {
  ProducerRequestsBloc({
    required ProducerRequestRepository producerRequestRepository,
  }) : _repo = producerRequestRepository,
       super(const ProducerRequestsState.initial()) {
    on<ProducerRequestsLoadRequested>(_onLoadRequested);
    on<ProducerRequestsApproveRequested>(_onApproveRequested);
    on<ProducerRequestsRejectRequested>(_onRejectRequested);
    on<ProducerRequestsResendRequested>(_onResendRequested);
  }

  final ProducerRequestRepository _repo;

  Future<void> _onLoadRequested(
    ProducerRequestsLoadRequested event,
    Emitter<ProducerRequestsState> emit,
  ) async {
    emit(const ProducerRequestsState.loading());
    await emit.forEach<List<AdminProducerRequest>>(
      _repo.watch(),
      onData: (requests) => ProducerRequestsState.loaded(
        requests: requests,
        statusFilter: event.statusFilter,
      ),
      onError: (error, stackTrace) =>
          const ProducerRequestsState.error('Unable to load requests.'),
    );
  }

  Future<void> _onApproveRequested(
    ProducerRequestsApproveRequested event,
    Emitter<ProducerRequestsState> emit,
  ) async {
    final current = state;
    if (current is! ProducerRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.approve(event.request);
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(actionInProgress: false),
        );
      }
    } catch (_) {
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to approve request.',
          ),
        );
      }
    }
  }

  Future<void> _onRejectRequested(
    ProducerRequestsRejectRequested event,
    Emitter<ProducerRequestsState> emit,
  ) async {
    final current = state;
    if (current is! ProducerRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.reject(event.request, reviewComment: event.reviewComment);
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(actionInProgress: false),
        );
      }
    } catch (_) {
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to reject request.',
          ),
        );
      }
    }
  }

  Future<void> _onResendRequested(
    ProducerRequestsResendRequested event,
    Emitter<ProducerRequestsState> emit,
  ) async {
    final current = state;
    if (current is! ProducerRequestsLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _repo.resend(event.request);
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(actionInProgress: false),
        );
      }
    } catch (_) {
      if (state is ProducerRequestsLoaded) {
        emit(
          (state as ProducerRequestsLoaded).copyWith(
            actionInProgress: false,
            actionError: 'Unable to resend invitation.',
          ),
        );
      }
    }
  }
}

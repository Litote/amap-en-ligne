import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_requests_state.freezed.dart';

@freezed
sealed class ProducerRequestsState with _$ProducerRequestsState {
  const factory ProducerRequestsState.initial() = ProducerRequestsInitial;
  const factory ProducerRequestsState.loading() = ProducerRequestsLoading;
  const factory ProducerRequestsState.loaded({
    required List<AdminProducerRequest> requests,
    ProducerRequestStatus? statusFilter,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = ProducerRequestsLoaded;
  const factory ProducerRequestsState.error(String message) =
      ProducerRequestsError;
}

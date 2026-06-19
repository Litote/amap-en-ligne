import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_request_state.freezed.dart';

@freezed
sealed class ProducerRequestState with _$ProducerRequestState {
  const factory ProducerRequestState.initial() = ProducerRequestInitial;
  const factory ProducerRequestState.submitting() = ProducerRequestSubmitting;
  const factory ProducerRequestState.success({
    required ProducerRequestResponse response,
  }) = ProducerRequestSuccess;
  const factory ProducerRequestState.error({
    required String message,
    ProducerConflictField? conflictField,
  }) = ProducerRequestError;
}

import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_requests_event.freezed.dart';

@freezed
sealed class ProducerRequestsEvent with _$ProducerRequestsEvent {
  const factory ProducerRequestsEvent.loadRequested({
    ProducerRequestStatus? statusFilter,
  }) = ProducerRequestsLoadRequested;

  const factory ProducerRequestsEvent.approveRequested({
    required AdminProducerRequest request,
  }) = ProducerRequestsApproveRequested;

  const factory ProducerRequestsEvent.rejectRequested({
    required AdminProducerRequest request,
    String? reviewComment,
  }) = ProducerRequestsRejectRequested;

  const factory ProducerRequestsEvent.resendRequested({
    required AdminProducerRequest request,
  }) = ProducerRequestsResendRequested;
}

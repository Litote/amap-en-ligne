import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_producer_request.freezed.dart';
part 'admin_producer_request.g.dart';

enum ProducerRequestStatus {
  @JsonValue('PENDING_VALIDATION')
  pendingValidation,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@freezed
abstract class AdminProducerRequest with _$AdminProducerRequest {
  const factory AdminProducerRequest({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'producer_name') required String producerName,
    @JsonKey(name: 'admin_first_name') required String adminFirstName,
    @JsonKey(name: 'admin_last_name') required String adminLastName,
    @JsonKey(name: 'admin_email') required String adminEmail,
    required ProducerRequestStatus status,
    @JsonKey(name: 'submitted_at') required String submittedAt,
    @JsonKey(name: 'reviewed_at') String? reviewedAt,
    @JsonKey(name: 'review_comment') String? reviewComment,
    @JsonKey(name: 'submitter_comment') String? submitterComment,
    @JsonKey(name: 'resend_requested_at') String? resendRequestedAt,
  }) = _AdminProducerRequest;

  factory AdminProducerRequest.fromJson(Map<String, Object?> json) =>
      _$AdminProducerRequestFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_request_response.freezed.dart';
part 'producer_request_response.g.dart';

@freezed
abstract class ProducerRequestResponse with _$ProducerRequestResponse {
  const factory ProducerRequestResponse({
    @JsonKey(name: 'request_id') required String requestId,
    required String status,
  }) = _ProducerRequestResponse;

  factory ProducerRequestResponse.fromJson(Map<String, Object?> json) =>
      _$ProducerRequestResponseFromJson(json);
}

enum ProducerConflictField { producerName, adminEmail, unknown }

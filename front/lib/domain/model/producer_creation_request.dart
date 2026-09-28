import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_creation_request.freezed.dart';
part 'producer_creation_request.g.dart';

@freezed
abstract class ProducerCreationRequest with _$ProducerCreationRequest {
  const factory ProducerCreationRequest({
    @JsonKey(name: 'producer_name') required String producerName,
    @JsonKey(name: 'admin_first_name') required String adminFirstName,
    @JsonKey(name: 'admin_last_name') required String adminLastName,
    @JsonKey(name: 'admin_email') required String adminEmail,
    @JsonKey(name: 'submitter_comment') String? submitterComment,
  }) = _ProducerCreationRequest;

  factory ProducerCreationRequest.fromJson(Map<String, Object?> json) =>
      _$ProducerCreationRequestFromJson(json);
}

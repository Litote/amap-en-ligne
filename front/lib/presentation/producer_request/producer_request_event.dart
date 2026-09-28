import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_request_event.freezed.dart';

@freezed
sealed class ProducerRequestEvent with _$ProducerRequestEvent {
  const factory ProducerRequestEvent.submitted({
    required String producerName,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    String? submitterComment,
  }) = ProducerRequestSubmitted;
}

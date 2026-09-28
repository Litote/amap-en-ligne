import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_template.freezed.dart';
part 'delivery_template.g.dart';

@freezed
abstract class EarlySlot with _$EarlySlot {
  const factory EarlySlot({
    @JsonKey(name: 'arrival_time') required String arrivalTime,
    String? explanation,
    @JsonKey(name: 'max_volunteers') required int maxVolunteers,
  }) = _EarlySlot;

  factory EarlySlot.fromJson(Map<String, Object?> json) =>
      _$EarlySlotFromJson(json);
}

@freezed
abstract class DeliveryTemplate with _$DeliveryTemplate {
  const factory DeliveryTemplate({
    @JsonKey(name: 'delivery_template_id') required String deliveryTemplateId,
    @JsonKey(name: 'organization_id') required String organizationId,
    required String name,
    @JsonKey(name: 'standard_start_time') required String standardStartTime,
    @JsonKey(name: 'standard_end_time') required String standardEndTime,
    @JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,
    @JsonKey(name: 'desired_volunteer_count')
    @Default(1)
    int desiredVolunteerCount,
    @JsonKey(name: 'early_slot') EarlySlot? earlySlot,
  }) = _DeliveryTemplate;

  factory DeliveryTemplate.fromJson(Map<String, Object?> json) =>
      _$DeliveryTemplateFromJson(json);
}

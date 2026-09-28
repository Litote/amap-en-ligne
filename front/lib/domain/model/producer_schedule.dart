import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_schedule.freezed.dart';
part 'producer_schedule.g.dart';

/// Read-only projection of one AMAP's deliveries that concern the producer,
/// synced on its private `producer-account:{id}` scope (a producer never
/// receives the `organization:{id}` scope, which carries members' personal
/// data). Derived by the back, never mutated by the client; mirrors the back
/// `persistence.model.ProducerSchedule`. One per linked AMAP, keyed by
/// [organizationId].
@freezed
abstract class ProducerSchedule with _$ProducerSchedule {
  const factory ProducerSchedule({
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    @JsonKey(name: 'organization_name') required String organizationName,
    @Default(<ProducerScheduleDelivery>[])
    List<ProducerScheduleDelivery> deliveries,
  }) = _ProducerSchedule;

  factory ProducerSchedule.fromJson(Map<String, Object?> json) =>
      _$ProducerScheduleFromJson(json);
}

/// A delivery carrying at least one of the producer's contracts.
@freezed
abstract class ProducerScheduleDelivery with _$ProducerScheduleDelivery {
  const factory ProducerScheduleDelivery({
    @JsonKey(name: 'delivery_id') required String deliveryId,
    @JsonKey(name: 'scheduled_date') required String scheduledDate,
    required DeliveryStatus status,
    @Default(<ProducerScheduleContract>[])
    List<ProducerScheduleContract> contracts,
    @JsonKey(name: 'basket_descriptions')
    @Default(<BasketDeliveryDescription>[])
    List<BasketDeliveryDescription> basketDescriptions,
  }) = _ProducerScheduleDelivery;

  factory ProducerScheduleDelivery.fromJson(Map<String, Object?> json) =>
      _$ProducerScheduleDeliveryFromJson(json);
}

/// One of the producer's contracts linked to a delivery.
@freezed
abstract class ProducerScheduleContract with _$ProducerScheduleContract {
  const factory ProducerScheduleContract({
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'contract_name') required String contractName,
    @JsonKey(name: 'basket_quantity') required int basketQuantity,
    required DeliveryContractStatus status,

    /// Lifecycle of the contract itself (null only for schedules synced
    /// before the back sent it).
    @JsonKey(name: 'contract_status') ContractStatus? contractStatus,
  }) = _ProducerScheduleContract;

  factory ProducerScheduleContract.fromJson(Map<String, Object?> json) =>
      _$ProducerScheduleContractFromJson(json);
}

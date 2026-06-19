import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_description_event.freezed.dart';

@freezed
sealed class DeliveryDescriptionEvent with _$DeliveryDescriptionEvent {
  const factory DeliveryDescriptionEvent.requested({
    required Organization org,
    required String deliveryId,
  }) = DeliveryDescriptionRequested;

  const factory DeliveryDescriptionEvent.itemToggled({
    required String productTypeId,
    required String basketSizeName,
    required String itemTypeId,
  }) = ItemToggled;

  const factory DeliveryDescriptionEvent.weightChanged({
    required String productTypeId,
    required String basketSizeName,
    required String itemTypeId,
    String? weight,
  }) = WeightChanged;

  const factory DeliveryDescriptionEvent.saveRequested() =
      DeliveryDescriptionSaveRequested;
}

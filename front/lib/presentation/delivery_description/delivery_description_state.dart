import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_description_state.freezed.dart';

@freezed
sealed class DeliveryDescriptionState with _$DeliveryDescriptionState {
  const factory DeliveryDescriptionState.initial() = DeliveryDescriptionInitial;

  const factory DeliveryDescriptionState.loaded({
    required Organization org,
    required Delivery delivery,
    required List<ProductType> productTypes,
    required List<BasketDeliveryDescription> localDescriptions,
  }) = DeliveryDescriptionLoaded;

  const factory DeliveryDescriptionState.saving() = DeliveryDescriptionSaving;

  const factory DeliveryDescriptionState.saved() = DeliveryDescriptionSaved;

  const factory DeliveryDescriptionState.error({required String message}) =
      DeliveryDescriptionError;
}
